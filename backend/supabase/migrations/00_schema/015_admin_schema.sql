-- Star Sitters — §31.6 admin schema additions (BACKEND.md §31.6)
-- Note: family_profiles.home_address already exists as jsonb (Migration 4); do not add a text column.

alter table public.family_profiles
  add column if not exists rejection_reason text;

create table if not exists public.uploaded_documents (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.users(id) on delete cascade,
  doc_kind      text not null
    check (doc_kind in ('bg_check','cert','consent_form','other')),
  document_name text not null,
  storage_path  text not null,
  uploaded_at   timestamptz not null default now()
);
create index if not exists idx_uploaded_documents_user
  on public.uploaded_documents(user_id, uploaded_at desc);

alter table public.sitter_profiles
  add column if not exists suspension_reason text,
  add column if not exists suspended_until   timestamptz;

create table if not exists public.courses (
  id                    uuid primary key default gen_random_uuid(),
  name                  text not null,
  category              text not null default 'General',
  status                text not null default 'draft'
    check (status in ('published','draft','archived')),
  description           text,
  modules               text[] not null default '{}',
  instructor            text,
  duration_hours        numeric(4,1),
  level                 text check (level in ('Beginner','Intermediate','Advanced')),
  price                 numeric(8,2) not null default 0,
  requirements          text,
  learning_objectives   text,
  provides_certificate  boolean not null default true,
  created_by            uuid references public.users(id),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

drop trigger if exists trg_courses_updated_at on public.courses;
create trigger trg_courses_updated_at
  before update on public.courses
  for each row execute function public.touch_updated_at();

create table if not exists public.certification_submissions (
  id                    uuid primary key default gen_random_uuid(),
  sitter_id             uuid not null
                        references public.sitter_profiles(user_id) on delete cascade,
  course_id             uuid not null references public.courses(id) on delete cascade,
  score                 numeric(5,2),
  questions_answered  int,
  correct_answers       int,
  time_taken_seconds    int,
  status                public.verification_status not null default 'pending',
  rejection_reason      text,
  submitted_at          timestamptz not null default now(),
  reviewed_at           timestamptz,
  reviewed_by           uuid references public.users(id),
  unique (sitter_id, course_id)
);
create index if not exists idx_cert_submissions_status
  on public.certification_submissions(status, submitted_at desc);

create table if not exists public.disputes (
  id                  uuid primary key default gen_random_uuid(),
  job_id              uuid not null references public.jobs(id) on delete cascade,
  reported_by_user_id uuid not null references public.users(id),
  reported_by_role    public.user_role not null
    check (reported_by_role in ('family','sitter')),
  issue_type          text not null
    check (issue_type in ('time_discrepancy','payment_issue','no_show','safety_concern','other')),
  description         text,
  priority            text not null default 'medium'
    check (priority in ('low','medium','high')),
  status              text not null default 'open'
    check (status in ('open','investigating','resolved')),
  resolution_notes    text,
  resolved_by         uuid references public.users(id),
  resolved_at         timestamptz,
  created_at          timestamptz not null default now()
);
create index if not exists idx_disputes_status on public.disputes(status, created_at desc);
create index if not exists idx_disputes_job    on public.disputes(job_id);

create table if not exists public.job_timeline_events (
  id          uuid primary key default gen_random_uuid(),
  job_id      uuid not null references public.jobs(id) on delete cascade,
  event_type  text not null
    check (event_type in (
      'posted','hired','clock_in','clock_out',
      'completed','cancelled','disputed','resolved'
    )),
  title       text,
  actor_id    uuid references public.users(id),
  created_at  timestamptz not null default now()
);
create index if not exists idx_timeline_job on public.job_timeline_events(job_id, created_at asc);

alter table public.notifications
  add column if not exists delivery_status text not null default 'sent'
    check (delivery_status in ('sent','delivered','failed')),
  add column if not exists trigger_type    text,
  add column if not exists fcm_message_id  text;

insert into public.system_config (key, value) values
  ('system_notifications_enabled', 'true'::jsonb),
  ('auto_verification_enabled',    'false'::jsonb),
  ('gps_tracking_mode',            '"required"'::jsonb),
  ('time_rounding_rule',           '"exact"'::jsonb),
  ('overtime_rule',                '"disabled"'::jsonb),
  ('session_timeout_minutes',      '30'::jsonb),
  ('max_login_attempts',           '5'::jsonb),
  ('data_retention_months',        '24'::jsonb)
on conflict (key) do nothing;

-- Lock new admin-controlled columns at the same layer as §5 Migration 13.
create or replace function public.fn_family_lock_admin_fields()
returns trigger language plpgsql as $$
begin
  if not public.tx_immutability_bypass() and not public.admin_only_bool() then
    if old.bg_check_status is distinct from new.bg_check_status then
      raise exception 'bg_check_status is admin-only' using errcode = '42501';
    end if;
    if old.rejection_reason is distinct from new.rejection_reason then
      raise exception 'rejection_reason is admin-only' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.fn_sitter_lock_admin_fields()
returns trigger language plpgsql as $$
begin
  if not public.tx_immutability_bypass() and not public.admin_only_bool() then
    if old.is_active is distinct from new.is_active then
      raise exception 'is_active is admin-only' using errcode = '42501';
    end if;
    if old.guardian_consent_status is distinct from new.guardian_consent_status then
      raise exception 'guardian_consent_status is admin-only' using errcode = '42501';
    end if;
    if old.total_minutes_worked is distinct from new.total_minutes_worked then
      raise exception 'total_minutes_worked is server-maintained' using errcode = '42501';
    end if;
    if old.total_earnings is distinct from new.total_earnings then
      raise exception 'total_earnings is server-maintained' using errcode = '42501';
    end if;
    if old.suspension_reason is distinct from new.suspension_reason then
      raise exception 'suspension_reason is admin-only' using errcode = '42501';
    end if;
    if old.suspended_until is distinct from new.suspended_until then
      raise exception 'suspended_until is admin-only' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;
