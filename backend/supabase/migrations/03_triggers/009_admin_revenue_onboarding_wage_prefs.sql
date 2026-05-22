-- Monthly ledger revenue for admin dashboard chart + wage rounding/overtime defaults in system_config.

insert into public.system_config (key, value) values
  ('time_rounding_mode', '"exact"'::jsonb),
  ('overtime_mode', '"disabled"'::jsonb)
on conflict (key) do nothing;

create or replace function public.admin_report_revenue_per_month(p_months int default 6)
returns table(bucket_month date, month_label text, revenue numeric)
language plpgsql
stable
security definer
set search_path = public as $$
declare
  m int := greatest(coalesce(p_months, 6), 1);
  start_m date;
begin
  perform public.admin_only();
  start_m := date_trunc('month', now())::date - ((m - 1) || ' months')::interval;
  return query
  with series as (
    select generate_series(start_m, date_trunc('month', now())::date, interval '1 month')::date as b
  )
  select s.b as bucket_month,
         to_char(s.b, 'Mon YYYY') as month_label,
         coalesce((
           select sum(le.amount)::numeric(14, 2)
           from public.ledger_entries le
           where le.type = 'earning'::public.ledger_type
             and date_trunc('month', le.created_at)::date = s.b
         ), 0)::numeric as revenue
  from series s
  order by s.b;
end;
$$;

create or replace function public.admin_recent_onboarding(p_limit int default 30)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public as $$
declare
  lim int := greatest(coalesce(p_limit, 30), 1);
begin
  perform public.admin_only();
  return query
  with combined as (
    select
      u.created_at as ts,
      jsonb_build_object(
        'type', 'Family',
        'name', coalesce(nullif(trim(both from coalesce(u.full_name, '')), ''), u.email),
        'email', u.email,
        'date', to_char(u.created_at::date, 'YYYY-MM-DD'),
        'status',
        case when fp.bg_check_status = 'approved'::public.verification_status then 'Verified' else 'Pending' end,
        'details', jsonb_build_object(
          'type', 'Family',
          'name', coalesce(nullif(trim(both from coalesce(u.full_name, '')), ''), u.email),
          'registeredOn', to_char(u.created_at::date, 'YYYY-MM-DD'),
          'status',
          case when fp.bg_check_status = 'approved'::public.verification_status then 'Verified' else 'Pending' end,
          'email', u.email,
          'phone', coalesce(u.phone, '—'),
          'address',
          coalesce(
            nullif(trim(both from fp.home_address->>'line1'), ''),
            nullif(trim(both from fp.home_address->>'formatted'), ''),
            nullif(trim(both from fp.home_address->>'address'), ''),
            '—'
          ),
          'numberOfChildren', (
            select count(*)::int from public.children c where c.family_id = fp.user_id
          ),
          'childrenAges', coalesce((
            select string_agg(c.age::text, ', ' order by c.age)
            from public.children c
            where c.family_id = fp.user_id
          ), '—'),
          'backgroundCheck',
          case fp.bg_check_status
            when 'approved'::public.verification_status then 'Approved'
            when 'rejected'::public.verification_status then 'Rejected'
            when 'pending'::public.verification_status then 'In progress'
            else 'Not submitted'
          end,
          'preferredRate',
          case
            when fp.babysitter_prefs ? 'hourly_rate_min' then
              '$' || coalesce(fp.babysitter_prefs->>'hourly_rate_min', '?')
              || coalesce('-' || (fp.babysitter_prefs->>'hourly_rate_max'), '') || '/hr'
            else '—'
          end
        )
      ) as j
    from public.family_profiles fp
    join public.users u on u.id = fp.user_id
    union all
    select
      u.created_at as ts,
      jsonb_build_object(
        'type', 'Babysitter',
        'name', coalesce(nullif(trim(both from coalesce(u.full_name, '')), ''), u.email),
        'email', u.email,
        'date', to_char(u.created_at::date, 'YYYY-MM-DD'),
        'status',
        case when sp.guardian_consent_status = 'approved'::public.verification_status then 'Verified' else 'Pending' end,
        'details', jsonb_build_object(
          'type', 'Babysitter',
          'name', coalesce(nullif(trim(both from coalesce(u.full_name, '')), ''), u.email),
          'registeredOn', to_char(u.created_at::date, 'YYYY-MM-DD'),
          'status',
          case when sp.guardian_consent_status = 'approved'::public.verification_status then 'Verified' else 'Pending' end,
          'email', u.email,
          'phone', coalesce(u.phone, '—'),
          'address', '—',
          'yearsOfExperience', 0,
          'ageGroups', '—',
          'backgroundCheck',
          case sp.guardian_consent_status
            when 'approved'::public.verification_status then 'Guardian consent approved'
            when 'rejected'::public.verification_status then 'Guardian consent rejected'
            when 'pending'::public.verification_status then 'Guardian consent pending'
            else 'Guardian consent not submitted'
          end,
          'hourlyRate', '—'
        )
      ) as j
    from public.sitter_profiles sp
    join public.users u on u.id = sp.user_id
  )
  select c.j
  from combined c
  order by c.ts desc
  limit lim;
end;
$$;

revoke all on function public.admin_report_revenue_per_month(int) from public;
revoke all on function public.admin_recent_onboarding(int) from public;

grant execute on function public.admin_report_revenue_per_month(int) to authenticated;
grant execute on function public.admin_recent_onboarding(int) to authenticated;
