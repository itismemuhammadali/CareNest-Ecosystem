# Run Star Sitters backend locally

Postgres + Supabase CLI + Docker. No separate Node API.

**Monorepo:** to run **both Flutter apps + Admin Next** together, follow the root checklist [`RUN_LOCAL.md`](../../RUN_LOCAL.md) in the PIXORAFT1 workspace.

**Hosted project (FCM + Resend + webhooks):** see [`HOSTED_CLOUD_SETUP.md`](./HOSTED_CLOUD_SETUP.md).

## Prerequisites

- Docker running
- [Supabase CLI](https://supabase.com/docs/guides/cli)

## Environment files

```bash
cp .env.example .env
# After `supabase status`, paste SUPABASE_* keys into `.env`.

cp supabase/.env.example supabase/.env.local
# Same keys for `supabase functions serve --env-file supabase/.env.local`
```

`.env` and `supabase/.env.local` are gitignored; only `*.example` files are committed.

## Commands

```bash
cd starsitters-backend
supabase start
supabase db reset
supabase status
```

Use Studio URL from `supabase status` to inspect tables, RLS, and run test SQL.

## GitHub Actions

Workflow **`supabase-db`** has two jobs:

| Job | When it runs | Result |
|-----|----------------|--------|
| `migrate-check` | Every push touching `supabase/migrations/**` or `seed.sql` | Always runs; verifies `.sql` files exist (keeps **main** green). |
| `hosted-db-push` | Only if **variable** `ENABLE_SUPABASE_DB_PUSH` = `true` **and** both **secrets** are set | Runs `supabase link` + `db push` to your cloud project. |

If you previously set `ENABLE_SUPABASE_DB_PUSH` without secrets, older workflow versions could still fail. Current workflow skips `hosted-db-push` until **all three** are present.

**If `hosted-db-push` still fails:** open the job log — common causes are expired personal access token, wrong `SUPABASE_PROJECT_REF`, or **paused** Supabase project (restore in dashboard).

## Paused cloud projects

Restore the project in the Supabase dashboard before MCP or `db push` to hosted DB will work.

---

## Full key & URL inventory (BACKEND.md §21–§22 + §31)

Use this as the checklist for “everything wired.” **v0.1** can run with **mock** push/email (no Firebase/Resend) once Supabase is up.

### A. Supabase project (every client)

| Name | Where you get it | Who holds it |
|------|-------------------|--------------|
| **Project URL** | Dashboard → Settings → API → `URL` | Flutter, Admin web (`NEXT_PUBLIC_SUPABASE_URL`), `.env` |
| **Anon (public) key** | Settings → API → `anon` `public` | Flutter, Admin web only — **safe in bundles** |
| **Service role key** | Settings → API → `service_role` **secret** | Edge Functions (auto in cloud), **never** in Flutter/admin client bundles |
| **Project ref** | URL `https://<REF>.supabase.co` or Settings → General | `supabase link`, GitHub secret `SUPABASE_PROJECT_REF` |
| **Personal access token** | [Account → Access Tokens](https://supabase.com/dashboard/account/tokens) | `supabase link` / CI only (`SUPABASE_ACCESS_TOKEN`) |

Local CLI: after `supabase start`, run `supabase status` — it prints **API URL**, **anon key**, and **service_role** for your machine.

### B. Edge Functions (hosted: `supabase secrets set` — BACKEND.md §8, §22)

| Secret | Required when | Notes |
|--------|----------------|-------|
| `SUPABASE_URL` | Always (cloud auto-injects) | Same as project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Always (auto-injected) | Server-side only |
| `WEBHOOK_SECRET` | Always | Same random string in **Database → Webhooks** header `x-webhook-secret` |
| `APP_BASE_URL` | Always for consent links | Use your **real** app or marketing site URL so guardians open a real page (can be Flutter web later); not only `*.supabase.co` |
| `FCM_PROJECT_ID` | `system_config.fcm_provider` = **`live`** | Firebase project id |
| `FCM_SERVICE_ACCOUNT_JSON` | `fcm_provider` = **`live`** | Full Firebase service account JSON (FCM HTTP v1) |
| `RESEND_API_KEY` | `email_provider` = **`resend`** | From resend.com |
| `EMAIL_FROM` | Resend sends | Verified sender/domain in Resend |

With **`fcm_provider`** / **`email_provider`** = **`mock`** in `system_config` (seed default), you do **not** need FCM or Resend for demos — functions log and return 200.

### C. Database webhooks (Dashboard, not `.env`)

| Webhook | Table | Events | URL |
|---------|-------|--------|-----|
| e.g. `notify_on_insert` | `notifications` | INSERT | `{SUPABASE_URL}/functions/v1/send_push` |
| e.g. `guardian_consent_email` | `guardian_consents` | INSERT | `{SUPABASE_URL}/functions/v1/send_guardian_consent_email` |

Both must send header **`x-webhook-secret: <same WEBHOOK_SECRET>`**.

### D. Flutter apps (`Star_Sitter_Family`, `Star_Sitter_Baby_Sitter`) — BACKEND.md §22

| Variable | Purpose |
|----------|---------|
| `SUPABASE_URL` | Same project URL |
| `SUPABASE_ANON_KEY` | anon key only |
| `GOOGLE_OAUTH_CLIENT_ID_ANDROID` | Google Sign-In (Android) — Google Cloud OAuth client |
| `GOOGLE_OAUTH_CLIENT_ID_IOS` | iOS (when you ship iOS) |
| **`google-services.json`** | Firebase Android (FCM + often Google Sign-In) — file on disk, not always a single “API key” string |

Email/password auth uses Supabase Auth — no extra API key beyond project keys.

### E. Admin Next.js (`StarSitters_Admin` / `starsitters-admin`) — BACKEND.md §31

| Variable | Purpose |
|----------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | anon key only |

Admin RPCs still require the logged-in user to be in **`admin_users`** and `users.role = 'admin'` per spec.

### F. GitHub Actions (optional CI deploy)

| Name | Type | Purpose |
|------|------|---------|
| `SUPABASE_ACCESS_TOKEN` | Secret | PAT for `supabase link` / `db push` |
| `SUPABASE_PROJECT_REF` | Secret | Project ref string |
| `ENABLE_SUPABASE_DB_PUSH` | **Variable** (not secret) | Must be `true` to run hosted deploy job |

### G. v0.2 / deferred (BACKEND.md §26–§27) — not required for Tuesday demo

Stripe, Checkr/Sterling, Apple Sign-In, Google Maps keys, Sentry, etc. — adapter flags in `system_config`; keys arrive later per product plan.
