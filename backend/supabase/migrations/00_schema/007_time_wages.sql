-- Star Sitters — wage tiers, time entries, system_config (BACKEND.md §5 Migration 7)
create table public.age_wage_tiers (
  id              serial      primary key,
  min_age         int         not null check (min_age >= 0),
  max_age         int         not null check (max_age <= 100),
  hourly_rate     numeric(10,2) not null check (hourly_rate > 0),
  effective_from  date        not null default current_date,
  created_by      uuid        references public.users(id),
  constraint chk_age_range check (max_age >= min_age),
  unique (min_age, max_age, effective_from)
);

create table public.time_entries (
  id                uuid        primary key default gen_random_uuid(),
  hire_id           uuid        not null references public.hires(id)
                                on delete cascade,
  sitter_id         uuid        not null
                                references public.sitter_profiles(user_id),
  clock_in_at       timestamptz not null,
  clock_out_at      timestamptz,
  clock_in_lat      double precision,
  clock_in_lng      double precision,
  clock_out_lat     double precision,
  clock_out_lng     double precision,
  geofence_passed   boolean,
  computed_minutes  int,
  computed_wage     numeric(12,2),
  created_at        timestamptz not null default now()
);

create index idx_time_entries_hire_id on public.time_entries(hire_id);
create index idx_time_entries_sitter_id on public.time_entries(sitter_id);

create unique index uq_one_open_time_entry
  on public.time_entries(sitter_id)
  where clock_out_at is null;

create table public.system_config (
  key        text        primary key,
  value      jsonb       not null,
  updated_at timestamptz not null default now(),
  updated_by uuid        references public.users(id)
);
