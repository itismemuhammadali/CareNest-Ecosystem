-- Star Sitters — admin_users + audit_logs (BACKEND.md §5 Migration 11)
create table public.admin_users (
  id           uuid      primary key references public.users(id) on delete cascade,
  permissions  text[]    not null default '{}',
  created_at   timestamptz not null default now()
);

create table public.audit_logs (
  id           uuid        primary key default gen_random_uuid(),
  actor_id     uuid        references public.users(id) on delete set null,
  action       text        not null,
  entity_type  text,
  entity_id    uuid,
  before_state jsonb,
  after_state  jsonb,
  ip_address   inet,
  user_agent   text,
  created_at   timestamptz not null default now()
);

create index idx_audit_logs_actor_id on public.audit_logs(actor_id);
create index idx_audit_logs_entity on public.audit_logs(entity_type, entity_id);
create index idx_audit_logs_created on public.audit_logs(created_at desc);
