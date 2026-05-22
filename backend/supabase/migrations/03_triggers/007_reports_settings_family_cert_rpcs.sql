-- BACKEND.md §5/§7/§31: report RPCs, admin_update_system_config, family/sitter compliance RPCs,
-- relax notifications.delivery_status (Edge send_push uses mock_ok, partial, etc.).

alter table public.notifications
  drop constraint if exists notifications_delivery_status_check;

insert into public.system_config (key, value) values
  ('min_sitter_age', '13'::jsonb),
  ('max_job_duration_hours', '8'::jsonb),
  ('admin_two_factor_ui_enabled', 'true'::jsonb),
  ('data_auto_cleanup_enabled', 'false'::jsonb),
  ('backup_frequency', '"Daily"'::jsonb)
on conflict (key) do nothing;

create or replace function public.admin_update_system_config(p_configs jsonb)
returns void
language plpgsql
security definer
set search_path = public as $$
declare
  r record;
begin
  perform public.admin_only();
  if p_configs is null or jsonb_typeof(p_configs) <> 'object' then
    raise exception 'p_configs must be a json object';
  end if;

  for r in select * from jsonb_each(p_configs)
  loop
    insert into public.system_config (key, value, updated_by)
    values (r.key, r.value, auth.uid())
    on conflict (key) do update
      set value      = excluded.value,
          updated_at = now(),
          updated_by = excluded.updated_by;
  end loop;

  perform public.write_audit_log(
    'admin_update_system_config',
    'system_config',
    null,
    null,
    p_configs
  );
end;
$$;

create or replace function public.family_submit_background_check(p_documents jsonb)
returns void
language plpgsql
security definer
set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_bg  uuid;
begin
  if public.current_user_role() is distinct from 'family' then
    raise exception 'only family accounts may submit a background check';
  end if;

  perform set_config('app.bypass_immutability', 'true', true);

  update public.family_profiles
     set bg_check_status = 'pending'::public.verification_status,
         rejection_reason = null
   where user_id = v_uid;

  if not found then
    raise exception 'family profile not found';
  end if;

  insert into public.background_checks (family_id, documents, status)
  values (v_uid, coalesce(p_documents, '[]'::jsonb), 'pending'::public.verification_status)
  on conflict (family_id) do update
    set documents    = excluded.documents,
        status         = 'pending'::public.verification_status,
        submitted_at   = now(),
        reviewed_by    = null,
        reviewed_at    = null,
        admin_notes    = null;

  select id into v_bg from public.background_checks where family_id = v_uid limit 1;

  perform public.write_audit_log(
    'family_submit_background_check',
    'background_checks',
    v_bg,
    null,
    jsonb_build_object(
      'doc_count',
      coalesce(jsonb_array_length(coalesce(p_documents, '[]'::jsonb)), 0)
    )
  );
end;
$$;

create or replace function public.sitter_submit_certification(
  p_course_id            uuid,
  p_score                numeric default null,
  p_questions_answered   int default null,
  p_correct_answers      int default null,
  p_time_taken_seconds   int default null
)
returns void
language plpgsql
security definer
set search_path = public as $$
declare
  v_uid    uuid := auth.uid();
  v_status public.verification_status;
