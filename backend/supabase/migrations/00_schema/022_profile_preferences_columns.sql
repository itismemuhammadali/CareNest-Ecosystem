-- S15: Sitter settings preferences sync across devices.
-- F4: Family privacy settings sync across devices.
alter table public.sitter_profiles
  add column if not exists preferences jsonb not null default '{}'::jsonb;

alter table public.family_profiles
  add column if not exists privacy_settings jsonb not null default '{}'::jsonb;

comment on column public.sitter_profiles.preferences is
  'User preferences (push_notifications, dark_mode) synced across devices';

comment on column public.family_profiles.privacy_settings is
  'Privacy settings (profile_visible, show_location, etc.) synced across devices';
