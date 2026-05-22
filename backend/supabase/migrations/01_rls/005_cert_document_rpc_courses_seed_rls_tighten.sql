-- BACKEND.md §5/§7/§18 — document certifications + demo courses + insert hardening.

create or replace function public.register_certification_document(
  p_cert_type       text,
  p_document_path   text
)
returns public.certifications
language plpgsql
security definer
set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_row public.certifications;
  v_type text := trim(coalesce(p_cert_type, ''));
  v_path text := trim(coalesce(p_document_path, ''));
begin
  if public.current_user_role() is distinct from 'sitter' then
    raise exception 'only sitter accounts may register certification documents';
  end if;

  if length(v_type) < 2 then
    raise exception 'cert_type is required';
  end if;

  if length(v_path) < 8 then
    raise exception 'document_path is required';
  end if;

  if v_path not like (v_uid::text || '/%') then
    raise exception '%', format('document_path must start with %s/', v_uid::text);
  end if;

  insert into public.certifications (
    sitter_id,
    cert_type,
    document_path,
    status
  )
  values (
    v_uid,
    v_type,
    v_path,
    'pending'::public.verification_status
  )
  returning * into v_row;

  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_uid,
    'certification_document_registered',
    'certifications',
    v_row.id,
    to_jsonb(v_row)
  );

  return v_row;
end;
$$;

revoke all on function public.register_certification_document(text, text) from public;
grant execute on function public.register_certification_document(text, text) to authenticated;

drop policy if exists "certifications: sitter insert own" on public.certifications;

create policy "certifications: sitter insert own"
  on public.certifications for insert
  with check (
    sitter_id = auth.uid()
    and status = 'pending'::public.verification_status
    and length(trim(cert_type)) >= 2
    and (
      document_path is null
      or (
        length(trim(document_path)) >= 8
        and document_path like (auth.uid()::text || '/%')
      )
    )
  );

insert into public.courses (
  id,
  name,
  category,
  status,
  description,
  modules,
  instructor,
  duration_hours,
  level,
  price,
  provides_certificate
) values
  (
    'a0000001-0001-4001-8001-000000000001'::uuid,
    'CPR & First Aid Essentials',
    'Safety',
    'published',
    'Core CPR and first-aid awareness for teen sitters (demo course).',
    array['Basics', 'Scenarios', 'Quiz']::text[],
    'Star Sitters Training',
    2.0,
    'Beginner',
    0,
    true
  ),
  (
    'a0000001-0001-4001-8001-000000000002'::uuid,
    'Professional Communication with Families',
    'Professional',
    'published',
    'Messaging, boundaries, and check-in habits (demo course).',
    array['Tone', 'Safety', 'Quiz']::text[],
    'Star Sitters Training',
    1.5,
    'Beginner',
    0,
    true
  ),
  (
    'a0000001-0001-4001-8001-000000000003'::uuid,
    'Child Engagement & Activities',
    'Care',
    'published',
    'Age-appropriate play and routines (demo course).',
    array['Planning', 'Activities', 'Quiz']::text[],
    'Star Sitters Training',
    2.5,
    'Intermediate',
    0,
    true
  )
on conflict (id) do update set
  name        = excluded.name,
  category    = excluded.category,
  status      = excluded.status,
  description = excluded.description,
  modules     = excluded.modules,
  instructor  = excluded.instructor,
  duration_hours = excluded.duration_hours,
  level       = excluded.level,
  price       = excluded.price,
  provides_certificate = excluded.provides_certificate,
  updated_at  = now();
