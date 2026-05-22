-- RPC to allow newly signed-up sitters (not yet email-confirmed) to create guardian consent
-- Uses service role to bypass RLS, but validates the sitter_id exists in auth.users
create or replace function public.sitter_create_guardian_consent(
  p_sitter_id uuid,
  p_guardian_name text,
  p_guardian_email text,
  p_guardian_phone text default null
)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_result jsonb;
begin
  -- Verify the sitter_id exists in auth.users (basic validation)
  if not exists (select 1 from auth.users where id = p_sitter_id) then
    return jsonb_build_object('error', 'Sitter not found');
  end if;

  -- Check if guardian consent already exists for this sitter
  if exists (select 1 from public.guardian_consents where sitter_id = p_sitter_id) then
    return jsonb_build_object('success', true, 'message', 'Guardian consent already exists');
  end if;

  -- Insert the guardian consent row (only columns that exist in the table)
  insert into public.guardian_consents (
    sitter_id,
    guardian_name,
    guardian_email,
    guardian_phone
  ) values (
    p_sitter_id,
    p_guardian_name,
    p_guardian_email,
    p_guardian_phone
  );

  return jsonb_build_object('success', true, 'message', 'Guardian consent created');
exception when others then
  return jsonb_build_object('error', SQLERRM);
end;
$$;

-- Grant execute permission to anon role so unauthenticated users can call it
grant execute on function public.sitter_create_guardian_consent(uuid, text, text, text) to anon;
