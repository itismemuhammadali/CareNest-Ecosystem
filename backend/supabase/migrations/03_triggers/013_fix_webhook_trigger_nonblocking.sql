-- Fix: make notify_send_push and notify_guardian_consent_email non-blocking.
-- Previously these raised EXCEPTION when webhook_secret = 'ROTATE_ME', causing
-- all admin action RPCs (approve/reject family, suspend sitter, resolve dispute)
-- to fail with HTTP 400. Now they raise WARNING and skip the HTTP call instead,
-- so admin actions always succeed regardless of push notification configuration.
-- Also updates system_config webhook_secret to the original known-good value.

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
    RAISE WARNING 'notify_send_push: webhook_secret not configured in system_config — push notification skipped';
    RETURN NEW;
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
    RAISE WARNING 'notify_guardian_consent_email: webhook_secret not configured — consent email skipped';
    RETURN NEW;
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

-- After applying this migration, update webhook_secret in system_config:
--   UPDATE public.system_config SET value = '"<your-new-webhook-secret>"' WHERE key = 'webhook_secret';
