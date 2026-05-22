-- Seed admin UI demos on a HOSTED Supabase project (run in Dashboard → SQL Editor as postgres).
-- Targets demo-looking family accounts only (email @starsitters.invalid or name "Demo Pending Family").
-- Idempotent-ish: safe to re-run; may add another seed child row if family had zero children.
--
-- Before run: ensure you are on the correct project (URL matches NEXT_PUBLIC_SUPABASE_URL).

begin;

select set_config('app.bypass_immutability', 'true', true);

-- ---------------------------------------------------------------------------
-- 1) Families → pending verification (admin /families Approve / Reject)
-- ---------------------------------------------------------------------------
with cands as (
  select fp.user_id
  from public.family_profiles fp
  join public.users u on u.id = fp.user_id and u.role = 'family'
  where (
    u.email ilike '%@starsitters.invalid'
    or coalesce(u.full_name, '') ilike '%demo pending%'
  )
  and fp.bg_check_status in ('approved', 'rejected', 'not_submitted')
  order by u.created_at desc
  limit 6
)
update public.family_profiles fp
set bg_check_status = 'pending',
    rejection_reason = null
from cands
where fp.user_id = cands.user_id;

insert into public.background_checks (family_id, documents, status)
select fp.user_id, '[]'::jsonb, 'pending'::public.verification_status
from public.family_profiles fp
join public.users u on u.id = fp.user_id and u.role = 'family'
where fp.bg_check_status = 'pending'
  and (
    u.email ilike '%@starsitters.invalid'
    or coalesce(u.full_name, '') ilike '%demo pending%'
  )
on conflict (family_id) do update
set status = 'pending'::public.verification_status,
    reviewed_by = null,
    reviewed_at = null,
    admin_notes = null;

-- ---------------------------------------------------------------------------
-- 2) Jobs (admin /jobs) — one anchor family + optional sitter for "hired" row
-- ---------------------------------------------------------------------------
do $$
declare
  v_family uuid;
  v_child  uuid;
  v_sitter uuid;
  v_job_open uuid;
  v_job_hired uuid;
  v_job_done uuid;
  v_job_active uuid;
begin
  select fp.user_id into v_family
  from public.family_profiles fp
  join public.users u on u.id = fp.user_id and u.role = 'family'
  order by u.created_at
  limit 1;

  if v_family is null then
    raise notice 'No family profile found — skip jobs/disputes seed.';
    return;
  end if;

  select c.id into v_child
  from public.children c
  where c.family_id = v_family
  order by c.created_at
  limit 1;

  if v_child is null then
    insert into public.children (family_id, name, age, notes)
    values (v_family, 'Demo Child', 6, 'seed_admin_dashboard_demos')
    returning id into v_child;
  end if;

  select sp.user_id into v_sitter
  from public.sitter_profiles sp
  join public.users u on u.id = sp.user_id and u.role = 'sitter'
  order by u.created_at
  limit 1;

  -- Open job
  insert into public.jobs (
    family_id, title, description, date, start_time, end_time,
    number_of_children, child_ids, location_lat, location_lng,
    location_address, status
  ) values (
    v_family,
    'Demo evening sitter (open)',
    'Seeded for admin Jobs Monitoring.',
    (current_date + 1),
    (current_date + 1)::timestamptz + time '18:00',
    (current_date + 1)::timestamptz + time '21:00',
    1, array[v_child]::uuid[], 40.7128, -74.0060,
    '{"line1":"Demo St, NYC"}'::jsonb,
    'open'::public.job_status
  ) returning id into v_job_open;

  insert into public.job_timeline_events (job_id, event_type, title)
  values (v_job_open, 'posted', 'Job posted (demo seed)');

  -- Hired + active-ish pipeline when a sitter exists
  if v_sitter is not null then
    insert into public.jobs (
      family_id, title, description, date, start_time, end_time,
      number_of_children, child_ids, location_lat, location_lng,
      location_address, status
    ) values (
      v_family,
      'Demo weekend sitter (hired)',
      'Seeded hire row for admin list.',
      current_date,
      (current_date::timestamptz + time '10:00'),
      (current_date::timestamptz + time '14:00'),
      1, array[v_child]::uuid[], 40.7128, -74.0060,
      '{"line1":"Demo Ave, NYC"}'::jsonb,
      'hired'::public.job_status
    ) returning id into v_job_hired;

    insert into public.hires (job_id, sitter_id, hourly_rate)
    values (v_job_hired, v_sitter, 14.00);

    insert into public.job_timeline_events (job_id, event_type, title, actor_id)
    values
      (v_job_hired, 'posted', 'Job posted (demo seed)', v_family),
      (v_job_hired, 'hired', 'Sitter hired (demo seed)', v_family);

    insert into public.jobs (
      family_id, title, description, date, start_time, end_time,
      number_of_children, child_ids, location_lat, location_lng,
      location_address, status
    ) values (
      v_family,
      'Demo daytime sitter (active)',
      'Seeded in-progress style job.',
      current_date,
      (current_date::timestamptz + time '08:00'),
      (current_date::timestamptz + time '12:00'),
      1, array[v_child]::uuid[], 40.7128, -74.0060,
      '{"line1":"Demo Blvd, NYC"}'::jsonb,
      'active'::public.job_status
    ) returning id into v_job_active;

    insert into public.hires (job_id, sitter_id, hourly_rate)
    values (v_job_active, v_sitter, 15.00);

    insert into public.job_timeline_events (job_id, event_type, title, actor_id)
    values
      (v_job_active, 'posted', 'Job posted (demo seed)', v_family),
      (v_job_active, 'hired', 'Sitter hired (demo seed)', v_family);
  end if;

  -- Completed job (no hire required for listing; sitter name may be empty)
  insert into public.jobs (
    family_id, title, description, date, start_time, end_time,
    number_of_children, child_ids, location_lat, location_lng,
    location_address, status
  ) values (
    v_family,
    'Demo past sitter (completed)',
    'Seeded completed job.',
    (current_date - 2),
    (current_date - 2)::timestamptz + time '16:00',
    (current_date - 2)::timestamptz + time '19:00',
    1, array[v_child]::uuid[], 40.7128, -74.0060,
    '{"line1":"Demo Rd, NYC"}'::jsonb,
    'completed'::public.job_status
  ) returning id into v_job_done;

  insert into public.job_timeline_events (job_id, event_type, title)
  values
    (v_job_done, 'posted', 'Job posted (demo seed)'),
    (v_job_done, 'completed', 'Marked completed (demo seed)');

  -- ---------------------------------------------------------------------------
  -- 3) Disputes (admin /disputes) — attach to completed job when possible
  -- ---------------------------------------------------------------------------
  if v_job_done is not null and v_sitter is not null then
    insert into public.disputes (
      job_id, reported_by_user_id, reported_by_role,
      issue_type, description, priority, status
    ) values
      (
        v_job_done, v_family, 'family',
        'time_discrepancy', 'Demo: hours looked wrong on checkout.', 'high', 'open'
      ),
      (
        v_job_done, v_sitter, 'sitter',
        'payment_issue', 'Demo: payout not visible after job.', 'medium', 'investigating'
      );
  elsif v_job_open is not null then
    insert into public.disputes (
      job_id, reported_by_user_id, reported_by_role,
      issue_type, description, priority, status
    ) values (
      v_job_open, v_family, 'family',
      'other', 'Demo dispute on open job.', 'low', 'open'
    );
  end if;
end $$;

commit;
