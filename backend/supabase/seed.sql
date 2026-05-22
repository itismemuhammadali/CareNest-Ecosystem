-- Demo / dev seed — aligns with BACKEND.md §5 + Appendix A
-- Run after migrations (`supabase db reset` applies this automatically).

-- Default brackets aligned with admin Wage Configuration UI (11–12, 13–14, 15–17).
insert into public.age_wage_tiers (min_age, max_age, hourly_rate, effective_from) values
  (11, 12, 10.00, '2026-01-01'),
  (13, 14, 12.00, '2026-01-01'),
  (15, 17, 15.00, '2026-01-01')
on conflict (min_age, max_age, effective_from) do nothing;

insert into public.system_config (key, value) values
  ('min_sitter_age',             '11'::jsonb),
  ('max_sitter_age',             '17'::jsonb),
  ('default_geofence_radius_m',  '150'::jsonb),
  ('geofence_hard_block',        'false'::jsonb),
  ('geofence_notify_family',     'true'::jsonb),
  ('platform_fee_pct',           '0'::jsonb),
  ('fcm_provider',               '"mock"'::jsonb),
  ('email_provider',             '"mock"'::jsonb),
  ('email_from',                 '"StarSitters <noreply@starsitters.app>"'::jsonb),
  ('payout_provider',            '"manual"'::jsonb),
  ('bg_check_provider',          '"manual"'::jsonb),
  -- v0.2+ placeholders (no external keys required for local demo)
  ('stripe_connect_status',      '"deferred"'::jsonb),
  ('geofencing_enforcement',     '"soft_radius_only"'::jsonb)
on conflict (key) do nothing;

-- Published demo courses (same UUIDs as migration 20260513100000 — safe on conflict).
insert into public.courses (id, name, category, status, description, modules, instructor, duration_hours, level, price, provides_certificate) values
  ('a0000001-0001-4001-8001-000000000001'::uuid, 'CPR & First Aid Essentials', 'Safety', 'published',
   'Core CPR and first-aid awareness for teen sitters (demo course).',
   array['Basics', 'Scenarios', 'Quiz']::text[], 'Star Sitters Training', 2.0, 'Beginner', 0, true),
  ('a0000001-0001-4001-8001-000000000002'::uuid, 'Professional Communication with Families', 'Professional', 'published',
   'Messaging, boundaries, and check-in habits (demo course).',
   array['Tone', 'Safety', 'Quiz']::text[], 'Star Sitters Training', 1.5, 'Beginner', 0, true),
  ('a0000001-0001-4001-8001-000000000003'::uuid, 'Child Engagement & Activities', 'Care', 'published',
   'Age-appropriate play and routines (demo course).',
   array['Planning', 'Activities', 'Quiz']::text[], 'Star Sitters Training', 2.5, 'Intermediate', 0, true)
on conflict (id) do update set
  status = excluded.status,
  updated_at = now();
