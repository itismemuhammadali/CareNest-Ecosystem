-- Fix H9: wage tier changes were effective tomorrow, now effective today
create or replace function public.admin_update_wage_tiers(p_tiers jsonb)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_admin uuid := auth.uid();
  v_tier  jsonb;
  v_effective date := current_date;
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

  insert into public.audit_logs (actor_id, action, entity_type, entity_id, metadata)
  values (
    v_admin,
    'admin_update_wage_tiers', 'age_wage_tiers', null,
    jsonb_build_object('tiers', p_tiers, 'effective_from', v_effective)
  );
end;
$$;
