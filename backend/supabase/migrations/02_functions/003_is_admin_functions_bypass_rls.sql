-- Harden admin helpers: inside SECURITY DEFINER, row_security must be off so reads
-- on public.admin_users do not re-evaluate RLS (avoids infinite recursion and 500s
-- even if a policy on admin_users ever calls is_admin() again).

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select exists (
    select 1 from public.admin_users where id = auth.uid()
  );
$$;

create or replace function public.admin_only_bool()
returns boolean
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select exists (select 1 from public.admin_users where id = auth.uid());
$$;

create or replace function public.admin_only()
returns void
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
begin
  if not exists (
    select 1 from public.admin_users where id = auth.uid()
  ) then
    raise exception 'unauthorized: admin role required'
      using errcode = '42501';
  end if;
end;
$$;
