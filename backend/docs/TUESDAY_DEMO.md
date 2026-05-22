# Tuesday demo — non-technical walkthrough

Aligned with **BACKEND.md §19**. One Supabase project; two Android apps (Family + Sitter).

## Prep

1. Apply migrations (`supabase db push` or SQL Editor).
2. Auth: email confirmations ON; Google redirect URIs per BACKEND.md §5 checklist.
3. Edge secrets: `WEBHOOK_SECRET`, `APP_BASE_URL`. Keep `fcm_provider` / `email_provider` = **mock** until keys exist.
4. Webhooks: `notifications` → `send_push`; `guardian_consents` → `send_guardian_consent_email` (header `x-webhook-secret`).
5. Family: `family_profiles` + `bg_check_status = 'approved'` (via `admin_approve_bg_check` or Studio for demo).
6. Sitter: `sitter_profiles` + guardian link → `confirm_guardian_consent` → admin `admin_approve_certification` → `is_active = true`.

## Live narrative

Show Table Editor, then app flow: post job → apply (`create_application`) → hire (`create_hire`) → chat messages → clock in/out → wallet/ledger in SQL. Finish with `audit_logs` as the tamper-evident trail.
