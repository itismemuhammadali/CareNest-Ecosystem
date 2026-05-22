-- C3: Move hardcoded webhook secret out of trigger functions into system_config.
-- The old secret (48e9967…) is now in git history and must be rotated externally.
-- After applying this migration:
--   1. Generate a new secret: openssl rand -hex 32
--   2. Update system_config: UPDATE public.system_config SET value = '"<new-secret>"' WHERE key = 'webhook_secret';
--   3. Update WEBHOOK_SECRET in your Edge Functions env (Supabase Dashboard → Edge Functions → Secrets).

-- Seed the row with a placeholder — operator MUST overwrite before going live.
INSERT INTO public.system_config (key, value)
VALUES ('webhook_secret', '"ROTATE_ME"')
ON CONFLICT (key) DO NOTHING;

-- Rewrite webhook 1: notifications → send_push
CREATE OR REPLACE FUNCTION public.notify_send_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _url     text;
  _secret  text;
  _payload jsonb;
BEGIN
  _url    := current_setting('app.settings.supabase_url', true) || '/functions/v1/send_push';
  _secret := public.cfg_text('webhook_secret', '');

  IF _secret = '' OR _secret = 'ROTATE_ME' THEN
    RAISE EXCEPTION 'webhook_secret not configured in system_config';
  END IF;

  _payload := jsonb_build_object(
    'type',       TG_OP,
    'table',      TG_TABLE_NAME,
    'schema',     TG_TABLE_SCHEMA,
    'record',     row_to_json(NEW)::jsonb,
    'old_record', NULL
  );

  PERFORM net.http_post(
    url     := _url,
    headers := jsonb_build_object(
      'Content-Type',     'application/json',
      'x-webhook-secret', _secret
    ),
    body    := _payload
  );
  RETURN NEW;
END;
$$;

-- Rewrite webhook 2: guardian_consents → send_guardian_consent_email
CREATE OR REPLACE FUNCTION public.notify_guardian_consent_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _url     text;
  _secret  text;
  _payload jsonb;
BEGIN
  _url    := current_setting('app.settings.supabase_url', true) || '/functions/v1/send_guardian_consent_email';
  _secret := public.cfg_text('webhook_secret', '');

  IF _secret = '' OR _secret = 'ROTATE_ME' THEN
    RAISE EXCEPTION 'webhook_secret not configured in system_config';
  END IF;

  _payload := jsonb_build_object(
    'type',       TG_OP,
    'table',      TG_TABLE_NAME,
    'schema',     TG_TABLE_SCHEMA,
    'record',     row_to_json(NEW)::jsonb,
    'old_record', NULL
  );

  PERFORM net.http_post(
    url     := _url,
    headers := jsonb_build_object(
      'Content-Type',     'application/json',
      'x-webhook-secret', _secret
    ),
    body    := _payload
  );
  RETURN NEW;
END;
$$;
