-- Allow sitters to read jobs they applied to or were hired for (BACKEND.md §17 job history / my applications).
-- Without this, only policy "jobs: sitter sees open jobs" applies and nested job rows disappear after status changes.

create policy "jobs: sitter sees jobs via application or hire"
  on public.jobs for select
  using (
    public.current_user_role() = 'sitter'
    and (
      exists (
        select 1 from public.applications a
        where a.job_id = jobs.id and a.sitter_id = auth.uid()
      )
      or exists (
        select 1 from public.hires h
        where h.job_id = jobs.id and h.sitter_id = auth.uid()
      )
    )
  );
