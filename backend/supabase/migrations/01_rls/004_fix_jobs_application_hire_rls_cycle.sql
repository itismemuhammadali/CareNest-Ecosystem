-- Fix 42P17: Break jobs ↔ applications ↔ hires RLS recursion cycle.
--
-- Migration 20260512120000 added policy "jobs: sitter sees jobs via application or hire"
-- which queries applications and hires directly. Those tables have RLS policies that
-- query jobs in turn, creating cycles:
--   jobs → applications → jobs  (infinite recursion)
--   jobs → hires        → jobs  (infinite recursion)
--
-- Fix: introduce SECURITY DEFINER helpers with row_security = off (same pattern used
-- in migration 20260215133000 for the jobs ↔ family_profiles cycle).

-- Helper: check if current sitter applied to a specific job (bypasses RLS)
create or replace function public.sitter_applied_to_job(p_job_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select exists (
    select 1 from public.applications a
    where a.job_id = p_job_id and a.sitter_id = auth.uid()
  );
$$;

-- Helper: check if current sitter was hired for a specific job (bypasses RLS)
create or replace function public.sitter_hired_for_job(p_job_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select exists (
    select 1 from public.hires h
    where h.job_id = p_job_id and h.sitter_id = auth.uid()
  );
$$;

grant execute on function public.sitter_applied_to_job(uuid) to authenticated;
grant execute on function public.sitter_hired_for_job(uuid) to authenticated;

-- Drop and recreate the offending policy using RLS-bypass helpers
drop policy if exists "jobs: sitter sees jobs via application or hire" on public.jobs;

create policy "jobs: sitter sees jobs via application or hire"
  on public.jobs for select
  using (
    public.current_user_role() = 'sitter'
    and (
      public.sitter_applied_to_job(jobs.id)
      or public.sitter_hired_for_job(jobs.id)
    )
  );

-- Also harden "jobs: family insert" which subqueries family_profiles directly.
-- Use the existing helper from migration 20260215133000 to avoid a potential cycle.
drop policy if exists "jobs: family insert" on public.jobs;

create policy "jobs: family insert"
  on public.jobs for insert
  with check (
    family_id = auth.uid()
    and public.family_bg_check_approved(auth.uid())
  );
