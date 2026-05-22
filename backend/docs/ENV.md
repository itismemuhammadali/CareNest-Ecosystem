# Environment variables

| Location | File | Purpose |
|----------|------|---------|
| Repo root (CLI / scripts) | `.env` (gitignored) | `SUPABASE_*`, `WEBHOOK_SECRET`, FCM, Resend — copy from [`.env.example`](../.env.example) |
| Local Edge `supabase functions serve` | `supabase/.env.local` | Gitignored — copy from `supabase/.env.example` |
| Hosted Edge | Supabase **Secrets** or `supabase secrets set` | Same logical names; never commit values — see [`SECRETS_AND_ENV.md`](./SECRETS_AND_ENV.md) |

Full matrix: [`LOCAL_DEV.md`](./LOCAL_DEV.md).
