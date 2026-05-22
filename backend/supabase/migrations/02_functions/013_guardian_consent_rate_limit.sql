-- B2: Rate limit anonymous calls to confirm_guardian_consent().
-- Tracks failed attempts per token. Blocks after 10 failed attempts in 1 hour.
create table if not exists public.consent_attempt_log (
  id         bigint generated always as identity primary key,
  token_hash text    not null,
  attempted_at timestamptz not null default now()
);

create index if not exists idx_consent_attempt_log_token_hash
  on public.consent_attempt_log(token_hash, attempted_at);

-- Remove entries older than 24 hours to keep the table lean (runs via trigger-cleanup approach)
drop function if exists public.confirm_guardian_consent(uuid);
create or replace function public.confirm_guardian_consent(p_token uuid)
returns jsonb
language plpgsql security definer
set search_path = public as $$
declare
  v_hash       text := md5(p_token::text);
  v_attempts   int;
  v_row        public.guardian_consents;
begin
  -- Count failed attempts in the last hour for this token hash
  select count(*) into v_attempts
    from public.consent_attempt_log
   where token_hash   = v_hash
     and attempted_at > now() - interval '1 hour';

  if v_attempts >= 10 then
    raise exception 'Too many attempts. Try again in an hour.'
      using errcode = 'P0001';
  end if;

  select * into v_row
    from public.guardian_consents
   where consent_token = p_token
     and status        = 'pending'
     and expires_at    > now();

  if not found then
    -- Log failed attempt
    insert into public.consent_attempt_log (token_hash) values (v_hash);
    raise exception 'Invalid or expired consent token.'
      using errcode = 'P0002';
  end if;

  update public.guardian_consents
     set status = 'approved', consented_at = now()
   where id = v_row.id;

  update public.sitter_profiles
     set guardian_consent_status = 'approved'
   where user_id = v_row.sitter_id;

  -- Clean up old attempt logs (keep table lean)
  delete from public.consent_attempt_log
   where attempted_at < now() - interval '24 hours';

  return jsonb_build_object('success', true, 'sitter_id', v_row.sitter_id);
end;
$$;

grant execute on function public.confirm_guardian_consent(uuid) to anon, authenticated;
