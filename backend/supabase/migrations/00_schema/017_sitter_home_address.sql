-- Add home_address JSONB column to sitter_profiles for storing address during registration.
ALTER TABLE public.sitter_profiles
  ADD COLUMN IF NOT EXISTS home_address jsonb NOT NULL DEFAULT '{}';
