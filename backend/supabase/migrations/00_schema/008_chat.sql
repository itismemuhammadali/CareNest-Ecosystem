-- Star Sitters — chat (BACKEND.md §5 Migration 8)
create table public.conversations (
  id          uuid        primary key default gen_random_uuid(),
  job_id      uuid        not null references public.jobs(id) on delete cascade,
  family_id   uuid        not null references public.family_profiles(user_id),
  sitter_id   uuid        not null references public.sitter_profiles(user_id),
  created_at  timestamptz not null default now(),
  unique (job_id, sitter_id)
);

create index idx_conversations_family_id on public.conversations(family_id);
create index idx_conversations_sitter_id on public.conversations(sitter_id);

create table public.messages (
  id               uuid        primary key default gen_random_uuid(),
  conversation_id  uuid        not null
                               references public.conversations(id) on delete cascade,
  sender_id        uuid        not null references public.users(id),
  body             text        not null check (char_length(body) between 1 and 4000),
  read_at          timestamptz,
  created_at       timestamptz not null default now()
);

create index idx_messages_conv_created
  on public.messages(conversation_id, created_at desc);
