# Admin Web App SRS Closure Checklist

Scope baseline: SRS + Application Flow (Families, Babysitters, Admin Dashboard), limited to admin-web-app relevant requirements.

Last updated: 2026-05-11

## Status Summary

- **Implemented in code:** Admin auth/RBAC, verification approvals, certification approvals, wage/system config, reporting pages, notifications page, disputes workflows.
- **Partially verified:** End-to-end runtime verification is complete only for flows exercised manually in this workspace session.
- **External/manual required:** Hosted Supabase Auth URL + SMTP configuration and live inbox reset-email verification.

## Requirement Matrix (Admin Scope)

| SRS ID | Requirement (admin-relevant) | Status | Evidence |
|---|---|---|---|
| FR-001 | Role-based registration/login/authentication | PASS | `src/app/(auth)/page.tsx`, `src/middleware.ts` |
| FR-002 | Distinct role-based permissions | PASS | `src/middleware.ts` checks `admin_users` + role; settings RBAC card uses `fetchOwnAdminMembership()` |
| FR-004 | Admin review/approval of family background checks | PASS | `src/app/(dashboard)/families/page.tsx` + `approveFamily()/rejectFamily()` in `src/lib/supabase/admin.ts` |
| FR-007 | Application review + secure interaction + hiring support | PARTIAL | Jobs/disputes data are wired (`jobs`, `disputes` pages) but full hiring interaction depends on mobile-side flows and shared backend data |
| FR-008 | Secure in-app messaging | PARTIAL | Messaging data path exists in backend model; admin UI does not provide full chat moderation console in current scope |
| FR-011 | Admin verifies certifications | PASS | `src/app/(dashboard)/certifications/page.tsx`, `approveCertificationSubmission()`, `rejectCertificationSubmission()` |
| FR-014 | Notifications/alerts | PASS | `src/app/(dashboard)/notifications/page.tsx`, header bell integration, backend `send_push` delivery states |
| FR-015 | Admin dashboard for user/verification management | PASS | Dashboard + Families + Babysitters + Jobs pages wired via Supabase client helpers |
| FR-016 | Admin configures wages and platform rules | PASS | `src/app/(dashboard)/wages/page.tsx`, `src/app/(dashboard)/settings/page.tsx`, `admin_update_wage_tiers`, `admin_update_system_config` |
| FR-017 | Admin reporting and analytics | PASS | `src/app/(dashboard)/reports/page.tsx`, `/api/admin/reports/export`, report RPC consumers |
| FR-018 | RBAC + secure data handling | PASS | Server-side role gate in `src/middleware.ts`; protected API route in `src/app/api/admin/reports/export/route.ts` |
| FR-019 | Deployment readiness (admin side) | PARTIAL | Build is clean in normal env, but local CI-style build in this session hit transient Google Fonts fetch failure; deploy pipeline validation still needed |

## End-to-End Checks Completed in This Session

1. **Code-level flow verification**
   - Families approve/reject path traces to backend RPC calls.
   - Certification approve/reject path traces to backend RPC calls.
   - Wage/settings save path traces to backend config + wage RPC calls.
   - Reports page traces to report RPCs and CSV export route.

2. **Build verification**
   - `next build` succeeds in prior runs in this workspace.
   - Latest run failed due network fetch of Google Font (`Inter`) from `fonts.googleapis.com` (environmental/network issue, not TS/runtime logic regression).

3. **Forgot-password runtime verification (admin auth UX)**
   - Opened `http://localhost:3000/forgot-password`.
   - Submitted reset request for `tshaukat.25@gmail.com`.
   - UI transitioned to **Check Your Email** state with **Resend Email** action.
   - This confirms client integration path to Supabase Auth reset endpoint from the admin app.

4. **Authenticated admin runtime verification (browser UAT)**
   - Created disposable local admin account via service-role API and inserted `admin_users` membership (`permissions: ['all']`).
   - Logged in successfully and confirmed redirect to `/dashboard`.
   - Navigated and validated load states + data bindings for:
     - `/dashboard`
     - `/wages` (save action completed; success status rendered: "Saved to Supabase ...")
     - `/reports` (charts/cards populated, export controls visible/enabled)
     - `/settings` (RBAC card resolved to admin membership; platform settings save completed with success status)
     - `/notifications`
     - `/disputes`
   - These checks confirm FR-015/FR-016/FR-017 admin workflows are wired and operational in local runtime.

5. **Families approve/reject workflow verification**
   - Loaded `/families` with non-zero dataset (5 rows).
   - Executed **Approve** on one pending family and observed stat transition:
     - Verified: `1 -> 2`
     - Pending: `3 -> 2`
   - Executed **Reject** on one pending family (with rejection reason) and observed transition:
     - Pending: `2 -> 1`
     - Rejected: `1 -> 2`
   - Confirms FR-004 operational behavior in runtime.

6. **Certification approve/reject workflow verification**
   - Seeded demo course + two pending certification submissions.
   - In `/certifications` -> Certification Approvals:
     - Approved one submission.
     - Rejected one submission with explicit reason.
   - Observed stat transition:
     - Pending Approvals: `2 -> 0`
     - Avg Completion Rate reflected decided data (`88%` shown).
   - Confirms FR-011 operational behavior in runtime.

7. **Notifications lifecycle verification (non-zero)**
   - Opened `/notifications` after family/cert decisions generated notification events.
   - Observed non-zero loaded dataset:
     - Loaded rows: `6`
     - Pending/sent: `6`
   - Confirms FR-014 runtime ingestion/rendering with live records (non-empty).

8. **Reports export artifact verification (non-empty CSV)**
   - Generated export-equivalent notifications CSV artifact from the same source columns used by `/api/admin/reports/export`.
   - Artifact path: `starsitters-backend/docs/notifications-export-check.csv`
   - Validation: `6` data rows + header (`7` lines total).
   - Confirms export data availability with non-empty payload.

## Remaining Items to Fully Close SRS Admin Scope

### A) Hosted Supabase (outside repo; manual)

1. Authentication -> URL Configuration
   - Set **Site URL** to production admin origin.
   - Add Redirect URLs including `/reset-password` for all used origins.
2. Authentication -> Emails
   - For production robustness, configure **custom SMTP** (recommended).
   - Keep Confirm Email behavior aligned with production policy.
3. Authentication -> Email templates
   - Verify reset template includes Supabase confirmation URL variable.
4. Complete live reset-password test to real inbox (open link + change password + relogin).

### B) Final runtime acceptance (manual UAT)

1. Complete hosted live reset-password test to real inbox (open link + change password + relogin) on final production URL + SMTP configuration.

## Notes

- This checklist is intentionally scoped to admin web app + shared backend integration points used by admin.
- Mobile family/babysitter UX completeness is tracked separately from this admin closure file.
