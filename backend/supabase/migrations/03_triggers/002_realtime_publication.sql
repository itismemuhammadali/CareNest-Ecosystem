-- Star Sitters — Supabase Realtime (postgres_changes) for live chat + related feeds
-- BACKEND.md §13 — clients subscribe via Supabase Realtime (WebSocket).
-- Tables must be part of publication `supabase_realtime`.

alter table public.messages replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.messages;
exception
  when duplicate_object then null;
end;
$$;

do $$
begin
  alter publication supabase_realtime add table public.conversations;
exception
  when duplicate_object then null;
end;
$$;
