-- F5: Single-query mark-all-read to replace N sequential round-trips.

create or replace function public.mark_all_notifications_read()
returns void
language sql security definer
set search_path = public
as $$
  update public.notifications
     set read_at = now()
   where user_id = auth.uid()
     and read_at is null;
$$;

grant execute on function public.mark_all_notifications_read() to authenticated;
