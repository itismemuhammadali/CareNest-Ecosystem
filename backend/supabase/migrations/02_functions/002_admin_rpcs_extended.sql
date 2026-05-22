-- Star Sitters — §31.6.1 admin RPCs (BACKEND.md §31.6.1) — additions beyond Migration 16

create or replace function public.admin_dashboard_stats()
returns jsonb
language sql security definer
set search_path = public as $$
  select jsonb_build_object(
    'families_total',        (select count(*) from public.family_profiles),
    'families_pending_bg',   (select count(*) from public.family_profiles
                              where bg_check_status = 'pending'),
    'families_approved_bg',  (select count(*) from public.family_profiles
                              where bg_check_status = 'approved'),
    'sitters_total',         (select count(*) from public.sitter_profiles),
    'sitters_active',        (select count(*) from public.sitter_profiles
                              where is_active = true),
    'sitters_pending_consent',(select count(*) from public.sitter_profiles
                              where guardian_consent_status = 'pending'),
    'certs_pending',         (select count(*) from public.certification_submissions
                              where status = 'pending'),
    'jobs_open',             (select count(*) from public.jobs where status = 'open'),
    'jobs_active',           (select count(*) from public.jobs where status = 'active'),
    'jobs_completed_30d',    (select count(*) from public.jobs
                              where status = 'completed'
                                and updated_at > now() - interval '30 days'),
    'disputes_open',         (select count(*) from public.disputes where status = 'open'),
    'withdrawals_pending',   (select count(*) from public.withdrawal_requests
                              where status = 'pending')
  );
$$;

create or replace function public.admin_approve_family(p_user_id uuid)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_admin uuid := auth.uid();
begin
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  update public.family_profiles
     set bg_check_status = 'approved',
         rejection_reason = null
   where user_id = p_user_id;

  if not found then
    raise exception 'family_profile not found for user %', p_user_id;
  end if;

  update public.background_checks
     set status = 'approved',
         reviewed_by = v_admin,
         reviewed_at = now()
   where family_id = p_user_id;

  perform public.write_audit_log(
    'admin_approve_family',
    'family_profiles',
    p_user_id,
    null,
    jsonb_build_object('approver_id', v_admin)
  );

  insert into public.notifications (user_id, type, title, body)
  values (p_user_id, 'bg_check_result',
          'Background check approved',
          'Your background check is approved. You can now post jobs.');
end;
$$;

create or replace function public.admin_reject_family(p_user_id uuid, p_reason text)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_admin uuid := auth.uid();
begin
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  if p_reason is null or length(trim(p_reason)) < 5 then
    raise exception 'rejection reason must be at least 5 characters';
  end if;

  update public.family_profiles
     set bg_check_status  = 'rejected',
         rejection_reason = p_reason
   where user_id = p_user_id;

  if not found then
    raise exception 'family_profile not found for user %', p_user_id;
  end if;

  update public.background_checks
     set status = 'rejected',
         reviewed_by = v_admin,
         reviewed_at = now(),
         admin_notes = p_reason
   where family_id = p_user_id;

  perform public.write_audit_log(
    'admin_reject_family',
    'family_profiles',
    p_user_id,
    null,
    jsonb_build_object('reason', p_reason, 'approver_id', v_admin)
  );

  insert into public.notifications (user_id, type, title, body)
  values (p_user_id, 'bg_check_result',
          'Background check rejected',
          'Reason: ' || p_reason);
end;
$$;

create or replace function public.admin_suspend_sitter(
  p_user_id uuid, p_reason text, p_until timestamptz default null
)
returns void
language plpgsql security definer
set search_path = public as $$
begin
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  update public.sitter_profiles
     set is_active = false,
         suspension_reason = p_reason,
         suspended_until   = p_until
   where user_id = p_user_id;

  if not found then
    raise exception 'sitter_profile not found for user %', p_user_id;
  end if;

  perform public.write_audit_log(
    'admin_suspend_sitter', 'sitter_profiles', p_user_id, null,
    jsonb_build_object('reason', p_reason, 'until', p_until)
  );

  insert into public.notifications (user_id, type, title, body)
  values (
    p_user_id,
    'account_suspended',
    'Your account is suspended',
    case
      when p_reason is not null and btrim(p_reason) <> '' then 'Reason: ' || p_reason
      else 'Contact support for details.'
    end
  );
end;
$$;

