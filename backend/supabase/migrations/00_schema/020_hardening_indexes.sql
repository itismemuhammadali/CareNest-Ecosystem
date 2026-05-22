-- B1: Add missing index on messages.sender_id for fast "find my sent messages" queries.
create index if not exists idx_messages_sender_id
  on public.messages(sender_id);
