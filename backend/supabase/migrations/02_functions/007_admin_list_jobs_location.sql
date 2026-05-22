-- Add location_address, location_lat, location_lng to admin_list_jobs RPC
drop function if exists public.admin_list_jobs(text, text, int, int);

create or replace function public.admin_list_jobs(
  p_status_filter text default 'all',
  p_search        text default '',
  p_page          int  default 1,
  p_page_size     int  default 20
)
returns table (
  job_id           uuid,
  family_name      text,
  sitter_name      text,
  job_date         date,
  status           text,
  computed_minutes int,
  computed_wage    numeric(12,2),
  timeline         jsonb,
  location_address jsonb,
  location_lat     double precision,
  location_lng     double precision
)
language plpgsql security definer
set search_path = public as $$
begin
  perform public.admin_only();

  return query
  select
    j.id as job_id,
    fu.full_name as family_name,
    su.full_name as sitter_name,
    j.date as job_date,
    j.status::text as status,
    te.computed_minutes,
    te.computed_wage,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'event_type', jt.event_type,
            'title', jt.title,
            'created_at', jt.created_at
          ) order by jt.created_at
        )
        from public.job_timeline_events jt
        where jt.job_id = j.id
      ),
      '[]'::jsonb
    ) as timeline,
    j.location_address,
    j.location_lat,
    j.location_lng
  from public.jobs j
  join public.family_profiles fp on fp.user_id = j.family_id
  join public.users fu on fu.id = fp.user_id
  left join public.hires h on h.job_id = j.id
  left join public.sitter_profiles sp on sp.user_id = h.sitter_id
  left join public.users su on su.id = sp.user_id
  left join lateral (
    select te2.computed_minutes, te2.computed_wage
    from public.time_entries te2
    join public.hires h2 on h2.id = te2.hire_id
    where h2.job_id = j.id
      and te2.clock_out_at is not null
    order by te2.clock_out_at desc nulls last
    limit 1
  ) te on true
  where (p_status_filter = 'all' or j.status::text = p_status_filter)
    and (
      p_search = ''
      or fu.full_name ilike '%' || p_search || '%'
      or coalesce(su.full_name, '') ilike '%' || p_search || '%'
      or j.id::text = p_search
    )
  order by j.created_at desc
  limit p_page_size offset (p_page - 1) * p_page_size;
end;
$$;

revoke all on function public.admin_list_jobs(text, text, int, int) from public;
grant execute on function public.admin_list_jobs(text, text, int, int) to authenticated;
