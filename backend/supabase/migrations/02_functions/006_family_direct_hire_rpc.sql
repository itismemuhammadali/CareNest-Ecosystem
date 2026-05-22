-- C5: family_direct_hire — atomic job + application + hire for the
-- "browse sitter → hire directly" flow in the Family app.
-- The family picks a sitter from the browse screen (no job posted yet).
-- This RPC creates the job, creates an accepted application on behalf of
-- the sitter, creates the hire row, and opens the conversation.

create or replace function public.family_direct_hire(
  p_sitter_id      uuid,
  p_date           date,
  p_start_time     timestamptz,
  p_end_time       timestamptz,
  p_num_children   int  default 1,
  p_title          text default 'Direct hire'
)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_family_id  uuid := auth.uid();
  v_job_id     uuid;
  v_app_id     uuid;
  v_hire       public.hires;
  v_rate       numeric(10,2);
  v_sitter_age int;
  v_conv_id    uuid;
begin
  if v_family_id is null then
    raise exception 'not authenticated';
  end if;

  -- 1. Create the job (status = 'open' so create_hire constraint passes)
  insert into public.jobs (
    family_id, title, date, start_time, end_time,
    number_of_children, status,
    location_lat, location_lng, location_address, geofence_radius_m
  ) values (
    v_family_id, p_title, p_date, p_start_time, p_end_time,
    p_num_children, 'open',
    0, 0, '{}'::jsonb, 150
  )
  returning id into v_job_id;

  -- 2. Create an application on behalf of the sitter (SECURITY DEFINER bypasses RLS)
  insert into public.applications (job_id, sitter_id, status, cover_message)
  values (v_job_id, p_sitter_id, 'pending', null)
  returning id into v_app_id;

  -- 3. Get sitter age + wage rate
  select (date_part('year', age(current_date, date_of_birth)))::int
    into v_sitter_age
    from public.sitter_profiles
   where user_id = p_sitter_id;

  select hourly_rate into v_rate
    from public.age_wage_tiers
   where v_sitter_age between min_age and max_age
   order by effective_from desc
   limit 1;

  if v_rate is null then
    raise exception 'no wage tier configured for sitter age %', v_sitter_age;
  end if;

  -- 4. Accept the application
  update public.applications set status = 'accepted' where id = v_app_id;

  -- 5. Create hire
  insert into public.hires (job_id, sitter_id, hourly_rate)
  values (v_job_id, p_sitter_id, v_rate)
  returning * into v_hire;

  -- 6. Update job status to hired
  update public.jobs set status = 'hired' where id = v_job_id;

  -- 7. Open conversation
  insert into public.conversations (job_id, family_id, sitter_id)
  values (v_job_id, v_family_id, p_sitter_id)
  on conflict (job_id, sitter_id) do nothing
  returning id into v_conv_id;

  -- 8. Audit log
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_family_id, 'direct_hire_created', 'hires', v_hire.id,
    jsonb_build_object(
      'job_id', v_hire.job_id,
      'sitter_id', v_hire.sitter_id,
      'hourly_rate', v_hire.hourly_rate
    )
  );

  return jsonb_build_object(
    'hire_id',          v_hire.id,
    'job_id',           v_job_id,
    'application_id',   v_app_id,
    'conversation_id',  v_conv_id,
    'hourly_rate',      v_rate
  );
end;
$$;

grant execute on function public.family_direct_hire(uuid, date, timestamptz, timestamptz, int, text)
  to authenticated;
