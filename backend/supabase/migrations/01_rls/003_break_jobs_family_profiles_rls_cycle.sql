-- Fix 42P17 infinite recursion between jobs ↔ family_profiles RLS.
-- "jobs: sitter sees open jobs" subqueries family_profiles; "family_profiles: sitter sees
-- relevant families" subqueries jobs. Postgres may evaluate both policy trees → cycle.
-- Helpers run with row_security off so membership/bg checks do not re-enter RLS.

create or replace function public.family_bg_check_approved(p_family_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select coalesce(
    (
      select fp.bg_check_status = 'approved'::public.verification_status
      from public.family_profiles fp
      where fp.user_id = p_family_user_id
    ),
    false
  );
$$;

create or replace function public.sitter_applied_to_family_jobs(p_family_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select exists (
    select 1
    from public.jobs j
    join public.applications a on a.job_id = j.id
    where j.family_id = p_family_user_id
      and a.sitter_id = auth.uid()
  );
$$;

grant execute on function public.family_bg_check_approved(uuid) to authenticated;
grant execute on function public.sitter_applied_to_family_jobs(uuid) to authenticated;

drop policy if exists "family_profiles: sitter sees relevant families" on public.family_profiles;

create policy "family_profiles: sitter sees relevant families"
  on public.family_profiles for select
  using (
    public.current_user_role() = 'sitter'
    and public.sitter_applied_to_family_jobs(family_profiles.user_id)
  );

drop policy if exists "jobs: sitter sees open jobs" on public.jobs;

create policy "jobs: sitter sees open jobs"
  on public.jobs for select
  using (
    public.current_user_role() = 'sitter'
    and status = 'open'::public.job_status
    and public.family_bg_check_approved(jobs.family_id)
  );

drop policy if exists "jobs: family insert" on public.jobs;

create policy "jobs: family insert"
  on public.jobs for insert
  with check (
    family_id = auth.uid()
    and public.family_bg_check_approved(auth.uid())
  );
