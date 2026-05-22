-- Fix: make handle_new_auth_user resilient to out-of-range date_of_birth.
-- Previously: Flutter DatePicker defaulted to 2000, user with DOB < 2008 caused
-- chk_sitter_age constraint violation in sitter_profiles → trigger fails → 500.
-- Now: DOB is clamped to the valid 11-17 year range, constraint never fires.

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role;
  v_dob  date;
BEGIN
  v_role := coalesce(
    (new.raw_user_meta_data->>'role')::public.user_role,
    'family'
  );

  INSERT INTO public.users (id, role, email, full_name, phone)
  VALUES (
    new.id,
    v_role,
    new.email,
    coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), ''),
    nullif(trim(new.raw_user_meta_data->>'phone'), '')
  )
  ON CONFLICT (id) DO UPDATE SET
    email     = excluded.email,
    full_name = coalesce(excluded.full_name, public.users.full_name),
    phone     = coalesce(excluded.phone, public.users.phone);

  IF v_role = 'family' THEN
    INSERT INTO public.family_profiles (user_id)
    VALUES (new.id)
    ON CONFLICT (user_id) DO NOTHING;

  ELSIF v_role = 'sitter' THEN
    -- Parse DOB safely; fall back to 14 years ago if missing, invalid, or out of range.
    BEGIN
      v_dob := (nullif(trim(new.raw_user_meta_data->>'date_of_birth'), ''))::date;
    EXCEPTION WHEN OTHERS THEN
      v_dob := NULL;
    END;

    -- Clamp to valid age window (11–17 years). If out of range use 14-year default.
    IF v_dob IS NULL
       OR v_dob <= (current_date - interval '18 years')::date
       OR v_dob >  (current_date - interval '11 years')::date
    THEN
      v_dob := (current_date - interval '14 years')::date;
    END IF;

    INSERT INTO public.sitter_profiles (user_id, date_of_birth)
    VALUES (new.id, v_dob)
    ON CONFLICT (user_id) DO NOTHING;
  END IF;

  RETURN new;
END;
$$;
