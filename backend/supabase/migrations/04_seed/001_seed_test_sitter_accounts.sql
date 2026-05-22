-- Seed test sitter accounts for QA/audit purposes.
-- Uses ALTER TABLE ... DISABLE TRIGGER to bypass the admin-only field guard
-- (this migration runs as postgres superuser so it can do this safely).
-- Sitters must be 11-18 years old (chk_sitter_age).

begin;

-- First, create the auth user if it doesn't exist
insert into auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
)
values (
  '7d018c2d-e00b-4946-afee-ac8f304e4f5a',
  '00000000-0000-0000-0000-000000000000',
  'emma.johnson@test.com',
  crypt('password123', gen_salt('bf')),
  now(),
  jsonb_build_object('role', 'sitter', 'full_name', 'Emma Johnson'),
  now(),
  now()
)
on conflict (id) do nothing;

-- The trigger will create the public.users row automatically
-- But we need to update the role to sitter
alter table public.users disable trigger trg_users_role_immutable;

update public.users
set
  role      = 'sitter',
  full_name = 'Emma Johnson'
where id = '7d018c2d-e00b-4946-afee-ac8f304e4f5a';

alter table public.users enable trigger trg_users_role_immutable;

-- Disable the admin-only field trigger to allow setting is_active
alter table public.sitter_profiles disable trigger trg_sitter_lock_admin_fields;

-- Create sitter_profiles row (sitter born 2010-03-20 = 16 years old in 2026)
insert into public.sitter_profiles (user_id, date_of_birth, is_active, guardian_consent_status)
values (
  '7d018c2d-e00b-4946-afee-ac8f304e4f5a',
  '2010-03-20',
  true,
  'approved'
)
on conflict (user_id) do update
  set is_active                = true,
      date_of_birth            = '2010-03-20',
      guardian_consent_status  = 'approved';

-- Re-enable the trigger
alter table public.sitter_profiles enable trigger trg_sitter_lock_admin_fields;

commit;
