-- Helpers read by Edge Functions (service role) for typed system_config access
grant execute on function public.cfg_text(text, text) to service_role;
grant execute on function public.cfg_bool(text, boolean) to service_role;
grant execute on function public.cfg_int(text, integer) to service_role;
-- Optional: allow authenticated clients to read typed config via RPC (Flutter)
grant execute on function public.cfg_bool(text, boolean) to authenticated;
grant execute on function public.cfg_text(text, text) to authenticated;
grant execute on function public.cfg_int(text, integer) to authenticated;