create or replace function public.admin_unsuspend_sitter(p_user_id uuid)
returns void
language plpgsql security definer
set search_path = public as $$
begin
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  update public.sitter_profiles
     set is_active = true,
         suspension_reason = null,
         suspended_until   = null
   where user_id = p_user_id;

  if not found then
    raise exception 'sitter_profile not found for user %', p_user_id;
  end if;

  perform public.write_audit_log(
    'admin_unsuspend_sitter', 'sitter_profiles', p_user_id, null,
    '{}'::jsonb
  );

  insert into public.notifications (user_id, type, title, body)
  values (p_user_id, 'account_restored',
          'Your account is active',
          'Your suspension has been lifted.');
end;
$$;

create or replace function public.admin_update_wage_tiers(p_tiers jsonb)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_admin uuid := auth.uid();
  v_tier  jsonb;
  v_effective date := (current_date + interval '1 day')::date;
begin
  perform public.admin_only();

  if jsonb_typeof(p_tiers) <> 'array' then
    raise exception 'p_tiers must be a JSON array';
  end if;

  for v_tier in select jsonb_array_elements(p_tiers)
  loop
    insert into public.age_wage_tiers (
      min_age, max_age, hourly_rate, effective_from, created_by
    )
    values (
      (v_tier->>'min_age')::int,
      (v_tier->>'max_age')::int,
      (v_tier->>'hourly_rate')::numeric(10,2),
      v_effective,
      v_admin
    )
    on conflict (min_age, max_age, effective_from)
    do update set hourly_rate = excluded.hourly_rate,
                  created_by  = excluded.created_by;
  end loop;

  perform public.write_audit_log(
    'admin_update_wage_tiers', 'age_wage_tiers', null, null,
    jsonb_build_object('tiers', p_tiers, 'effective_from', v_effective)
  );
end;
$$;

create or replace function public.admin_resolve_dispute(
  p_dispute_id uuid, p_notes text
)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_dispute public.disputes;
begin
  perform public.admin_only();

  select * into v_dispute from public.disputes
   where id = p_dispute_id and status <> 'resolved'
   for update;
  if not found then
    raise exception 'dispute not found or already resolved';
  end if;

  update public.disputes
     set status           = 'resolved',
         resolution_notes = p_notes,
         resolved_by      = auth.uid(),
         resolved_at      = now()
   where id = p_dispute_id;

  insert into public.job_timeline_events (job_id, event_type, title, actor_id)
  values (v_dispute.job_id, 'resolved', 'Dispute resolved', auth.uid());

  perform public.write_audit_log(
    'admin_resolve_dispute', 'disputes', p_dispute_id, null,
    jsonb_build_object('notes', p_notes)
  );

  insert into public.notifications (user_id, type, title, body)
  values (v_dispute.reported_by_user_id, 'dispute_resolved',
          'Your dispute has been resolved',
          coalesce(nullif(trim(p_notes), ''), 'See the job page for details.'));
end;
$$;

create or replace function public.admin_update_dispute_status(
  p_dispute_id uuid, p_status text
)
returns void
language plpgsql security definer
set search_path = public as $$
begin
  perform public.admin_only();
  if p_status not in ('open','investigating','resolved') then
    raise exception 'invalid status %', p_status;
  end if;

  update public.disputes set status = p_status where id = p_dispute_id;
  if not found then raise exception 'dispute not found'; end if;

  perform public.write_audit_log(
    'admin_update_dispute_status', 'disputes', p_dispute_id, null,
    jsonb_build_object('status', p_status)
  );
end;
$$;

revoke all on function public.admin_dashboard_stats() from public;
revoke all on function public.admin_approve_family(uuid) from public;
revoke all on function public.admin_reject_family(uuid, text) from public;
revoke all on function public.admin_suspend_sitter(uuid, text, timestamptz) from public;
revoke all on function public.admin_unsuspend_sitter(uuid) from public;
revoke all on function public.admin_update_wage_tiers(jsonb) from public;
revoke all on function public.admin_resolve_dispute(uuid, text) from public;
revoke all on function public.admin_update_dispute_status(uuid, text) from public;

grant execute on function public.admin_dashboard_stats() to authenticated;
grant execute on function public.admin_approve_family(uuid) to authenticated;
grant execute on function public.admin_reject_family(uuid, text) to authenticated;
grant execute on function public.admin_suspend_sitter(uuid, text, timestamptz) to authenticated;
grant execute on function public.admin_unsuspend_sitter(uuid) to authenticated;
grant execute on function public.admin_update_wage_tiers(jsonb) to authenticated;
grant execute on function public.admin_resolve_dispute(uuid, text) to authenticated;
grant execute on function public.admin_update_dispute_status(uuid, text) to authenticated;
