-- Star Sitters — SECURITY DEFINER RPCs (BACKEND.md §7 + §8.3)

-- 20260501000013_rpcs.sql

-- ============================================================
-- 1. create_application(job_id, cover_message)
-- Called by: Sitter, from JobDetailScreen
-- ============================================================
create or replace function public.create_application(
  p_job_id        uuid,
  p_cover_message text default null
)
returns public.applications
language plpgsql security definer
set search_path = public as $$
declare
  v_sitter_id uuid := auth.uid();
  v_app       public.applications;
  v_is_active boolean;
begin
  -- 1. Validate sitter is active (guardian consent + admin approved)
  select is_active into v_is_active
    from public.sitter_profiles where user_id = v_sitter_id;

  if not found then
    raise exception 'sitter profile not found';
  end if;
  if not v_is_active then
    raise exception 'your profile must be approved before applying to jobs';
  end if;

  -- 2. Validate job is open
  if not exists (
    select 1 from public.jobs
    where id = p_job_id and status = 'open'
  ) then
    raise exception 'job is not open for applications';
  end if;

  -- 3. Insert application
  insert into public.applications (job_id, sitter_id, cover_message)
  values (p_job_id, v_sitter_id, p_cover_message)
  returning * into v_app;

  -- 4. Audit log
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_sitter_id, 'application_created', 'applications', v_app.id,
    to_jsonb(v_app)
  );

  return v_app;
end;
$$;

-- ============================================================
-- 2. withdraw_application(application_id)
-- Called by: Sitter
-- ============================================================
create or replace function public.withdraw_application(
  p_application_id uuid
)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_sitter_id uuid := auth.uid();
begin
  update public.applications
     set status = 'withdrawn'
   where id = p_application_id
     and sitter_id = v_sitter_id
     and status = 'pending';

  if not found then
    raise exception 'application not found or cannot be withdrawn';
  end if;

  insert into public.audit_logs (actor_id, action, entity_type, entity_id)
  values (v_sitter_id, 'application_withdrawn', 'applications', p_application_id);
end;
$$;

-- ============================================================
-- 3. create_hire(application_id)
-- Called by: Family, from job detail screen
-- One transaction: accept this app, reject others, create hire,
--                  open conversation, update job status
-- ============================================================
create or replace function public.create_hire(
  p_application_id uuid
)
returns public.hires
language plpgsql security definer
set search_path = public as $$
declare
  v_family_id   uuid := auth.uid();
  v_app         public.applications;
  v_job         public.jobs;
  v_rate        numeric(10,2);
  v_sitter_age  int;
  v_hire        public.hires;
  v_conv_id     uuid;
begin
  -- 1. Fetch application and verify family owns the job
  select a.* into v_app
    from public.applications a
    join public.jobs j on j.id = a.job_id
   where a.id = p_application_id
     and j.family_id = v_family_id
     and a.status = 'pending'
     and j.status = 'open'
  for update;

  if not found then
    raise exception 'application not found or job already hired';
  end if;

  -- 2. Fetch job
  select * into v_job from public.jobs where id = v_app.job_id;

  -- 3. Get sitter's current age and snapshot wage rate.
  -- Use full-year arithmetic on the date itself so a sitter that turned 13 yesterday
  -- is treated as 13 today (extract(year from age()) gives the same answer here, but
  -- this form is unambiguous and matches the chk_sitter_age constraint logic).
  select (date_part('year', age(current_date, date_of_birth)))::int
    into v_sitter_age
    from public.sitter_profiles
   where user_id = v_app.sitter_id;

  select hourly_rate into v_rate
    from public.age_wage_tiers
   where v_sitter_age between min_age and max_age
   order by effective_from desc
   limit 1;

  if v_rate is null then
    raise exception 'no wage tier configured for sitter age %', v_sitter_age;
  end if;

  -- 4. Accept this application
  update public.applications
     set status = 'accepted'
   where id = p_application_id;

  -- 5. Reject all other pending applications for this job
  update public.applications
     set status = 'rejected'
   where job_id = v_app.job_id
     and id <> p_application_id
     and status = 'pending';

  -- 6. Create hire with snapshotted rate
  insert into public.hires (job_id, sitter_id, hourly_rate)
  values (v_app.job_id, v_app.sitter_id, v_rate)
  returning * into v_hire;

  -- 7. Update job status to hired
  update public.jobs
     set status = 'hired'
   where id = v_app.job_id;

  -- 8. Open conversation
  insert into public.conversations (job_id, family_id, sitter_id)
  values (v_app.job_id, v_family_id, v_app.sitter_id)
  on conflict (job_id, sitter_id) do nothing
  returning id into v_conv_id;

  -- 9. Audit
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_family_id, 'hire_created', 'hires', v_hire.id,
    jsonb_build_object(
      'job_id', v_hire.job_id,
      'sitter_id', v_hire.sitter_id,
      'hourly_rate', v_hire.hourly_rate
    )
  );

  return v_hire;
