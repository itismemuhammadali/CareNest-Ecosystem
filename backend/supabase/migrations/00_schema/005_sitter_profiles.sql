-- Star Sitters — sitter profiles, guardian consents, certifications (BACKEND.md §5 Migration 5)
-- Wallet auto-create trigger is in 20260209100009_wallet.sql (requires wallets table to exist).

create table public.sitter_profiles (
  user_id               uuid        primary key
                                    references public.users(id) on delete cascade,
  date_of_birth         date        not null,
  bio                   text,
  is_active             boolean     not null default false,
  guardian_consent_status public.verification_status not null default 'not_submitted',
  total_minutes_worked  int             not null default 0,
  total_earnings        numeric(12,2)   not null default 0 check (total_earnings >= 0),
  updated_at            timestamptz not null default now(),
  constraint chk_sitter_age check (
    date_of_birth <= (current_date - interval '11 years')::date
    and date_of_birth >  (current_date - interval '18 years')::date
  )
);

create trigger trg_sitter_profiles_updated_at
  before update on public.sitter_profiles
  for each row execute function public.touch_updated_at();

create table public.guardian_consents (
  id                 uuid        primary key default gen_random_uuid(),
  sitter_id          uuid        unique not null
                                 references public.sitter_profiles(user_id)
                                 on delete cascade,
  guardian_name      text        not null,
  guardian_email     text        not null,
  guardian_phone     text,
  consent_token      uuid        not null default gen_random_uuid(),
  consent_given_at   timestamptz,
  consent_ip         inet,
  document_path      text,
  created_at         timestamptz not null default now()
);

create unique index idx_guardian_consents_token
  on public.guardian_consents(consent_token);

create table public.certifications (
  id            uuid        primary key default gen_random_uuid(),
  sitter_id     uuid        not null
                            references public.sitter_profiles(user_id)
                            on delete cascade,
  cert_type     text        not null,
  document_path text,
  status        public.verification_status not null default 'not_submitted',
  reviewed_by   uuid        references public.users(id),
  reviewed_at   timestamptz,
  admin_notes   text,
  expires_at    date,
  submitted_at  timestamptz not null default now()
);

create index idx_certifications_sitter_id on public.certifications(sitter_id);
create index idx_certifications_status on public.certifications(status);
