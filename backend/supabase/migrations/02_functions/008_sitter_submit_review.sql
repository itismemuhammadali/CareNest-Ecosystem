-- Add profile_status to sitter_profiles and RPC to submit for review

alter table public.sitter_profiles
  add column if not exists profile_status text not null default 'draft'
    check (profile_status in ('draft','under_review','approved','rejected'));

create or replace function public.sitter_submit_for_review()
returns void
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
begin
  update public.sitter_profiles
  set profile_status = 'under_review'
  where user_id = auth.uid();

  insert into public.notifications(user_id, type, title, body)
  values (
    (select id from public.users where role = 'admin' limit 1),
    'sitter_review_request',
    'New sitter submitted for review',
    'Sitter ' || auth.uid()::text || ' has submitted their profile for review.'
  );
end;
$$;

grant execute on function public.sitter_submit_for_review() to authenticated;
