# Testing

## Flutter

From each app directory (`Star_Sitter_Family`, `Star_Sitter_Baby_Sitter`, `star_sitters_core`):

```bash
flutter pub get
flutter test
dart analyze
```

## Postgres / RLS

- **Smoke script (manual):** [`../supabase/tests/rls_smoke.sql`](../supabase/tests/rls_smoke.sql) — policy / RPC checklist; run fragments in Supabase SQL Editor with a real JWT when tightening security.
- **Cert document RPC:** after uploading to bucket `cert-docs`, clients should call **`register_certification_document(p_cert_type, p_document_path)`** (path must be `{auth_user_id}/...` relative to the bucket). Migration: `20260513100000_cert_document_rpc_courses_seed_rls_tighten.sql`.
- **Full regression:** BACKEND.md still allows pgTAP / scripted assertions per policy — not yet automated in CI.

## Hosted runbook

See [`HOSTED_CLOUD_SETUP.md`](./HOSTED_CLOUD_SETUP.md) §8 and [`DEPLOY.md`](./DEPLOY.md).
