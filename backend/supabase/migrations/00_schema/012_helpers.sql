-- Star Sitters — admin_only, audit, cfg_* (BACKEND.md §5 Migration 12)
create or replace function public.admin_only()
returns void
language plpgsql security definer
set search_path = public as $$
begin
  if not exists (
    select 1 from public.admin_users where id = auth.uid()
  ) then
    raise exception 'unauthorized: admin role required'
      using errcode = '42501';
  end if;
end;
$$;

create or replace function public.admin_only_bool()
returns boolean
language sql stable security definer
set search_path = public as $$
  select exists (select 1 from public.admin_users where id = auth.uid());
$$;

create or replace function public.write_audit_log(
  p_action       text,
  p_entity_type  text,
  p_entity_id    uuid,
  p_before       jsonb default null,
  p_after        jsonb default null
)
returns void
language plpgsql security definer
set search_path = public as $$
begin
  insert into public.audit_logs (
    actor_id, action, entity_type, entity_id, before_state, after_state, created_at
  ) values (
    auth.uid(), p_action, p_entity_type, p_entity_id, p_before, p_after, now()
  );
end;
$$;

create or replace function public.cfg_bool(p_key text, p_default boolean default false)
returns boolean language sql stable as $$
  select coalesce((select value::boolean from public.system_config where key = p_key), p_default);
$$;

create or replace function public.cfg_text(p_key text, p_default text default '')
returns text language sql stable as $$
  select coalesce((select value #>> '{}' from public.system_config where key = p_key), p_default);
$$;

create or replace function public.cfg_int(p_key text, p_default int default 0)
returns int language sql stable as $$
  select coalesce((select (value)::int from public.system_config where key = p_key), p_default);
$$;