end;
$$;

-- ============================================================
-- 4. clock_in(hire_id, lat, lng)
-- Called by: Sitter, from Active Job screen
-- ============================================================
create or replace function public.clock_in(
  p_hire_id uuid,
  p_lat     double precision,
  p_lng     double precision
)
returns public.time_entries
language plpgsql security definer
set search_path = public as $$
declare
  v_sitter_id     uuid := auth.uid();
  v_hire          public.hires;
  v_job           public.jobs;
  v_entry         public.time_entries;
  v_geofence_ok   boolean;
  v_dist_m        double precision;
  v_hard_block    boolean;
begin
  -- 0. Take a per-sitter advisory lock so two simultaneous clock_in calls
  --    serialize. Belt-and-suspenders alongside the partial unique index
  --    uq_one_open_time_entry — that index will reject duplicates with a
  --    clean unique-violation error, but the advisory lock guarantees the
  --    rest of this transaction (job status flip, audit log) sees a
  --    consistent state. The lock is automatically released at COMMIT.
  perform pg_advisory_xact_lock(hashtext('clock_in:' || v_sitter_id::text));

  -- 1. Validate hire belongs to this sitter and job is 'hired'
  select h.* into v_hire
    from public.hires h
    join public.jobs j on j.id = h.job_id
   where h.id = p_hire_id
     and h.sitter_id = v_sitter_id
     and j.status = 'hired'
  for update;

  if not found then
    raise exception 'hire not found or job not in hired state';
  end if;

  -- 2. Pre-check (defensive). The partial unique index uq_one_open_time_entry
  --    is the authoritative gate — if this check passes but a concurrent
  --    transaction inserts first, the index will raise a unique_violation
  --    on our own INSERT below and the whole transaction rolls back.
  if exists (
    select 1 from public.time_entries
    where sitter_id = v_sitter_id and clock_out_at is null
  ) then
    raise exception 'sitter already has an open time entry'
      using errcode = '23505';   -- mimic unique_violation for consistent UI handling
  end if;

  -- 3. Fetch job for geofence
  select * into v_job from public.jobs where id = v_hire.job_id;

  -- 4. Geofence check (Haversine via earthdistance extension)
  v_dist_m := earth_distance(
    ll_to_earth(v_job.location_lat, v_job.location_lng),
    ll_to_earth(p_lat, p_lng)
  );
  v_geofence_ok := v_dist_m <= v_job.geofence_radius_m;

  -- 5. Hard-block config (read via cfg_bool helper — see Migration 12).
  --    Direct casts of system_config.value can silently misfire when the
  --    JSON-encoded value is the string 'true' vs the boolean true; cfg_bool
  --    handles both safely.
  v_hard_block := public.cfg_bool('geofence_hard_block', false);

  if not v_geofence_ok and v_hard_block then
    raise exception 'you are %.0f meters from the job location. must be within %sm.',
      v_dist_m, v_job.geofence_radius_m;
  end if;

  -- 6. Update job to active
  update public.jobs set status = 'active' where id = v_job.id;

  -- 7. Insert time entry. The partial unique index will reject this row
  --    if any other open entry for this sitter exists.
  insert into public.time_entries (
    hire_id, sitter_id, clock_in_at,
    clock_in_lat, clock_in_lng, geofence_passed
  )
  values (
    p_hire_id, v_sitter_id, now(),
    p_lat, p_lng, v_geofence_ok
  )
  returning * into v_entry;

  -- 8. Audit
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_sitter_id, 'clock_in', 'time_entries', v_entry.id,
    jsonb_build_object(
      'geofence_passed', v_geofence_ok,
      'distance_m', round(v_dist_m::numeric, 2),
      'lat', p_lat, 'lng', p_lng
    )
  );

  return v_entry;
end;
$$;

