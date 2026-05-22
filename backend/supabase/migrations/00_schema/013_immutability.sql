-- Star Sitters — immutability triggers (BACKEND.md §5 Migration 13)
create or replace function public.tx_immutability_bypass()
returns boolean
language sql stable as $$
  select coalesce(current_setting('app.bypass_immutability', true), 'false') = 'true';
$$;

create or replace function public.fn_prevent_role_change()
returns trigger language plpgsql as $$
begin
  if old.role is distinct from new.role
     and not public.tx_immutability_bypass()
     and not public.admin_only_bool()
  then
    raise exception 'role is immutable for non-admins'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger trg_users_role_immutable
  before update on public.users
  for each row execute function public.fn_prevent_role_change();

create or replace function public.fn_sitter_lock_admin_fields()
returns trigger language plpgsql as $$
begin
  if not public.tx_immutability_bypass() and not public.admin_only_bool() then
    if old.is_active is distinct from new.is_active then
      raise exception 'is_active is admin-only' using errcode = '42501';
    end if;
    if old.guardian_consent_status is distinct from new.guardian_consent_status then
      raise exception 'guardian_consent_status is admin-only' using errcode = '42501';
    end if;
    if old.total_minutes_worked is distinct from new.total_minutes_worked then
      raise exception 'total_minutes_worked is server-maintained' using errcode = '42501';
    end if;
    if old.total_earnings is distinct from new.total_earnings then
      raise exception 'total_earnings is server-maintained' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_sitter_lock_admin_fields
  before update on public.sitter_profiles
  for each row execute function public.fn_sitter_lock_admin_fields();

create or replace function public.fn_family_lock_admin_fields()
returns trigger language plpgsql as $$
begin
  if not public.tx_immutability_bypass() and not public.admin_only_bool() then
    if old.bg_check_status is distinct from new.bg_check_status then
      raise exception 'bg_check_status is admin-only' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_family_lock_admin_fields
  before update on public.family_profiles
  for each row execute function public.fn_family_lock_admin_fields();
