-- Star Sitters — Storage buckets + object policies (BACKEND.md §9)
-- Paths: {bucket_id}/{user_id}/...

insert into storage.buckets (id, name, public, file_size_limit)
values
  ('avatars', 'avatars', true, 5242880),
  ('bg-check-docs', 'bg-check-docs', false, 20971520),
  ('cert-docs', 'cert-docs', false, 20971520),
  ('guardian-consent-docs', 'guardian-consent-docs', false, 20971520)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit;

-- ---------- avatars (public read) ----------
create policy "storage_avatars_public_read"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "storage_avatars_authenticated_insert_own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_avatars_authenticated_update_own"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_avatars_authenticated_delete_own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------- bg-check-docs (family folder + admin read) ----------
create policy "storage_bg_check_family_select_own"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'bg-check-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_bg_check_admin_select_all"
  on storage.objects for select to authenticated
  using (bucket_id = 'bg-check-docs' and public.is_admin());

create policy "storage_bg_check_family_insert_own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'bg-check-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_bg_check_family_update_own"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'bg-check-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'bg-check-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_bg_check_family_delete_own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'bg-check-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------- cert-docs (sitter folder + admin read) ----------
create policy "storage_cert_sitter_select_own"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'cert-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_cert_admin_select_all"
  on storage.objects for select to authenticated
  using (bucket_id = 'cert-docs' and public.is_admin());

create policy "storage_cert_sitter_insert_own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'cert-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_cert_sitter_update_own"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'cert-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'cert-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_cert_sitter_delete_own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'cert-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------- guardian-consent-docs (sitter upload; admin read) ----------
create policy "storage_guardian_sitter_select_own"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'guardian-consent-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_guardian_admin_select_all"
  on storage.objects for select to authenticated
  using (bucket_id = 'guardian-consent-docs' and public.is_admin());

create policy "storage_guardian_sitter_insert_own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'guardian-consent-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_guardian_sitter_update_own"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'guardian-consent-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'guardian-consent-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_guardian_sitter_delete_own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'guardian-consent-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
