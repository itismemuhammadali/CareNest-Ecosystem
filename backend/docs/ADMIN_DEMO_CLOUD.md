# Admin demo data on hosted Supabase

Use this when the admin app points at **cloud** Supabase (`https://<project-ref>.supabase.co`).

## Show the client “the data lives in Supabase”

1. Open [Supabase Dashboard](https://supabase.com/dashboard) and sign in.
2. Select the **same project** as `NEXT_PUBLIC_SUPABASE_URL` (project ref is the subdomain before `.supabase.co`).
3. Go to **Table Editor** (left sidebar). Open tables such as `family_profiles`, `jobs`, `disputes`, `users`, and `sitter_profiles` — the rows you see are what the admin UI reads (via the anon key + RLS, and admin RPCs where applicable).
4. Optional: **Authentication → Users** lists auth accounts; **`public.users`** mirrors profile rows created by triggers.

## Pending demo families (approve / reject in the app)

**Option A — API (creates real Auth users + profiles):** from `starsitters-backend`:

```bash
bash scripts/seed-pending-family.sh
```

Run it several times for multiple rows. Then refresh **Families Management**; use the row **Approve** (check) or **Reject** (X) when status is **Pending** (calls `admin_approve_family` / `admin_reject_family`).

**Option B — SQL (reset existing demo-looking families to pending):** in Dashboard → **SQL** → New query, paste and run:

`docs/sql/seed_admin_dashboard_demos.sql`

That script only touches families whose email ends with `@starsitters.invalid` or whose name matches “Demo Pending …”, then seeds jobs/disputes.

## Babysitters — pending vs active

- **Certification** column in the admin table is driven by `guardian_consent_status === 'approved'` (guardian consent), not course certs alone.
- **Account status “Pending”** means `is_active` is false. Use the **green shield** on the row to **activate** (calls `admin_unsuspend_sitter`, which sets `is_active` true and clears suspension fields).
- **Suspend** uses `admin_suspend_sitter` (red shield when active).

## Jobs and disputes

After running `docs/sql/seed_admin_dashboard_demos.sql`, open **Jobs Monitoring** and **Disputes & Issues** and refresh.

## Safety

- Do not run the SQL seed on production with real customer emails matching the demo filters; narrow the `WHERE` clauses in the file if needed.
