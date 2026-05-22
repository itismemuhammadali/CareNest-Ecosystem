-- Star Sitters — jobs, applications, hires (BACKEND.md §5 Migration 6)
create table public.jobs (
  id                 uuid        primary key default gen_random_uuid(),
  family_id          uuid        not null
                                 references public.family_profiles(user_id)
                                 on delete cascade,
  title              text        not null check (char_length(title) between 5 and 200),
  description        text,
  date               date        not null,
  start_time         timestamptz not null,
  end_time           timestamptz not null,
  number_of_children int         not null check (number_of_children between 1 and 10),
  child_ids          uuid[]      not null default '{}',
  location_lat       double precision not null,
  location_lng       double precision not null,
  location_address   jsonb       not null default '{}',
  geofence_radius_m  int         not null default 150
                                 check (geofence_radius_m between 50 and 500),
  status             public.job_status not null default 'open',
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  constraint chk_job_times check (end_time > start_time)
);

create trigger trg_jobs_updated_at
  before update on public.jobs
  for each row execute function public.touch_updated_at();

create index idx_jobs_status_start on public.jobs(status, start_time);

create index idx_jobs_location on public.jobs
  using gist(ll_to_earth(location_lat, location_lng));

create table public.applications (
  id              uuid        primary key default gen_random_uuid(),
  job_id          uuid        not null references public.jobs(id) on delete cascade,
  sitter_id       uuid        not null
                              references public.sitter_profiles(user_id)
                              on delete cascade,
  cover_message   text,
  status          public.application_status not null default 'pending',
  applied_at      timestamptz not null default now(),
  unique (job_id, sitter_id)
);

create index idx_applications_job_id on public.applications(job_id);
create index idx_applications_sitter_id on public.applications(sitter_id);

create table public.hires (
  id           uuid        primary key default gen_random_uuid(),
  job_id       uuid        unique not null
                           references public.jobs(id) on delete cascade,
  sitter_id    uuid        not null
                           references public.sitter_profiles(user_id),
  hourly_rate  numeric(10,2) not null,
  hired_at     timestamptz not null default now()
);

create index idx_hires_sitter_id on public.hires(sitter_id);
