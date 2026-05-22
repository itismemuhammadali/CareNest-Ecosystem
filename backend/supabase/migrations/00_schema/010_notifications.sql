-- Star Sitters — devices + notifications (BACKEND.md §5 Migration 10)
create table public.devices (
  id           uuid        primary key default gen_random_uuid(),
  user_id      uuid        not null references public.users(id) on delete cascade,
  fcm_token    text        not null,
  platform     text        not null default 'android',
  last_seen_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);

create index idx_devices_user_id on public.devices(user_id);

create table public.notifications (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references public.users(id) on delete cascade,
  type        text        not null,
  title       text,
  body        text,
  data        jsonb       default '{}',
  read_at     timestamptz,
  created_at  timestamptz not null default now()
);

create index idx_notifications_user_id_created
  on public.notifications(user_id, created_at desc);