begin
  if public.current_user_role() is distinct from 'sitter' then
    raise exception 'only sitter accounts may submit certifications';
  end if;

  if not exists (
    select 1 from public.courses c
    where c.id = p_course_id and c.status = 'published'
  ) then
    raise exception 'course not found or not published';
  end if;

  select cs.status into v_status
  from public.certification_submissions cs
  where cs.sitter_id = v_uid and cs.course_id = p_course_id;

  if v_status is null then
    insert into public.certification_submissions (
      sitter_id, course_id, score, questions_answered, correct_answers,
      time_taken_seconds, status, submitted_at
    )
    values (
      v_uid, p_course_id, p_score, p_questions_answered, p_correct_answers,
      p_time_taken_seconds, 'pending'::public.verification_status, now()
    );
  elsif v_status = 'rejected' then
    update public.certification_submissions
       set score                 = p_score,
           questions_answered    = p_questions_answered,
           correct_answers       = p_correct_answers,
           time_taken_seconds    = p_time_taken_seconds,
           status                = 'pending'::public.verification_status,
           rejection_reason      = null,
           submitted_at          = now(),
           reviewed_at           = null,
           reviewed_by           = null
     where sitter_id = v_uid and course_id = p_course_id;
  else
    raise exception 'certification submission already %', v_status;
  end if;

  perform public.write_audit_log(
    'sitter_submit_certification',
    'certification_submissions',
    p_course_id,
    null,
    jsonb_build_object('sitter_id', v_uid, 'course_id', p_course_id)
  );
end;
$$;

create or replace function public.admin_report_jobs_per_month(p_months int default 6)
returns table(bucket_month date, month_label text, jobs bigint)
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
         (
           select count(*)::bigint
           from public.jobs j
           where date_trunc('month', j.created_at)::date = s.b
         ) as jobs
  from series s
  order by s.b;
end;
$$;

create or replace function public.admin_report_hours_per_month(p_months int default 6)
returns table(bucket_month date, month_label text, hours numeric)
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
           select round((sum(te.computed_minutes)::numeric / 60.0), 2)
           from public.time_entries te
           where te.clock_out_at is not null
             and date_trunc('month', te.clock_out_at)::date = s.b
         ), 0)::numeric as hours
  from series s
  order by s.b;
end;
$$;

create or replace function public.admin_report_wage_distribution()
returns table(name text, value numeric)
language plpgsql
stable
security definer
set search_path = public as $$
begin
  perform public.admin_only();
  return query
  with latest_tiers as (
    select distinct on (awt.min_age, awt.max_age)
      awt.min_age,
      awt.max_age
    from public.age_wage_tiers awt
    order by awt.min_age, awt.max_age, awt.effective_from desc
  )
  select ('Age ' || lt.min_age || '–' || lt.max_age)::text as name,
         coalesce((
           select sum(le.amount)::numeric(14, 2)
           from public.ledger_entries le
           join public.sitter_profiles sp on sp.user_id = le.sitter_id
           where le.type = 'earning'::public.ledger_type
             and le.created_at > now() - interval '12 months'
             and floor(extract(year from age(current_date, sp.date_of_birth)))::int
                 between lt.min_age and lt.max_age
         ), 0)::numeric as value
  from latest_tiers lt
  order by lt.min_age;
end;
$$;

create or replace function public.admin_report_job_status_distribution()
returns table(name text, value bigint)
language plpgsql
stable
security definer
set search_path = public as $$
begin
  perform public.admin_only();
  return query
  select initcap(replace(j.status::text, '_', ' ')) as name,
         count(*)::bigint as value
  from public.jobs j
  group by j.status
  order by value desc;
end;
$$;

create or replace function public.admin_report_user_growth(p_months int default 6)
returns table(bucket_month date, month_label text, families bigint, babysitters bigint)
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
         (
           select count(*)::bigint
           from public.users u
           where u.role = 'family'
             and date_trunc('month', u.created_at)::date = s.b
         ) as families,
         (
           select count(*)::bigint
           from public.users u
           where u.role = 'sitter'
             and date_trunc('month', u.created_at)::date = s.b
         ) as babysitters
  from series s
  order by s.b;
end;
$$;

create or replace function public.admin_report_cert_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = public as $$
declare
  v_tot   int;
  v_appr  int;
  v_avg   numeric(10, 2);
  v_name  text;
  v_count bigint;
