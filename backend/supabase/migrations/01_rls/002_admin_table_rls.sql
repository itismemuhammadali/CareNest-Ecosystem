-- Star Sitters — §31.7 RLS for admin-era tables (BACKEND.md §31.7)
-- admin_users policies remain as in Migration 15 (admins may list admin_users).

alter table public.courses enable row level security;
alter table public.certification_submissions enable row level security;
alter table public.disputes enable row level security;
alter table public.uploaded_documents enable row level security;
alter table public.job_timeline_events enable row level security;

create policy "courses: published readable"
  on public.courses for select
  using (status = 'published');

create policy "courses: admin read all"
  on public.courses for select
  using (public.is_admin());

create policy "courses: admin write"
  on public.courses for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "cert_submissions: sitter select own"
  on public.certification_submissions for select
  using (sitter_id = auth.uid());

create policy "cert_submissions: sitter insert own"
  on public.certification_submissions for insert
  with check (sitter_id = auth.uid());

create policy "cert_submissions: admin select all"
  on public.certification_submissions for select
  using (public.is_admin());

create policy "cert_submissions: admin update"
  on public.certification_submissions for update
  using (public.is_admin())
  with check (public.is_admin());

create policy "disputes: reporter select own"
  on public.disputes for select
  using (reported_by_user_id = auth.uid());

create policy "disputes: job parties select"
  on public.disputes for select
  using (
    exists (
      select 1 from public.jobs j
      left join public.hires h on h.job_id = j.id
      where j.id = disputes.job_id
        and (j.family_id = auth.uid() or h.sitter_id = auth.uid())
    )
  );

create policy "disputes: admin select"
  on public.disputes for select
  using (public.is_admin());

create policy "disputes: reporter insert"
  on public.disputes for insert
  with check (reported_by_user_id = auth.uid());

create policy "disputes: admin update"
  on public.disputes for update
  using (public.is_admin())
  with check (public.is_admin());

create policy "uploaded_docs: uploader select"
  on public.uploaded_documents for select
  using (user_id = auth.uid());

create policy "uploaded_docs: uploader insert"
  on public.uploaded_documents for insert
  with check (user_id = auth.uid());

create policy "uploaded_docs: admin select"
  on public.uploaded_documents for select
  using (public.is_admin());

create policy "job_timeline: participants select"
  on public.job_timeline_events for select
  using (
    exists (
      select 1 from public.jobs j
      left join public.hires h on h.job_id = j.id
      where j.id = job_timeline_events.job_id
        and (j.family_id = auth.uid() or h.sitter_id = auth.uid())
    )
  );

create policy "job_timeline: admin select"
  on public.job_timeline_events for select
  using (public.is_admin());
