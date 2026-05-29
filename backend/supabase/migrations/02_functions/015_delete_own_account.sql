-- Allows a signed-in user to permanently delete their own account.
-- Deletes the row from auth.users, which cascades to public.users and all
-- child tables (family_profiles, children, jobs, applications, etc.) via
-- ON DELETE CASCADE foreign keys defined in the schema.
-- Also removes the user's avatar from storage so the path is free if they
-- re-register with the same email.
--
-- SECURITY DEFINER + explicit auth.uid() check ensures a user can only
-- ever delete themselves — never another user's account.

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  -- Remove avatar files from storage (best-effort — don't fail if missing)
  begin
    delete from storage.objects
     where bucket_id = 'avatars'
       and (storage.foldername(name))[1] = v_uid::text;
  exception when others then
    -- ignore storage errors
  end;

  -- Remove bg-check docs from storage (best-effort)
  begin
    delete from storage.objects
     where bucket_id = 'bg-check-docs'
       and (storage.foldername(name))[1] = v_uid::text;
  exception when others then
    -- ignore storage errors
  end;

  -- Delete from auth.users. The ON DELETE CASCADE on public.users.id
  -- (and all downstream tables) handles cleanup of every related row.
  delete from auth.users where id = v_uid;
end;
$$;

-- Grant to authenticated users only
grant execute on function public.delete_own_account() to authenticated;
