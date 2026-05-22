-- C8: Add required_certifications column to jobs.
-- Families can specify which cert_types a sitter must hold to apply.
-- The application RPC does not enforce this yet; enforcement is in the Flutter client
-- and should be added server-side as a follow-up check_constraint or RPC guard.

alter table public.jobs
  add column if not exists required_certifications text[] not null default '{}';
