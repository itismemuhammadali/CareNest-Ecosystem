-- BACKEND.md §12 — when geofence check fails in soft mode, notify the job's family.
-- Uses system_config key geofence_notify_family (default true via cfg_bool).

insert into public.system_config (key, value) values
  ('geofence_notify_family', 'true'::jsonb)
on conflict (key) do nothing;

-- ============================================================
-- clock_in — add optional family notification (after audit)
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
  v_sitter_id       uuid := auth.uid();
  v_hire            public.hires;
  v_job             public.jobs;
  v_entry           public.time_entries;
  v_geofence_ok     boolean;
  v_dist_m          double precision;
  v_hard_block      boolean;
  v_notify_family   boolean;
begin
  perform pg_advisory_xact_lock(hashtext('clock_in:' || v_sitter_id::text));

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

  if exists (
    select 1 from public.time_entries
    where sitter_id = v_sitter_id and clock_out_at is null
  ) then
    raise exception 'sitter already has an open time entry'
      using errcode = '23505';
  end if;

  select * into v_job from public.jobs where id = v_hire.job_id;

  v_dist_m := earth_distance(
    ll_to_earth(v_job.location_lat, v_job.location_lng),
    ll_to_earth(p_lat, p_lng)
  );
  v_geofence_ok := v_dist_m <= v_job.geofence_radius_m;

  v_hard_block := public.cfg_bool('geofence_hard_block', false);

  if not v_geofence_ok and v_hard_block then
    raise exception 'you are %.0f meters from the job location. must be within %sm.',
      v_dist_m, v_job.geofence_radius_m;
  end if;

  update public.jobs set status = 'active' where id = v_job.id;

  insert into public.time_entries (
    hire_id, sitter_id, clock_in_at,
    clock_in_lat, clock_in_lng, geofence_passed
  )
  values (
    p_hire_id, v_sitter_id, now(),
    p_lat, p_lng, v_geofence_ok
  )
  returning * into v_entry;

  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_sitter_id, 'clock_in', 'time_entries', v_entry.id,
    jsonb_build_object(
      'geofence_passed', v_geofence_ok,
      'distance_m', round(v_dist_m::numeric, 2),
      'lat', p_lat, 'lng', p_lng
    )
  );

  v_notify_family := public.cfg_bool('geofence_notify_family', true);
  if not v_geofence_ok and v_notify_family then
    insert into public.notifications (user_id, type, title, body, data)
    values (
      v_job.family_id,
      'geofence_warning',
      'Sitter clocked in outside job area',
      'The sitter clocked in farther from your job location than the allowed radius. See details in the app.',
      jsonb_build_object(
        'job_id', v_job.id,
        'hire_id', p_hire_id,
        'time_entry_id', v_entry.id,
        'distance_m', round(v_dist_m::numeric, 2),
        'geofence_radius_m', v_job.geofence_radius_m,
        'stage', 'clock_in'
      )
    );
  end if;

  return v_entry;
end;
$$;

-- ============================================================
-- clock_out — same for clock-out (soft geofence fail still pays)
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
  v_sitter_id       uuid := auth.uid();
  v_entry           public.time_entries;
  v_hire            public.hires;
  v_job             public.jobs;
  v_sitter_age      int;
  v_dist_m          double precision;
  v_geofence_ok     boolean;
  v_total_seconds   numeric;
  v_minutes         int;
  v_wage            numeric(12,2);
  v_new_balance     numeric(12,2);
  v_notify_family   boolean;
begin
  select te.* into v_entry
    from public.time_entries te
   where te.hire_id = p_hire_id
     and te.sitter_id = v_sitter_id
     and te.clock_out_at is null
  for update;

  if not found then
    raise exception 'no open clock-in found for this job';
  end if;

  select * into v_hire from public.hires where id = p_hire_id;
  select * into v_job  from public.jobs  where id = v_hire.job_id;

  v_dist_m := earth_distance(
    ll_to_earth(v_job.location_lat, v_job.location_lng),
    ll_to_earth(p_lat, p_lng)
  );
  v_geofence_ok := v_dist_m <= v_job.geofence_radius_m;

  v_total_seconds := extract(epoch from (now() - v_entry.clock_in_at));
  v_minutes := ceil(v_total_seconds / 60.0)::int;
  v_wage := round((v_minutes::numeric / 60.0) * v_hire.hourly_rate, 2);

  update public.time_entries
     set clock_out_at    = now(),
         clock_out_lat   = p_lat,
         clock_out_lng   = p_lng,
         geofence_passed = v_geofence_ok,
         computed_minutes = v_minutes,
         computed_wage    = v_wage
   where id = v_entry.id
  returning * into v_entry;

  update public.wallets
     set available_balance = available_balance + v_wage,
         lifetime_earnings = lifetime_earnings + v_wage,
         updated_at        = now()
   where sitter_id = v_sitter_id
  returning available_balance into v_new_balance;

  if not found then
    raise exception 'wallet not found for sitter';
  end if;

  insert into public.ledger_entries (
    sitter_id, type, amount, reference_type, reference_id, balance_after
  )
  values (
    v_sitter_id, 'earning', v_wage, 'time_entry', v_entry.id, v_new_balance
  );

  update public.jobs set status = 'completed' where id = v_job.id;

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

  v_notify_family := public.cfg_bool('geofence_notify_family', true);
  if not v_geofence_ok and v_notify_family then
    insert into public.notifications (user_id, type, title, body, data)
    values (
      v_job.family_id,
      'geofence_warning',
      'Sitter clocked out outside job area',
      'The sitter clocked out farther from your job location than the allowed radius. See details in the app.',
      jsonb_build_object(
        'job_id', v_job.id,
        'hire_id', p_hire_id,
        'time_entry_id', v_entry.id,
        'distance_m', round(v_dist_m::numeric, 2),
        'geofence_radius_m', v_job.geofence_radius_m,
        'stage', 'clock_out'
      )
    );
  end if;

  return v_entry;
end;
$$;

grant execute on function public.clock_in(uuid, double precision, double precision) to authenticated;
grant execute on function public.clock_out(uuid, double precision, double precision) to authenticated;
