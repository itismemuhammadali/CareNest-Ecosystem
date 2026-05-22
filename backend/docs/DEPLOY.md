# Deploy (hosted Supabase)

Order of operations:

1. **Schema:** `supabase link --project-ref <REF>` then `supabase db push` from this repo root.
2. **Edge Functions:** `supabase functions deploy send_push --no-verify-jwt` and `send_guardian_consent_email --no-verify-jwt`.
3. **Secrets:** [`HOSTED_CLOUD_SETUP.md`](./HOSTED_CLOUD_SETUP.md) §3 (`supabase secrets set` or Dashboard).
4. **Database webhooks:** same doc §5 (no CLI — Dashboard only).
5. **Config rows:** SQL in §4 for `system_config` (`fcm_provider`, `email_provider`, etc.).

CI: see `.github/workflows/` if present for automated `db push`.
