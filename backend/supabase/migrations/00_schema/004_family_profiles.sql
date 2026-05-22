-- Star Sitters — family + children + background_checks (BACKEND.md §5 Migration 4)
create table public.family_profiles (
  user_id              uuid        primary key
                                   references public.users(id) on delete cascade,
  home_address         jsonb       not null default '{}',
  home_lat             double precision,
  home_lng             double precision,
  home_safety_info     text,
  emergency_contact    jsonb       default '{}',
  babysitter_prefs     jsonb       default '{}',
  bg_check_status      public.verification_status not null default 'not_submitted',
  updated_at           timestamptz not null default now()
);

create trigger trg_family_profiles_updated_at
  before update on public.family_profiles
  for each row execute function public.touch_updated_at();

create table public.children (
  id          uuid        primary key default gen_random_uuid(),
  family_id   uuid        not null references public.family_profiles(user_id)
                          on delete cascade,
  name        text        not null check (char_length(name) between 1 and 100),
  age         int         not null check (age >= 0 and age <= 18),
  notes       text,
  created_at  timestamptz not null default now()
);

create index idx_children_family_id on public.children(family_id);

create table public.background_checks (
  id           uuid        primary key default gen_random_uuid(),
  family_id    uuid        unique not null
                           references public.family_profiles(user_id)
                           on delete cascade,
  documents    jsonb       not null default '[]',
  status       public.verification_status not null default 'pending',
  reviewed_by  uuid        references public.users(id),
  reviewed_at  timestamptz,
  admin_notes  text,
  submitted_at timestamptz not null default now()
);