-- ============================================================
-- 5. clock_out(hire_id, lat, lng)
-- Called by: Sitter, from Active Job screen
-- One transaction: close time entry, calculate exact-minute wage,
--                  insert ledger entry, update wallet, complete job
-- ============================================================
create or replace function public.clock_out(
  p_hire_id uuid,
  p_lat     double precision,
  p_lng     double precision
)
returns public.time_entries
language plpgsql security definer
set search_path = public as $$
declare
  v_sitter_id     uuid := auth.uid();
  v_entry         public.time_entries;
  v_hire          public.hires;
  v_job           public.jobs;
  v_sitter_age    int;
  v_dist_m        double precision;
  v_geofence_ok   boolean;
  v_total_seconds numeric;
  v_minutes       int;
  v_wage          numeric(12,2);
  v_new_balance   numeric(12,2);
begin
  -- 1. Fetch open time entry for this hire, owned by this sitter
  select te.* into v_entry
    from public.time_entries te
   where te.hire_id = p_hire_id
     and te.sitter_id = v_sitter_id
     and te.clock_out_at is null
  for update;

  if not found then
    raise exception 'no open clock-in found for this job';
  end if;

  -- 2. Fetch hire and job
  select * into v_hire from public.hires where id = p_hire_id;
  select * into v_job  from public.jobs  where id = v_hire.job_id;

  -- 3. Geofence at clock-out
  v_dist_m := earth_distance(
    ll_to_earth(v_job.location_lat, v_job.location_lng),
    ll_to_earth(p_lat, p_lng)
  );
  v_geofence_ok := v_dist_m <= v_job.geofence_radius_m;

  -- 4. Compute exact-minute wage using SNAPSHOTTED rate from hires table
  --    Formula: minutes = ceil(seconds / 60)
  --             wage    = (minutes / 60.0) * hourly_rate
  --    Using hire.hourly_rate (snapshotted at hire time — immutable)
  v_total_seconds := extract(epoch from (now() - v_entry.clock_in_at));
  v_minutes := ceil(v_total_seconds / 60.0)::int;
  v_wage := round((v_minutes::numeric / 60.0) * v_hire.hourly_rate, 2);

  -- 5. Update time entry
  update public.time_entries
     set clock_out_at    = now(),
         clock_out_lat   = p_lat,
         clock_out_lng   = p_lng,
         geofence_passed = v_geofence_ok,
         computed_minutes = v_minutes,
         computed_wage    = v_wage
   where id = v_entry.id
  returning * into v_entry;

  -- 6. Update wallet (available_balance + lifetime_earnings)
  update public.wallets
     set available_balance = available_balance + v_wage,
         lifetime_earnings = lifetime_earnings + v_wage,
         updated_at        = now()
   where sitter_id = v_sitter_id
  returning available_balance into v_new_balance;

  -- Wallet row must exist (created during sitter onboarding)
  if not found then
    raise exception 'wallet not found for sitter';
  end if;

  -- 7. Insert ledger entry
  insert into public.ledger_entries (
    sitter_id, type, amount, reference_type, reference_id, balance_after
  )
  values (
    v_sitter_id, 'earning', v_wage, 'time_entry', v_entry.id, v_new_balance
  );

  -- 8. Mark job completed
  update public.jobs set status = 'completed' where id = v_job.id;

  -- 9. Audit
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_sitter_id, 'clock_out', 'time_entries', v_entry.id,
    jsonb_build_object(
      'minutes', v_minutes,
      'wage', v_wage,
      'balance_after', v_new_balance,
      'geofence_passed', v_geofence_ok
    )
  );

  return v_entry;
end;
$$;

-- ============================================================
-- 6. request_withdrawal(amount, method, account_info)
-- Called by: Sitter, from WithdrawScreen
-- ============================================================
create or replace function public.request_withdrawal(
  p_amount       numeric(12,2),
  p_method       text,
  p_account_info jsonb default '{}'
)
returns public.withdrawal_requests
language plpgsql security definer
set search_path = public as $$
declare
  v_sitter_id    uuid := auth.uid();
  v_balance      numeric(12,2);
  v_request      public.withdrawal_requests;
