-- C7: Enforce geofence hard-block in production.
-- clock_in() already reads geofence_hard_block via cfg_bool(), defaulting to false.
-- Set it to true so sitters cannot clock in from outside the job geofence.
insert into public.system_config (key, value)
values ('geofence_hard_block', 'true'::jsonb)
on conflict (key) do update set value = 'true'::jsonb;
