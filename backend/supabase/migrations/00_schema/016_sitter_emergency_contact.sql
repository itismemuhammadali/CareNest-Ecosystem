-- Add emergency_contact JSONB column to sitter_profiles.
-- Stores: { contact_name, relationship, phone, dial_code, country_code, email }
-- Existing RLS on sitter_profiles already allows sitters to update their own row.

alter table public.sitter_profiles
  add column if not exists emergency_contact jsonb not null default '{}';