begin
  -- 1. Check available balance
  select available_balance into v_balance
    from public.wallets where sitter_id = v_sitter_id
  for update;

  if not found then
    raise exception 'wallet not found';
  end if;
  if p_amount <= 0 then
    raise exception 'withdrawal amount must be positive';
  end if;
  if p_amount > v_balance then
    raise exception 'insufficient balance: available %.2f, requested %.2f',
      v_balance, p_amount;
  end if;

  -- 2. Deduct from available balance immediately (reserved)
  update public.wallets
     set available_balance = available_balance - p_amount,
         pending_balance   = pending_balance   + p_amount
   where sitter_id = v_sitter_id;

  -- 3. Create withdrawal request
  insert into public.withdrawal_requests (sitter_id, amount, method, account_info)
  values (v_sitter_id, p_amount, p_method, p_account_info)
  returning * into v_request;

  -- 4. Ledger entry for deduction
  insert into public.ledger_entries (
    sitter_id, type, amount, reference_type, reference_id, balance_after
  )
  values (
    v_sitter_id, 'withdrawal', -p_amount, 'withdrawal_request', v_request.id,
    v_balance - p_amount
  );

  -- 5. Audit
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_sitter_id, 'withdrawal_requested', 'withdrawal_requests', v_request.id,
    jsonb_build_object('amount', p_amount, 'method', p_method)
  );

  return v_request;
end;
$$;

-- ============================================================
-- 7. admin_approve_bg_check(family_id, decision, notes)
-- Called by: Admin (via Supabase Studio or future admin web)
-- ============================================================
create or replace function public.admin_approve_bg_check(
  p_family_id uuid,
  p_decision  text,  -- 'approved' | 'rejected'
  p_notes     text default null
)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_admin_id uuid := auth.uid();
begin
  -- Standard admin RPC preamble: gate + immutability bypass for the bg_check_status flip.
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  if p_decision not in ('approved', 'rejected') then
    raise exception 'decision must be approved or rejected';
  end if;

  update public.background_checks
     set status      = p_decision::public.verification_status,
         reviewed_by = v_admin_id,
         reviewed_at = now(),
         admin_notes = p_notes
   where family_id = p_family_id;

  -- Update family_profile bg_check_status for fast RLS checks
  update public.family_profiles
     set bg_check_status = p_decision::public.verification_status
   where user_id = p_family_id;

  perform public.write_audit_log(
    'bg_check_' || p_decision,
    'background_checks',
    (select id from public.background_checks where family_id = p_family_id),
    null,
    jsonb_build_object('decision', p_decision, 'notes', p_notes, 'family_id', p_family_id)
  );

  -- Notification to family (insert row; Edge Function will push FCM)
  insert into public.notifications (user_id, type, title, body)
  values (
    p_family_id,
    'bg_check_result',
    case when p_decision = 'approved' then 'Background Check Approved'
         else 'Background Check Update' end,
    case when p_decision = 'approved'
         then 'Your background check has been approved. You can now post jobs.'
         else coalesce(p_notes, 'Your background check requires attention.') end
  );
end;
$$;

-- ============================================================
-- 8. admin_approve_certification(cert_id, decision, notes)
-- Called by: Admin
-- ============================================================
create or replace function public.admin_approve_certification(
  p_cert_id  uuid,
  p_decision text,
  p_notes    text default null
)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_admin_id  uuid := auth.uid();
  v_sitter_id uuid;
begin
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  if p_decision not in ('approved', 'rejected') then
    raise exception 'decision must be approved or rejected';
  end if;

  select sitter_id into v_sitter_id from public.certifications where id = p_cert_id;
  if not found then raise exception 'certification not found'; end if;

  update public.certifications
     set status      = p_decision::public.verification_status,
         reviewed_by = v_admin_id,
         reviewed_at = now(),
         admin_notes = p_notes
   where id = p_cert_id;

  -- If this is the first approved cert AND guardian consent is in place,
  -- flip sitter is_active. The trigger fn_sitter_lock_admin_fields permits
  -- this because we set the bypass GUC above.
  if p_decision = 'approved' then
    update public.sitter_profiles
       set is_active = true
     where user_id = v_sitter_id
       and guardian_consent_status = 'approved';
  end if;

  perform public.write_audit_log(
    'cert_' || p_decision,
    'certifications',
    p_cert_id,
    null,
    jsonb_build_object('decision', p_decision, 'sitter_id', v_sitter_id, 'notes', p_notes)
  );

  insert into public.notifications (user_id, type, title, body)
  values (
    v_sitter_id, 'cert_result',
    case when p_decision = 'approved' then 'Certification Approved' else 'Certification Update' end,
    case when p_decision = 'approved'
         then 'Your certification has been verified. You can now apply to jobs.'
         else coalesce(p_notes, 'Your certification requires attention.') end
  );
