-- Apply admin Wage Configuration (time_rounding_mode / overtime_mode) at clock-out.
-- Add admin_list_ledger_entries for salary / ledger transparency.

-- ============================================================
-- clock_out — billable time from system_config + hire hourly_rate
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
  v_dist_m          double precision;
  v_geofence_ok     boolean;
  v_total_seconds   numeric;
  v_mode            text;
  v_ot_mode         text;
  v_worked_mins     numeric;
  v_bill_mins       numeric;
  v_billable_hours  numeric;
  v_reg_h           numeric;
  v_ot_h            numeric;
  v_ot_mult         numeric;
  v_wage            numeric(12,2);
  v_new_balance     numeric(12,2);
  v_notify_family   boolean;
  v_computed_mins   int;
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

  v_mode := lower(trim(both from coalesce(
    nullif(public.cfg_text('time_rounding_mode', ''), ''),
    public.cfg_text('time_rounding_rule', 'exact')
  )));
  if v_mode is null or v_mode = '' then
    v_mode := 'exact';
  end if;

  v_ot_mode := lower(trim(both from coalesce(
    nullif(public.cfg_text('overtime_mode', ''), ''),
    public.cfg_text('overtime_rule', 'disabled')
  )));
  if v_ot_mode is null or v_ot_mode = '' then
    v_ot_mode := 'disabled';
  end if;

  v_worked_mins := v_total_seconds / 60.0;
  v_computed_mins := greatest(1, round(v_worked_mins)::int);

  if v_mode = 'round-up' then
    v_billable_hours := ceil((v_total_seconds / 3600.0)::numeric)::numeric;
  elsif v_mode = 'round-15' then
    v_bill_mins := round(v_worked_mins::numeric / 15.0) * 15.0;
    if v_bill_mins < 1 and v_worked_mins > 0 then
      v_bill_mins := 15;
    end if;
    v_billable_hours := v_bill_mins / 60.0;
  elsif v_mode = 'round-30' then
    v_bill_mins := round(v_worked_mins::numeric / 30.0) * 30.0;
    if v_bill_mins < 1 and v_worked_mins > 0 then
      v_bill_mins := 30;
    end if;
    v_billable_hours := v_bill_mins / 60.0;
  else
    v_billable_hours := (v_total_seconds / 3600.0)::numeric;
  end if;

  if v_billable_hours < (1.0 / 60.0) and v_total_seconds > 0 then
    v_billable_hours := (1.0 / 60.0)::numeric;
  end if;

  v_reg_h := least(v_billable_hours, 8);
  v_ot_h := greatest(v_billable_hours - 8, 0);

  v_ot_mult := 1::numeric;
  if v_ot_h > 0 then
    if v_ot_mode in ('1.5x', '1.5') then
      v_ot_mult := 1.5;
    elsif v_ot_mode in ('2x', '2') then
      v_ot_mult := 2;
    end if;
  end if;

  v_wage := round(v_hire.hourly_rate * (v_reg_h + v_ot_h * v_ot_mult), 2);

  update public.time_entries
     set clock_out_at     = now(),
         clock_out_lat    = p_lat,
         clock_out_lng    = p_lng,
         geofence_passed  = v_geofence_ok,
         computed_minutes = v_computed_mins,
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
      'minutes', v_computed_mins,
      'billable_hours', v_billable_hours,
      'rounding_mode', v_mode,
      'overtime_mode', v_ot_mode,
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

-- ============================================================
-- Admin ledger (salary / earnings audit trail)
-- ============================================================
create or replace function public.admin_list_ledger_entries(p_limit int default 200)
returns table (
  id uuid,
  sitter_id uuid,
  sitter_name text,
  sitter_email text,
  entry_type text,
  amount numeric,
  reference_type text,
  reference_id uuid,
  balance_after numeric,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public as $$
declare
  lim int := greatest(1, least(coalesce(p_limit, 200), 2000));
begin
  perform public.admin_only();
  return query
  select
    le.id,
    le.sitter_id,
    coalesce(nullif(trim(both from u.full_name), ''), u.email)::text as sitter_name,
    u.email::text as sitter_email,
    le.type::text as entry_type,
    le.amount::numeric,
    le.reference_type,
    le.reference_id,
    le.balance_after::numeric,
    le.created_at
  from public.ledger_entries le
  join public.users u on u.id = le.sitter_id
  order by le.created_at desc
  limit lim;
end;
$$;

revoke all on function public.admin_list_ledger_entries(int) from public;
grant execute on function public.admin_list_ledger_entries(int) to authenticated;
