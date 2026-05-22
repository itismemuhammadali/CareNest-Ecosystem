-- BACKEND.md §31 Days 8–10: notification delivery_status, registration trend RPC,
-- certification_submissions approve/reject, admin read notifications.

alter table public.notifications
  add column if not exists delivery_status text not null default 'pending';

drop policy if exists "notifications: admin read all" on public.notifications;
create policy "notifications: admin read all"
  on public.notifications for select
  using (public.is_admin());

create or replace function public.admin_registration_trend()
returns table(d date, role text, cnt bigint)
language sql
stable
security definer
set search_path = public as $$
  select date_trunc('day', u.created_at)::date as d,
         u.role::text as role,
         count(*)::bigint as cnt
    from public.users u
   group by 1, 2
   order by 1 desc, 2;
$$;

revoke all on function public.admin_registration_trend() from public;
grant execute on function public.admin_registration_trend() to authenticated;

create or replace function public.admin_approve_certification_submission(
  p_submission_id uuid,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public as $$
declare
  v_admin uuid := auth.uid();
  v_sitter uuid;
begin
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  update public.certification_submissions cs
     set status = 'approved'::public.verification_status,
         reviewed_at = now(),
         reviewed_by = v_admin,
         rejection_reason = null
   where cs.id = p_submission_id
     and cs.status = 'pending';

  if not found then
    raise exception 'pending certification_submission not found';
  end if;

  select cs.sitter_id into v_sitter
    from public.certification_submissions cs
   where cs.id = p_submission_id;

  perform public.write_audit_log(
    'admin_approve_certification_submission',
    'certification_submissions',
    p_submission_id,
    null,
    jsonb_build_object('notes', p_notes, 'sitter_id', v_sitter)
  );

  insert into public.notifications (user_id, type, title, body)
  values (
    v_sitter, 'cert_result', 'Course certification approved',
    coalesce(nullif(trim(p_notes), ''), 'Your course submission was approved.')
  );
end;
$$;

create or replace function public.admin_reject_certification_submission(
  p_submission_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = public as $$
declare
  v_admin uuid := auth.uid();
  v_sitter uuid;
begin
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  if p_reason is null or length(trim(p_reason)) < 5 then
    raise exception 'rejection reason must be at least 5 characters';
  end if;

  update public.certification_submissions cs
     set status = 'rejected'::public.verification_status,
         reviewed_at = now(),
         reviewed_by = v_admin,
         rejection_reason = p_reason
   where cs.id = p_submission_id
     and cs.status = 'pending';

  if not found then
    raise exception 'pending certification_submission not found';
  end if;

  select cs.sitter_id into v_sitter
    from public.certification_submissions cs
   where cs.id = p_submission_id;

  perform public.write_audit_log(
    'admin_reject_certification_submission',
    'certification_submissions',
    p_submission_id,
    null,
    jsonb_build_object('reason', p_reason, 'sitter_id', v_sitter)
  );

  insert into public.notifications (user_id, type, title, body)
  values (
    v_sitter, 'cert_result', 'Course certification update',
    'Reason: ' || p_reason
  );
end;
$$;

revoke all on function public.admin_approve_certification_submission(uuid, text) from public;
revoke all on function public.admin_reject_certification_submission(uuid, text) from public;
grant execute on function public.admin_approve_certification_submission(uuid, text) to authenticated;
grant execute on function public.admin_reject_certification_submission(uuid, text) to authenticated;
