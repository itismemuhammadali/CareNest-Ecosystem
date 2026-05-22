# Hosted Supabase + Edge Functions (demo / staging)

Flutter mobile apps use **project URL + anon key** in each app `.env` (see repo root `RUN_LOCAL.md` §8). This document covers **Edge Functions**, **secrets**, and **webhooks** after schema is pushed.

Use this after **`supabase db push`** to your cloud project. **Never commit** service-role keys, Firebase private keys, Resend keys, or webhook secrets to git — use **Dashboard → Edge Function secrets** and **GitHub encrypted secrets** only.

## 0. If secrets were ever pasted in chat, email, or a ticket

Treat them as **compromised**. Rotate immediately:

- [Supabase Dashboard → Account → Access Tokens](https://supabase.com/dashboard/account/tokens) — revoke old PAT, create new.
- **Project Settings → API** — rotate **service_role** if it was exposed (regenerate where offered).
- [Google Cloud Console](https://console.cloud.google.com/) → IAM → Service Accounts → **Firebase Admin SDK** key — delete leaked JSON, create a new key; update Edge secrets.
- [Resend](https://resend.com/) — rotate API key if exposed.

## 1. Link CLI and push schema

```bash
cd starsitters-backend
supabase login   # uses PAT from dashboard account tokens
supabase link --project-ref <YOUR_PROJECT_REF>   # from project URL: https://<REF>.supabase.co
supabase db push
```

## 2. Deploy Edge Functions

Database webhooks call these URLs **without a user JWT**. Deploy with **`--no-verify-jwt`** so Supabase does not block the request at the gateway (your code still checks **`x-webhook-secret`**).

```bash
supabase functions deploy send_push --no-verify-jwt
supabase functions deploy send_guardian_consent_email --no-verify-jwt
```

## 3. Set Edge secrets (hosted)

**Option A — from a filled, gitignored repo `.env` (recommended):**

```bash
cd starsitters-backend
cp .env.example .env
# Edit .env with **new** rotated secrets only (never commit).
bash scripts/push-hosted-secrets.sh
```

**Option B — `supabase secrets set` manually:**

```bash
supabase secrets set \
  WEBHOOK_SECRET="<same value as DB webhook header x-webhook-secret>" \
  APP_BASE_URL="https://your-marketing-or-app-domain.example" \
  RESEND_API_KEY="re_..." \
  EMAIL_FROM="Star Sitters <verified@yourdomain.com>" \
  FCM_PROJECT_ID="your-firebase-project-id" \
  FCM_SERVICE_ACCOUNT_JSON='{"type":"service_account",...one line...}'
```

Notes:

- **`FCM_SERVICE_ACCOUNT_JSON`** must be the **full** service account JSON on **one line** (`jq -c . < key.json`). Do not commit the file.
- Until you set live providers (step 4), functions still return **200** in **`mock`** mode without valid FCM/Resend.

See also [`SECRETS_AND_ENV.md`](./SECRETS_AND_ENV.md).

## 4. Flip providers in Postgres (optional — real push / email)

Default **`seed.sql`** keeps:

- `fcm_provider` = **`mock`**
- `email_provider` = **`mock`**

To send real FCM / Resend from Edge, run in **SQL Editor** (after secrets are set):

```sql
update public.system_config set value = '"live"'::jsonb where key = 'fcm_provider';
update public.system_config set value = '"resend"'::jsonb where key = 'email_provider';
```

To go back to safe demos:

```sql
update public.system_config set value = '"mock"'::jsonb where key = 'fcm_provider';
update public.system_config set value = '"mock"'::jsonb where key = 'email_provider';
```

## 5. Database webhooks (no `supabase` CLI subcommand)

Supabase does **not** provide something like `supabase db webhook create`. You either use the **Dashboard** or define a **SQL trigger** yourself (wrappers around `pg_net` / `supabase_functions.http_request` — see [Database Webhooks](https://supabase.com/docs/guides/database/webhooks)).

**Dashboard (recommended):** [Project → Integrations → Database Webhooks](https://supabase.com/dashboard/project/_/integrations/webhooks/overview) (older UI paths may say **Database → Webhooks**).

Both hooks must send header **`x-webhook-secret`** with the **exact same** value as Edge secret **`WEBHOOK_SECRET`**.

| Name | Table | Events | HTTP request URL |
|------|--------|--------|-------------------|
| Push on notification | `public.notifications` | Insert | `https://<PROJECT_REF>.supabase.co/functions/v1/send_push` |
| Guardian consent email | `public.guardian_consents` | Insert | `https://<PROJECT_REF>.supabase.co/functions/v1/send_guardian_consent_email` |

- Method: **POST**  
- Body: default **Supabase** webhook JSON (includes `record`, `type`, `table`, `schema`) — matches what the Edge handlers parse  
- Header: **`x-webhook-secret: <WEBHOOK_SECRET>`** (create the header in the webhook’s “HTTP Headers” section)

**Secrets the functions read (hosted):**

| Variable | Required when | Notes |
|----------|----------------|--------|
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Always | **Auto-injected** on hosted Edge Functions — you normally do **not** set these via `secrets set`. |
| `WEBHOOK_SECRET` | Always | Must match the webhook header; `openssl rand -hex 32` is fine. |
| `APP_BASE_URL` | Guardian email | **Public URL** where `/consent?token=…` resolves (app or marketing site), **not** the Supabase API URL. |
| `RESEND_API_KEY` | Real email | Only when `system_config.email_provider` = **`resend`**. |
| `EMAIL_FROM` | Optional | Pushed by `push-hosted-secrets.sh` if set; **`send_guardian_consent_email`** uses `system_config` key **`email_from`** (via `cfg_text`) for the Resend `from` field. |
| `FCM_PROJECT_ID` + `FCM_SERVICE_ACCOUNT_JSON` | Real push | Only when `system_config.fcm_provider` = **`live`**. JSON = full Firebase **service account** key (one line, `jq -c .`). |

## 6. Flutter + Admin clients

Use **anon** key + project URL only in:

- `Star_Sitter_*` `--dart-define` or `.env` (see each app’s `.env.example`)
- `StarSitters_Admin/starsitters-admin/.env.local` — `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`

Never ship **service_role** in mobile or browser bundles.

## 7. Deferred (v0.2+) — no keys required now

- **Stripe Connect** — `system_config.payout_provider` stays **`manual`** in seed; add keys when you implement payouts.
- **Hard geofencing** — `geofence_hard_block` defaults **`false`**; tighten when product/legal requires it. **`geofence_notify_family`** (default **`true`**) inserts a **`geofence_warning`** notification to the job’s family on soft clock-in/out misses (migration `20260211170000`).

See also [LOCAL_DEV.md](./LOCAL_DEV.md) for the full variable matrix.

## 8. Verifying hosted setup (outside the repo)

This cannot be confirmed from Git alone — run these in **SQL Editor** and the **Dashboard**:

**A. `system_config` keys exist** (hosted DB does not auto-run `seed.sql`):

```sql
select key, value from public.system_config
where key in ('fcm_provider','email_provider','email_from','geofence_hard_block','geofence_notify_family');
```

If rows are missing, use the `INSERT … ON CONFLICT` patterns in earlier support docs or run `supabase db push` after linking so migrations + manual seed SQL align.

**B. Edge Functions:** Dashboard → **Edge Functions** — `send_push` and `send_guardian_consent_email` listed; **Secrets** tab has `WEBHOOK_SECRET` (and FCM/Resend when live).

**C. Webhooks:** **Integrations → Database Webhooks** — two hooks on `notifications` and `guardian_consents` INSERT; each has header **`x-webhook-secret`** matching the Edge secret.

**D. After `supabase db push`:** apply new migrations from this repo (e.g. geofence family notification) so hosted matches `main`.

See also [DEPLOY.md](./DEPLOY.md) and [ENV.md](./ENV.md).
