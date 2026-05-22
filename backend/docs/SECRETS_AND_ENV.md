# Secrets and environment variables

## What never goes in Git

- Supabase **service_role** key  
- Supabase **personal access tokens**  
- **Webhook** shared secret (`WEBHOOK_SECRET`)  
- **Firebase** service account JSON (private key)  
- **Resend** API key  
- Any key that was **ever pasted into chat, email, or a ticket** — treat as **burned**; create **new** credentials in each dashboard and update only local `.env` / Supabase **Edge secrets**.

## Where secrets *do* go

| Context | File / location |
|--------|------------------|
| Local Edge `serve` | `supabase/.env.local` (gitignored) — copy from `supabase/.env.example` |
| Local scripts / CI | Repo root `.env` (gitignored) — copy from `.env.example` |
| Hosted Edge Functions | `supabase secrets set …` after `supabase link` — see [`HOSTED_CLOUD_SETUP.md`](./HOSTED_CLOUD_SETUP.md) or run `bash scripts/push-hosted-secrets.sh` |
| Flutter apps | `Star_Sitter_*/.env` (gitignored) — **anon** key + URL only |
| Admin Next.js | `StarSitters_Admin/starsitters-admin/.env.local` — **anon** + URL only |

## Rotating after a leak

1. **Supabase** — revoke old PAT; rotate **service_role** if it was exposed; regenerate **anon** only if you also exposed it to untrusted parties.  
2. **Firebase** — delete the leaked service account key JSON; create a new key; update `FCM_SERVICE_ACCOUNT_JSON` in Edge secrets.  
3. **Resend** — create a new API key; revoke the old one.  
4. **Webhooks** — generate a new `WEBHOOK_SECRET` (`openssl rand -hex 32`), set in Edge secrets **and** in each Database webhook header.

After rotation, your **code and demos behave the same** — only the secret material changes.

## Database webhooks + Edge secrets (hosted)

There is **no** `supabase` CLI command to create database webhooks — use the Dashboard (and match **`x-webhook-secret`** to **`WEBHOOK_SECRET`**). Full order of operations: [`HOSTED_CLOUD_SETUP.md`](./HOSTED_CLOUD_SETUP.md) §2–§5.