begin
  perform public.admin_only();

  select count(*)::int into v_tot
  from public.certification_submissions cs
  where cs.status in ('approved', 'rejected');

  select count(*)::int into v_appr
  from public.certification_submissions cs
  where cs.status = 'approved';

  select coalesce(
    avg(extract(epoch from (cs.reviewed_at - cs.submitted_at)) / 86400.0)::numeric(10, 2),
    0
  ) into v_avg
  from public.certification_submissions cs
  where cs.reviewed_at is not null
    and cs.status in ('approved', 'rejected');

  select c.name, count(*)::bigint
  into v_name, v_count
  from public.certification_submissions cs
  join public.courses c on c.id = cs.course_id
  group by c.name
  order by count(*) desc
  limit 1;

  return jsonb_build_object(
    'approval_rate',
    case when coalesce(v_tot, 0) = 0 then 0::numeric
         else round(100.0 * v_appr::numeric / v_tot::numeric, 1) end,
    'avg_processing_days', coalesce(v_avg, 0),
    'most_popular_course', coalesce(v_name, '—'),
    'most_popular_enrollments', coalesce(v_count, 0),
    'decided_submissions', coalesce(v_tot, 0)
  );
end;
$$;

create or replace function public.admin_report_summary(p_months int default 6)
returns jsonb
language plpgsql
stable
security definer
set search_path = public as $$
declare
  m       int := greatest(coalesce(p_months, 6), 1);
  v_start timestamptz;
  v_rev   numeric(14, 2);
  v_jobs  bigint;
  v_mins  bigint;
  v_hours numeric(14, 2);
  v_avg   numeric(14, 2);
begin
  perform public.admin_only();
  v_start := date_trunc('month', now()) - ((m - 1) || ' months')::interval;

  select coalesce(sum(le.amount), 0)::numeric(14, 2) into v_rev
  from public.ledger_entries le
  where le.type = 'earning'::public.ledger_type
    and le.created_at >= v_start;

  select count(*)::bigint into v_jobs
  from public.jobs j
  where j.status = 'completed'::public.job_status
    and j.updated_at >= v_start;

  select coalesce(sum(te.computed_minutes), 0)::bigint into v_mins
  from public.time_entries te
  where te.clock_out_at is not null
    and te.clock_out_at >= v_start;

  v_hours := round(v_mins::numeric / 60.0, 2);
  v_avg := case when coalesce(v_jobs, 0) = 0 then 0::numeric(14, 2)
                else round(v_hours / v_jobs::numeric, 2) end;

  return jsonb_build_object(
    'total_revenue', v_rev,
    'total_jobs', v_jobs,
    'total_hours', v_hours,
    'avg_duration', v_avg,
    'window_months', m
  );
end;
$$;

revoke all on function public.admin_update_system_config(jsonb) from public;
revoke all on function public.family_submit_background_check(jsonb) from public;
revoke all on function public.sitter_submit_certification(uuid, numeric, int, int, int) from public;
revoke all on function public.admin_report_jobs_per_month(int) from public;
revoke all on function public.admin_report_hours_per_month(int) from public;
revoke all on function public.admin_report_wage_distribution() from public;
revoke all on function public.admin_report_job_status_distribution() from public;
revoke all on function public.admin_report_user_growth(int) from public;
revoke all on function public.admin_report_cert_stats() from public;
revoke all on function public.admin_report_summary(int) from public;

grant execute on function public.admin_update_system_config(jsonb) to authenticated;
grant execute on function public.family_submit_background_check(jsonb) to authenticated;
grant execute on function public.sitter_submit_certification(uuid, numeric, int, int, int) to authenticated;
grant execute on function public.admin_report_jobs_per_month(int) to authenticated;
grant execute on function public.admin_report_hours_per_month(int) to authenticated;
grant execute on function public.admin_report_wage_distribution() to authenticated;
grant execute on function public.admin_report_job_status_distribution() to authenticated;
grant execute on function public.admin_report_user_growth(int) to authenticated;
grant execute on function public.admin_report_cert_stats() to authenticated;
grant execute on function public.admin_report_summary(int) to authenticated;
