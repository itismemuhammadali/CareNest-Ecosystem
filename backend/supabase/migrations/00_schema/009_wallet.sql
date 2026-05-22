-- Star Sitters — wallet, ledger, withdrawals + auto-wallet trigger (BACKEND.md §5 Migration 9)
create table public.wallets (
  sitter_id          uuid        primary key
                                 references public.sitter_profiles(user_id)
                                 on delete cascade,
  available_balance  numeric(12,2) not null default 0
                                   check (available_balance >= 0),
  pending_balance    numeric(12,2) not null default 0
                                   check (pending_balance >= 0),
  lifetime_earnings  numeric(12,2) not null default 0
                                   check (lifetime_earnings >= 0),
  updated_at         timestamptz  not null default now()
);

create trigger trg_wallets_updated_at
  before update on public.wallets
  for each row execute function public.touch_updated_at();

create table public.ledger_entries (
  id               uuid        primary key default gen_random_uuid(),
  sitter_id        uuid        not null
                               references public.wallets(sitter_id) on delete cascade,
  type             public.ledger_type not null,
  amount           numeric(12,2) not null,
  reference_type   text,
  reference_id     uuid,
  balance_after    numeric(12,2) not null,
  created_at       timestamptz not null default now()
);

create index idx_ledger_sitter_id_created
  on public.ledger_entries(sitter_id, created_at desc);

create table public.withdrawal_requests (
  id            uuid        primary key default gen_random_uuid(),
  sitter_id     uuid        not null
                            references public.wallets(sitter_id) on delete cascade,
  amount        numeric(12,2) not null check (amount > 0),
  method        text        not null,
  account_info  jsonb       default '{}',
  status        text        not null default 'pending',
  requested_at  timestamptz not null default now(),
  paid_at       timestamptz,
  paid_by       uuid        references public.users(id)
);

create index idx_withdrawal_sitter_id on public.withdrawal_requests(sitter_id);
create index idx_withdrawal_status on public.withdrawal_requests(status);

-- Auto-create wallet row when sitter_profile is inserted (moved from Migration 5)
create or replace function public.fn_create_wallet_for_sitter()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  insert into public.wallets (sitter_id, available_balance, pending_balance,
                              lifetime_earnings, updated_at)
  values (new.user_id, 0, 0, 0, now())
  on conflict (sitter_id) do nothing;
  return new;
end;
$$;

create trigger trg_create_wallet_for_sitter
  after insert on public.sitter_profiles
  for each row execute function public.fn_create_wallet_for_sitter();
