-- Allows a newly OAuth-authenticated user to claim sitter role.
-- Only works if they currently have role='family' AND have not posted any jobs
-- (meaning they just signed up via OAuth, not an existing family user).
CREATE OR REPLACE FUNCTION public.claim_sitter_role()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_uid uuid; v_current_role public.user_role;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

  SELECT role INTO v_current_role FROM public.users WHERE id = v_uid;

  IF v_current_role = 'sitter' THEN RETURN; END IF;

  IF v_current_role != 'family' THEN
    RAISE EXCEPTION 'Cannot claim sitter role from current role: %', v_current_role;
  END IF;

  -- Guard: do not convert real family users who have posted jobs
  IF EXISTS (SELECT 1 FROM public.jobs WHERE family_id = v_uid LIMIT 1) THEN
    RAISE EXCEPTION 'Existing family account cannot be converted to sitter';
  END IF;

  -- Convert role
  UPDATE public.users SET role = 'sitter' WHERE id = v_uid;

  -- Remove orphaned family_profiles row
  DELETE FROM public.family_profiles WHERE user_id = v_uid;

  -- Create sitter_profile with default DOB (14 years ago)
  INSERT INTO public.sitter_profiles (user_id, date_of_birth)
  VALUES (v_uid, (current_date - interval '14 years')::date)
  ON CONFLICT (user_id) DO NOTHING;
END; $$;

REVOKE ALL ON FUNCTION public.claim_sitter_role() FROM public;
GRANT EXECUTE ON FUNCTION public.claim_sitter_role() TO authenticated;
