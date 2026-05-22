-- S11 / B6: Prevent clock_out_at <= clock_in_at at the DB level.
-- The clock_out() RPC uses now() which is server-generated, so this can't happen
-- under normal operation. This constraint is a safety net in case the RPC is ever
-- called with a backdated timestamp or patched in future.

alter table public.time_entries
  add constraint chk_clock_out_after_clock_in
  check (clock_out_at is null or clock_out_at > clock_in_at);
