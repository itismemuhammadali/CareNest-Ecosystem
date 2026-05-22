-- Ensure auth.users insert creates profile rows (BACKEND.md §10)
create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer
set search_path = public as $$
declare
  v_role public.user_role;
begin
  v_role := coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'family');

  insert into public.users (id, role, email, full_name, phone)
  values (
    new.id,
    v_role,
    new.email,
    coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), ''),
    nullif(trim(new.raw_user_meta_data->>'phone'), '')
  )
  on conflict (id) do update set
    email     = excluded.email,
    full_name = coalesce(excluded.full_name, public.users.full_name),
    phone     = coalesce(excluded.phone, public.users.phone);

  if v_role = 'family' then
    insert into public.family_profiles (user_id)
    values (new.id)
    on conflict (user_id) do nothing;

  elsif v_role = 'sitter' then
    insert into public.sitter_profiles (user_id, date_of_birth)
    values (
      new.id,
      coalesce(
        (nullif(trim(new.raw_user_meta_data->>'date_of_birth'), ''))::date,
        (current_date - interval '14 years')::date
      )
    )
    on conflict (user_id) do nothing;
  end if;

  return new;
end;
$$;
