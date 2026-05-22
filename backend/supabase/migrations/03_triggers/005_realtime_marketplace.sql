-- Realtime feeds for local demo (BACKEND.md §13 — postgres_changes streams from Flutter)

alter table public.jobs replica identity full;
alter table public.applications replica identity full;
alter table public.notifications replica identity full;
alter table public.ledger_entries replica identity full;
alter table public.wallets replica identity full;
alter table public.hires replica identity full;
alter table public.time_entries replica identity full;

do $$ begin
  alter publication supabase_realtime add table public.jobs;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.applications;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.ledger_entries;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.wallets;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.hires;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.time_entries;
exception when duplicate_object then null; end $$;
