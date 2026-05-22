-- Add material_paths column to courses table for Supabase Storage references
alter table public.courses
  add column if not exists material_paths jsonb not null default '[]'::jsonb;

-- Create course-materials storage bucket (admin write, authenticated read)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'course-materials',
  'course-materials',
  false,
  524288000,
  array[
    'application/pdf',
    'video/mp4','video/quicktime','video/webm','video/x-msvideo',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain','text/markdown'
  ]
)
on conflict (id) do update set
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Admins can upload course materials"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'course-materials'
    and (select role from public.users where id = auth.uid()) = 'admin'
  );

create policy "Admins can delete course materials"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'course-materials'
    and (select role from public.users where id = auth.uid()) = 'admin'
  );

create policy "Authenticated can read course materials"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'course-materials');
