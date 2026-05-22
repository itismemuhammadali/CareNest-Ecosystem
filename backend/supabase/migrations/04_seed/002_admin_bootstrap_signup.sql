-- Admin self-registration via bootstrap code.
-- Allows a new user to grant themselves admin access by providing the
-- correct bootstrap code stored in system_config.
-- After the first admin registers, change the bootstrap code or disable this
-- by setting admin_bootstrap_code to '' in system_config.

INSERT INTO public.system_config (key, value)
VALUES ('admin_bootstrap_code', '"STARSITTERS_ADMIN_2026"')
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.admin_register_self(p_bootstrap_code text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_expected text;
BEGIN
  v_expected := public.cfg_text('admin_bootstrap_code', '');

  IF v_expected = '' THEN
    RAISE EXCEPTION 'Admin self-registration is disabled' USING ERRCODE = 'P0001';
  END IF;

  IF p_bootstrap_code IS NULL OR p_bootstrap_code <> v_expected THEN
    RAISE EXCEPTION 'Invalid bootstrap code' USING ERRCODE = 'P0001';
  END IF;

  -- Ensure the calling user exists in public.users
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid()) THEN
    RAISE EXCEPTION 'User profile not found — sign up first' USING ERRCODE = 'P0001';
  END IF;

  -- Grant admin role (bypass immutability guard on role column)
  PERFORM set_config('app.bypass_immutability', 'true', true);
  UPDATE public.users SET role = 'admin' WHERE id = auth.uid();

  -- Insert into admin_users (idempotent)
  INSERT INTO public.admin_users (id) VALUES (auth.uid())
  ON CONFLICT (id) DO NOTHING;

  -- Audit
  INSERT INTO public.audit_logs (actor_id, action, entity_type, entity_id)
  VALUES (auth.uid(), 'admin_register_self', 'admin_users', auth.uid());
END;
$$;

REVOKE ALL ON FUNCTION public.admin_register_self(text) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_register_self(text) TO authenticated;