end;
$$;

-- ============================================================
-- 9. admin_pay_withdrawal(request_id)
-- Called by: Admin, after physically transferring funds
-- ============================================================
create or replace function public.admin_pay_withdrawal(
  p_request_id uuid
)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_admin_id  uuid := auth.uid();
  v_request   public.withdrawal_requests;
begin
  perform public.admin_only();

  select * into v_request
    from public.withdrawal_requests
   where id = p_request_id and status = 'pending'
  for update;

  if not found then raise exception 'pending withdrawal not found'; end if;

  update public.withdrawal_requests
     set status  = 'paid',
         paid_at = now(),
         paid_by = v_admin_id
   where id = p_request_id;

  update public.wallets
     set pending_balance = pending_balance - v_request.amount
   where sitter_id = v_request.sitter_id;

  perform public.write_audit_log(
    'withdrawal_paid',
    'withdrawal_requests',
    p_request_id,
    null,
    jsonb_build_object('amount', v_request.amount, 'sitter_id', v_request.sitter_id)
  );

  insert into public.notifications (user_id, type, title, body)
  values (
    v_request.sitter_id, 'withdrawal_paid',
    'Withdrawal Processed',
    format('Your withdrawal of $%.2f has been sent.', v_request.amount)
  );
end;
$$;

create or replace function public.confirm_guardian_consent(
  p_token uuid
)
returns boolean
language plpgsql security definer
set search_path = public as $$
declare
  v_sitter_id        uuid;
  v_consent_created  timestamptz;
  v_token_ttl_hours  int := 24;
begin
  -- Mark this transaction as a server-side privileged write so the
  -- fn_sitter_lock_admin_fields trigger lets us flip guardian_consent_status.
  -- The GUC is transaction-scoped (set local) so it cannot leak to other
  -- sessions.
  perform set_config('app.bypass_immutability', 'true', true);

  -- 1. Atomically claim the token. This single UPDATE both checks (token
  --    exists, not yet used, not expired) and consumes (sets consent_given_at).
  --    Two concurrent guardians clicking the same link will see exactly one
  --    success because the row is locked by the UPDATE.
  update public.guardian_consents
     set consent_given_at = now(),
         consent_ip       = inet_client_addr()
   where consent_token   = p_token
     and consent_given_at is null
     and created_at      > now() - make_interval(hours => v_token_ttl_hours)
  returning sitter_id, created_at
        into v_sitter_id, v_consent_created;

  if not found then
    -- Either the token doesn't exist, was already consumed, or expired.
    -- Don't leak which one — a 24h-old token vs a fake token both return false.
    return false;
  end if;

  -- 2. Update sitter profile consent status. The trigger respects our GUC.
  update public.sitter_profiles
     set guardian_consent_status = 'approved'
   where user_id = v_sitter_id;

  -- 3. Notify sitter
  insert into public.notifications (user_id, type, title, body)
  values (
    v_sitter_id, 'guardian_consent_given',
    'Guardian Consent Received',
    'Your guardian has given consent. Your profile is now under admin review.'
  );

  -- 4. Audit (no actor — guardian is unauthenticated)
  insert into public.audit_logs (action, entity_type, entity_id, after_state)
  values ('guardian_consent_confirmed', 'guardian_consents', v_sitter_id,
          jsonb_build_object('confirmed_at', now()));

  return true;
end;
$$;

-- PostgREST: expose RPCs to clients (Supabase)
grant execute on function public.create_application(uuid, text) to authenticated;
grant execute on function public.withdraw_application(uuid) to authenticated;
grant execute on function public.create_hire(uuid) to authenticated;
grant execute on function public.clock_in(uuid, double precision, double precision) to authenticated;
grant execute on function public.clock_out(uuid, double precision, double precision) to authenticated;
grant execute on function public.request_withdrawal(numeric, text, jsonb) to authenticated;
grant execute on function public.admin_approve_bg_check(uuid, text, text) to authenticated;
grant execute on function public.admin_approve_certification(uuid, text, text) to authenticated;
grant execute on function public.admin_pay_withdrawal(uuid) to authenticated;
grant execute on function public.confirm_guardian_consent(uuid) to anon, authenticated;
