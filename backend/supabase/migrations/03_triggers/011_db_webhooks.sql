-- Star Sitters — DB Webhooks for Edge Functions
-- Sends standard Supabase DB webhook payload { type, table, schema, record, old_record }
-- to send_push on notifications INSERT
-- to send_guardian_consent_email on guardian_consents INSERT

-- Webhook 1: notifications → send_push
CREATE OR REPLACE FUNCTION public.notify_send_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _url     text;
  _secret  text;
  _svc_key text;
  _payload jsonb;
BEGIN
  _url     := current_setting('app.settings.supabase_url', true) || '/functions/v1/send_push';
  _secret  := current_setting('app.settings.webhook_secret', true);
  _svc_key := current_setting('app.settings.service_role_key', true);

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
      'Content-Type',      'application/json',
      'x-webhook-secret',  _secret
    ),
    body    := _payload
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_send_push ON public.notifications;
CREATE TRIGGER trg_notify_send_push
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_send_push();

-- Webhook 2: guardian_consents → send_guardian_consent_email
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
  _secret := current_setting('app.settings.webhook_secret', true);

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
      'Content-Type',      'application/json',
      'x-webhook-secret',  _secret
    ),
    body    := _payload
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_guardian_consent ON public.guardian_consents;
CREATE TRIGGER trg_notify_guardian_consent
  AFTER INSERT ON public.guardian_consents
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_guardian_consent_email();
