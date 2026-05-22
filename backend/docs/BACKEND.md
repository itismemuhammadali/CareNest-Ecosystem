# BACKEND.md — Star Sitters Platform v0.1
## Teen Babysitter Marketplace — Complete Backend Engineering Reference

**Owner:** Backend Developer (you — separate `starsitters-backend` repo)
**Frontend:** Muhammad Ali — `Star_Sitter_Family` + `Star_Sitter_Baby_Sitter` repos
**Admin Web:** `StarSitters_Admin` (cloned from `naqiiabbas/StarSitters`) — wired by you in Week 2
**Last updated:** May 2026
**Status:** Approved build plan — Week 1 mobile sprint (Days 1–5, Tue + Fri demos), Week 2 admin web sprint (Days 6–10)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [System Architecture](#2-system-architecture)
3. [Tech Stack — Full Justification](#3-tech-stack--full-justification)
4. [Repository Layout](#4-repository-layout)
5. [Postgres Schema — Full DDL](#5-postgres-schema--full-ddl)
6. [Row-Level Security — All Policies](#6-row-level-security--all-policies)
7. [Server-Side RPCs — Full Bodies](#7-server-side-rpcs--full-bodies)
8. [Edge Functions](#8-edge-functions)
9. [Storage Buckets + Access Policies](#9-storage-buckets--access-policies)
10. [Auth Flow](#10-auth-flow)
11. [Wage Engine Spec](#11-wage-engine-spec)
12. [Geofencing Spec](#12-geofencing-spec)
13. [Real-Time Chat Spec](#13-real-time-chat-spec)
14. [Push Notification Pipeline](#14-push-notification-pipeline)
15. [Security & DDoS Hardening](#15-security--ddos-hardening)
16. [Shared Flutter Package — star_sitters_core](#16-shared-flutter-package--star_sitters_core)
17. [Screen-by-Screen Wiring Map](#17-screen-by-screen-wiring-map)
18. [5-Day Execution Plan](#18-5-day-execution-plan)
19. [Tuesday Demo Script](#19-tuesday-demo-script)
20. [Friday Demo Script](#20-friday-demo-script)
21. [Deployment & Environment Setup](#21-deployment--environment-setup)
22. [Environment Variable Inventory](#22-environment-variable-inventory)
23. [Observability & Logging](#23-observability--logging)
24. [CI/CD Pipeline](#24-cicd-pipeline)
25. [Risk Register](#25-risk-register)
26. [v0.2 Backlog](#26-v02-backlog)
27. [External Service Integration Points (Pluggable Keys)](#27-external-service-integration-points-pluggable-keys)
28. [Deployment Strategy (Render / Firebase / TestFlight)](#28-deployment-strategy-render--firebase--testflight)
29. [Appendix A — Full DDL (runnable block)](#29-appendix-a--full-ddl-runnable-block)
30. [Appendix B — Full RLS (runnable block)](#30-appendix-b--full-rls-runnable-block)
31. [Admin Web Application — Complete Technical Breakdown](#31-admin-web-application--complete-technical-breakdown)
32. [Critical Review Reconciliation Log](#32-critical-review-reconciliation-log)

---

## 1. Executive Summary

Star Sitters is a two-sided mobile marketplace connecting **families** who need childcare with **certified teenage babysitters (ages 11–17)**. The platform is safety-first by design: all babysitters require guardian consent and admin-verified certifications before they can work; all families require admin-approved background checks before they can hire.

The backend underpins three clients: two existing Flutter apps (Family + Babysitter) and a Next.js admin web app (`StarSitters_Admin`). It is a **single monolithic Postgres backend** hosted on Supabase, with Firebase Cloud Messaging as the only additional external service (push notifications). There are **no microservices, no separate admin backend, no second API server.** All three clients hit the same Supabase project — same database, same Auth, same RLS, same Edge Functions, same audit log. The admin web app is just a third client that calls `admin_*` RPCs the Flutter apps don't call. This is the right call for a solo developer on a tight sprint and stays the right call up to approximately 50,000 MAU.

### One backend, three clients

| Client | Repo | Logs in as | Trusted via | Calls |
|---|---|---|---|---|
| Family Flutter app | `Star_Sitter_Family` | `users.role = 'family'` | JWT (`auth.uid()`) | RLS reads, family RPCs (`create_hire`, post job) |
| Babysitter Flutter app | `Star_Sitter_Baby_Sitter` | `users.role = 'sitter'` | JWT (`auth.uid()`) | RLS reads + open jobs, sitter RPCs (`create_application`, `clock_in`, `clock_out`, `request_withdrawal`) |
| Admin Web (Next.js) | `StarSitters_Admin` | `users.role = 'admin'` + row in `admin_users` | JWT + `admin_only()` Postgres guard | All `admin_*` RPCs (approve/reject, resolve disputes, update wage tiers, pay withdrawals) |

### Sprint timeline (corrected)

| Sprint | Days | Scope | Demos |
|---|---|---|---|
| **Week 1 — Mobile** | Days 1–5 | Backend schema + RLS + RPCs + Edge Functions + Flutter wiring on both apps | Tuesday demo (Day 4): post → apply → hire → chat → clock → wage. Friday demo (Day 5): bg-check, cert, admin approval via Supabase Studio, geofence, withdrawal, audit log |
| **Week 2 — Admin Web** | Days 6–10 | Next.js admin app wired to the same Supabase backend, security hardening, Vercel deploy | End of Week 2 demo: full admin app live |

The Friday Week-1 demo does **not** depend on the admin web app — admin actions are demoed via Supabase Studio (already in §20). The admin web app is a follow-on sprint that wires the existing backend's `admin_*` RPCs to a polished UI.

### What gets delivered

| Milestone | Date | Content |
|---|---|---|
| Tuesday demo | Day 4 | Auth → post job → apply → hire → chat → clock in/out → wage in wallet. Two Android phones, real data, real Supabase DB |
| Friday demo | Day 5 | Everything above + bg-check upload, cert upload, admin approval flows (via Supabase Studio), geofence demo, withdrawal request, audit log walkthrough |
| v0.1.0 tag | Day 5 | All migrations, Edge Functions, shared Flutter package, CI, deploy docs |
| v0.2.0 tag | Day 10 | Admin web app live on Vercel, all admin actions wired |

### What is explicitly out of scope for v0.1

Stripe Connect live payouts, Checkr/Sterling automated background checks, Apple Sign-In + iOS push, advanced analytics, Redis caching, custom rate limiting, refunds, recurring bookings, multi-language, 2FA on admin.

---

## 2. System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                             │
│                                                                 │
│   Flutter Family App          Flutter Babysitter App            │
│   (Star_Sitter_Family)        (Star_Sitter_Baby_Sitter)         │
│         │                              │                        │
│         └──────────┬───────────────────┘                        │
│                    │ star_sitters_core package                   │
└────────────────────┼────────────────────────────────────────────┘
                     │
                     │ supabase_flutter SDK (WebSocket + HTTPS)
                     │
┌────────────────────▼────────────────────────────────────────────┐
│                      SUPABASE (monolithic backend)              │
│                                                                 │
│  ┌──────────────┐  ┌─────────────┐  ┌────────────────────────┐  │
│  │  Auth        │  │  Postgres   │  │  Realtime              │  │
│  │  (email +    │  │  (all data) │  │  (chat + job updates)  │  │
│  │   Google     │  │  + RLS      │  │                        │  │
│  │   OAuth)     │  │  + RPCs     │  │                        │  │
│  └──────────────┘  └──────┬──────┘  └────────────────────────┘  │
│                           │                                     │
│  ┌──────────────┐  ┌──────▼──────┐  ┌────────────────────────┐  │
│  │  Storage     │  │  Edge Fns   │  │  DB Webhooks           │  │
│  │  (avatars,   │  │  (send_push │  │  (trigger Edge Fns on  │  │
│  │   certs,     │  │   consent   │  │   row insert/update)   │  │
│  │   bg-docs)   │  │   email)    │  │                        │  │
│  └──────────────┘  └──────┬──────┘  └────────────────────────┘  │
└───────────────────────────┼─────────────────────────────────────┘
                            │
                            │ FCM HTTP v1 API
                            ▼
               ┌─────────────────────────┐
               │  Firebase Cloud         │
               │  Messaging (FCM)        │
               │  (push only)            │
               └─────────────┬───────────┘
                             │
               ┌─────────────▼───────────┐
               │  Android Devices        │
               │  (iOS deferred v0.2)    │
               └─────────────────────────┘
```

### Key architectural principles

1. **Single Postgres database is the source of truth.** No Firestore, no Redis, no secondary store in v0.1. Consistency is easy when there is one store.
2. **Authorization lives at the data layer, not the application layer.** RLS policies enforce access rules in Postgres itself. A bug in Flutter code cannot leak data from another user because the DB will deny the read.
3. **Sensitive business operations are server-side RPCs.** Clock-in/out, hiring, wage calculation, withdrawal — these run in `SECURITY DEFINER` Postgres functions, one transaction, cannot be forged by a client.
4. **Clients are untrusted.** Coordinates, amounts, user IDs passed in by the client are inputs to server-side validation, never trusted authority.
5. **Push notifications are decoupled from app code.** DB webhook fires after a row insert → Edge Function posts to FCM. Neither Flutter app needs to know FCM logic; it just receives.

---

## 3. Tech Stack — Full Justification

### Why Supabase over pure Firebase

This is the most important architectural decision in the project. Here is the honest comparison for *this specific application*:

**The decisive factors that force Supabase:**

**A. This app handles money.** Wage = `(seconds / 3600) × age_tier_rate`. The result goes into a ledger that determines how much a teenager gets paid. In Postgres, `numeric(10,2)` is an exact decimal type — `0.1 + 0.2 = 0.3` always. In JavaScript (Firestore/Cloud Functions), `0.1 + 0.2 = 0.30000000000000004`. Wage rounding errors on a minor's paycheck is not a demo-day problem — it is a legal liability. Postgres wins here with no contest.

**B. This app is heavily relational.** The data has this shape:

```
Family → Jobs → Applications → Hires → TimeEntries → LedgerEntries → Wallet
               ↓               ↓
          Conversations    Sitter (age, wage tier)
               ↓
           Messages
```

SQL was built for exactly this. Firestore forces denormalization — you either copy data into every document (causes sync drift) or do fan-out reads in client code (slow, expensive per-read pricing). The queries "show all applications for this family's open jobs" or "find all time entries for hires in the last 30 days" are one SQL join each. In Firestore they are multiple async reads with client-side assembly.

**C. Atomic operations are critical for financial integrity.** The `clock_out` operation must: close the time entry, calculate wage, insert a ledger row, update wallet balance — all in one transaction, all-or-nothing. If the server crashes halfway through, the state must roll back. Postgres transactions do this natively. Firestore multi-document transactions are limited (500 docs max, no cross-collection joins in a single transaction, no SQL constraints to catch bad data).

**D. RLS is provably correct for a minor-safety platform.** Regulators care that sitters cannot read other sitters' wallets, that families cannot read other families' children's data. Postgres RLS policies are short, declarative, version-controlled, and testable with `pgTAP`. Firestore Security Rules are powerful but harder to compose across many collections.

**E. Audit logs are free in Postgres.** A Postgres trigger on every status-change column automatically writes to `audit_logs`. In Firestore, every admin Cloud Function has to manually write to a separate collection — human error is when someone forgets to add the audit write to a new function.

**Why Firebase FCM stays in the stack:**
FCM is Firebase's flagship product. The `firebase_messaging` Flutter SDK is Google-maintained, handles Android/iOS/Web token lifecycle, background handling, and notification presentation — all in one package. Building equivalent notification delivery without FCM would take a full day. Using Supabase Edge Functions to call FCM HTTP v1 API (20 lines of TypeScript) keeps the delivery guarantee while keeping everything else in Supabase.

**Why no Node.js/Express API:**
A standalone API server doubles the surface area. You'd rewrite all auth glue, recreate permission logic that Postgres RLS gives for free, manage two deploy pipelines (API + migrations), handle connection pooling separately, debug across two systems. This is 12-15 days of work for one developer. The Supabase Edge Function runtime (Deno) can run the tiny amount of server-side logic needed (FCM calls, email sends) without a standalone server.

### Full stack summary

| Concern | Tool | Why |
|---|---|---|
| Database | Postgres (via Supabase) | Relational, transactional, exact numerics, RLS |
| Auth | Supabase Auth | OAuth + email built-in, Flutter SDK excellent |
| Authorization | Postgres RLS | Data-layer enforcement, testable, version-controlled |
| Realtime | Supabase Realtime | WebSocket channels over Postgres changes |
| File storage | Supabase Storage | RLS-style bucket policies, signed URLs |
| Server logic | Postgres functions + Edge Functions (Deno) | Co-located with data, atomic, no separate deploy |
| Push | Firebase Cloud Messaging | Best-in-class Flutter SDK, free |
| State management | Riverpod 2 | Standard Flutter choice, async streams, testable |
| Shared code | `star_sitters_core` Dart package | DRY between two apps |
| Observability | Sentry (Flutter) + Supabase logs | Free tier covers demo |
| CI | GitHub Actions | `supabase db push` + `flutter analyze` |

---

## 4. Repository Layout

### Four-repo strategy

```
GitHub Organization (your account / Muhammadali2025222)
├── Star_Sitter_Family/          ← Muhammad Ali's repo (family Flutter app)
│   └── pubspec.yaml             ← adds star_sitters_core as git dependency
│
├── Star_Sitter_Baby_Sitter/     ← Muhammad Ali's repo (sitter Flutter app)
│   └── pubspec.yaml             ← adds star_sitters_core as git dependency
│
├── StarSitters_Admin/           ← admin web app (forked from naqiiabbas/StarSitters)
│   └── starsitters-admin/       ← Next.js 16 + Tailwind v4 + Supabase SSR (Week-2)
│
└── starsitters-backend/         ← YOUR repo (backend, owned by you, single source of truth)
    ├── supabase/
    │   ├── config.toml
    │   ├── seed.sql
    │   └── migrations/
    │       ├── 20260501000001_extensions.sql
    │       ├── 20260501000002_types_enums.sql
    │       ├── 20260501000003_users.sql
    │       ├── 20260501000004_family.sql
    │       ├── 20260501000005_sitter.sql
    │       ├── 20260501000006_marketplace.sql
    │       ├── 20260501000007_time_wages.sql
    │       ├── 20260501000008_chat.sql
    │       ├── 20260501000009_wallet.sql
    │       ├── 20260501000010_notifications.sql
    │       ├── 20260501000011_admin_audit.sql
    │       ├── 20260501000012_rls_policies.sql
    │       ├── 20260501000013_rpcs.sql
    │       ├── 20260501000014_triggers.sql
    │       ├── 20260501000015_helpers.sql               (admin_only, write_audit_log, cfg_bool/cfg_text)
    │       ├── 20260501000016_immutability_triggers.sql (role + sitter is_active locks)
    │       ├── 20260501000017_admin_schema.sql          (courses, disputes, certification_submissions, uploaded_documents, job_timeline_events)
    │       ├── 20260501000018_admin_rpcs.sql            (admin_approve_*, admin_resolve_*, admin_dashboard_stats, etc.)
    │       └── 20260501000019_admin_rls.sql             (RLS for admin tables)
    ├── supabase/functions/
    │   ├── send_push/
    │   │   └── index.ts
    │   └── send_guardian_consent_email/
    │       └── index.ts
    ├── packages/
    │   └── star_sitters_core/
    │       ├── pubspec.yaml
    │       ├── lib/
    │       │   ├── star_sitters_core.dart   (barrel export)
    │       │   ├── src/
    │       │   │   ├── client.dart           (Supabase init)
    │       │   │   ├── models/
    │       │   │   │   ├── user.dart
    │       │   │   │   ├── job.dart
    │       │   │   │   ├── application.dart
    │       │   │   │   ├── hire.dart
    │       │   │   │   ├── time_entry.dart
    │       │   │   │   ├── message.dart
    │       │   │   │   ├── conversation.dart
    │       │   │   │   ├── wallet.dart
    │       │   │   │   ├── ledger_entry.dart
    │       │   │   │   └── notification.dart
    │       │   │   ├── repos/
    │       │   │   │   ├── auth_repo.dart
    │       │   │   │   ├── job_repo.dart
    │       │   │   │   ├── application_repo.dart
    │       │   │   │   ├── hire_repo.dart
    │       │   │   │   ├── chat_repo.dart
    │       │   │   │   ├── wallet_repo.dart
    │       │   │   │   └── notification_repo.dart
    │       │   │   ├── providers/
    │       │   │   │   └── providers.dart    (Riverpod providers)
    │       │   │   └── widgets/
    │       │   │       └── auth_gate.dart
    ├── docs/
    │   ├── BACKEND.md           ← this file (master copy)
    │   ├── DEPLOY.md
    │   ├── ENV.md
    │   ├── DEMO_TUESDAY.md
    │   └── DEMO_FRIDAY.md
    ├── .github/
    │   └── workflows/
    │       ├── db-push.yml
    │       └── flutter-analyze.yml
    └── README.md
```

**Implementation status (May 2026):** the canonical Git implementation is [`T361/starsitters-backend`](https://github.com/T361/starsitters-backend) (local path `PIXORAFT1/starsitters-backend/`). It ships migrations `20260209100001`–`20260209100017` covering §5 schema (through wallet + notifications + admin/audit), §6 RLS, §7 core + admin RPCs + `confirm_guardian_consent`, §8 Edge Functions (`send_push`, `send_guardian_consent_email` using `cfg_*` RPCs for typed config), `seed.sql`, CI workflow `supabase-db`, and `starsitters-backend/docs/TUESDAY_DEMO.md`. The numbered filenames in the ASCII tree above are the *logical* order from the spec; the repo uses the `20260209…` prefix until admin-schema migrations (§31.6–§31.7) land in a follow-up PR.

### How the Flutter apps consume star_sitters_core

**Current (May 2026):** four separate Git repos (`starsitters-backend`, both Flutter apps, admin). `star_sitters_core` is a **sibling folder** consumed via path dependency (not published as a fifth remote yet):

```yaml
dependencies:
  star_sitters_core:
    path: ../star_sitters_core
```

Optional later: publish `star_sitters_core` to its own Git repo and switch to a `git:` dependency for CI machines that do not clone the monorepo layout.

---

## 5. Postgres Schema — Full DDL

Every table, every column, every constraint, every index. Written as migration-ordered SQL.

### Migration 1 — Extensions

```sql
-- 20260501000001_extensions.sql
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";
create extension if not exists "cube";
create extension if not exists "earthdistance";
-- earthdistance requires cube; together they give ll_to_earth() and earth_distance()
```

### Migration 2 — Enums and Custom Types

```sql
-- 20260501000002_types_enums.sql

create type public.user_role as enum ('family', 'sitter', 'admin');
create type public.job_status as enum (
  'draft', 'open', 'hired', 'active', 'completed', 'cancelled'
);
create type public.application_status as enum (
  'pending', 'accepted', 'rejected', 'withdrawn'
);
create type public.verification_status as enum (
  'not_submitted', 'pending', 'approved', 'rejected'
);
create type public.ledger_type as enum (
  'earning', 'withdrawal', 'adjustment', 'refund'
);
```

### Migration 3 — Users

```sql
-- 20260501000003_users.sql

create table public.users (
  id          uuid        primary key references auth.users(id) on delete cascade,
  role        public.user_role  not null,
  email       text        not null unique,
  full_name   text,
  phone       text,
  avatar_url  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- auto-set updated_at
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_users_updated_at
  before update on public.users
  for each row execute function public.touch_updated_at();

-- auto-create user row on auth.users insert (via Supabase Auth hook)
create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  insert into public.users (id, role, email, full_name)
  values (
    new.id,
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'family'),
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();
```

### Migration 4 — Family Side

```sql
-- 20260501000004_family.sql

create table public.family_profiles (
  user_id              uuid        primary key
                                   references public.users(id) on delete cascade,
  home_address         jsonb       not null default '{}',
  home_lat             double precision,
  home_lng             double precision,
  home_safety_info     text,
  emergency_contact    jsonb       default '{}',
  babysitter_prefs     jsonb       default '{}',
  bg_check_status      public.verification_status not null default 'not_submitted',
  updated_at           timestamptz not null default now()
);

create trigger trg_family_profiles_updated_at
  before update on public.family_profiles
  for each row execute function public.touch_updated_at();

create table public.children (
  id          uuid        primary key default gen_random_uuid(),
  family_id   uuid        not null references public.family_profiles(user_id)
                          on delete cascade,
  name        text        not null check (char_length(name) between 1 and 100),
  age         int         not null check (age >= 0 and age <= 18),
  notes       text,
  created_at  timestamptz not null default now()
);

create index idx_children_family_id on public.children(family_id);

create table public.background_checks (
  id           uuid        primary key default gen_random_uuid(),
  family_id    uuid        unique not null
                           references public.family_profiles(user_id)
                           on delete cascade,
  documents    jsonb       not null default '[]',
  -- [{"type": "government_id", "storage_path": "bg-check-docs/uuid/file.pdf"}]
  status       public.verification_status not null default 'pending',
  reviewed_by  uuid        references public.users(id),
  reviewed_at  timestamptz,
  admin_notes  text,
  submitted_at timestamptz not null default now()
);
```

### Migration 5 — Sitter Side

```sql
-- 20260501000005_sitter.sql

create table public.sitter_profiles (
  user_id               uuid        primary key
                                    references public.users(id) on delete cascade,
  date_of_birth         date        not null,
  -- computed age: never trust client-provided age for wage calc
  bio                   text,
  is_active             boolean     not null default false,
  -- flips true after: guardian consent + admin approves
  guardian_consent_status public.verification_status not null default 'not_submitted',
  -- denormalized aggregates updated by fn_update_sitter_totals trigger
  -- after every UPDATE of time_entries.clock_out_at. Stored as numeric (dollars,
  -- two decimals) to match the wallet ledger; minutes is an int sum.
  total_minutes_worked  int             not null default 0,
  total_earnings        numeric(12,2)   not null default 0 check (total_earnings >= 0),
  updated_at            timestamptz not null default now(),
  -- enforce SRS age range: 11-17 at signup.
  -- Use raw date math, not extract(year from age()), because age() rounds year-boundary
  -- edge cases incorrectly (a sitter who turns 18 today would still pass extract(year)
  -- briefly). Comparing date_of_birth directly to current_date is exact to the day.
  constraint chk_sitter_age check (
    date_of_birth <= (current_date - interval '11 years')::date
    and date_of_birth >  (current_date - interval '18 years')::date
  )
);

create trigger trg_sitter_profiles_updated_at
  before update on public.sitter_profiles
  for each row execute function public.touch_updated_at();

-- Auto-create the wallet row whenever a sitter_profile is inserted.
-- Without this, the first clock_out RPC call fails with "no wallet for sitter"
-- because clock_out updates the wallet but never inserts the row itself.
-- The wallets table is defined in 20260501000009_wallet.sql; we reference it
-- forward — Postgres resolves at trigger-fire time, not creation time, so as
-- long as wallets exists before the first sitter_profile is inserted (it does,
-- because migrations run in order), this trigger is safe.
create or replace function public.fn_create_wallet_for_sitter()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  insert into public.wallets (sitter_id, available_balance, pending_balance,
                              lifetime_earnings, updated_at)
  values (new.user_id, 0, 0, 0, now())
  on conflict (sitter_id) do nothing;
  return new;
end;
$$;

create trigger trg_create_wallet_for_sitter
  after insert on public.sitter_profiles
  for each row execute function public.fn_create_wallet_for_sitter();

create table public.guardian_consents (
  id                 uuid        primary key default gen_random_uuid(),
  sitter_id          uuid        unique not null
                                 references public.sitter_profiles(user_id)
                                 on delete cascade,
  guardian_name      text        not null,
  guardian_email     text        not null,
  guardian_phone     text,
  consent_token      uuid        not null default gen_random_uuid(),
  -- sent in magic link; one-time use
  consent_given_at   timestamptz,
  consent_ip         inet,
  document_path      text,
  created_at         timestamptz not null default now()
);

-- consent_token must stay secret — never exposed via RLS to sitter
create unique index idx_guardian_consents_token
  on public.guardian_consents(consent_token);

create table public.certifications (
  id            uuid        primary key default gen_random_uuid(),
  sitter_id     uuid        not null
                            references public.sitter_profiles(user_id)
                            on delete cascade,
  cert_type     text        not null,
  -- e.g. 'cpr', 'first_aid', 'child_safety', 'food_handling'
  document_path text,
  status        public.verification_status not null default 'not_submitted',
  reviewed_by   uuid        references public.users(id),
  reviewed_at   timestamptz,
  admin_notes   text,
  expires_at    date,
  submitted_at  timestamptz not null default now()
);

create index idx_certifications_sitter_id on public.certifications(sitter_id);
create index idx_certifications_status on public.certifications(status);
```

### Migration 6 — Marketplace

```sql
-- 20260501000006_marketplace.sql

create table public.jobs (
  id                 uuid        primary key default gen_random_uuid(),
  family_id          uuid        not null
                                 references public.family_profiles(user_id)
                                 on delete cascade,
  title              text        not null check (char_length(title) between 5 and 200),
  description        text,
  date               date        not null,
  start_time         timestamptz not null,
  end_time           timestamptz not null,
  number_of_children int         not null check (number_of_children between 1 and 10),
  child_ids          uuid[]      not null default '{}',
  location_lat       double precision not null,
  location_lng       double precision not null,
  location_address   jsonb       not null default '{}',
  geofence_radius_m  int         not null default 150
                                 check (geofence_radius_m between 50 and 500),
  status             public.job_status not null default 'open',
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  constraint chk_job_times check (end_time > start_time)
);

create trigger trg_jobs_updated_at
  before update on public.jobs
  for each row execute function public.touch_updated_at();

-- compound index for the sitter job-feed query:
-- WHERE status = 'open' ORDER BY start_time ASC
create index idx_jobs_status_start on public.jobs(status, start_time);

-- spatial index for "jobs near me" — uses earthdistance extension
create index idx_jobs_location on public.jobs
  using gist(ll_to_earth(location_lat, location_lng));

create table public.applications (
  id              uuid        primary key default gen_random_uuid(),
  job_id          uuid        not null references public.jobs(id) on delete cascade,
  sitter_id       uuid        not null
                              references public.sitter_profiles(user_id)
                              on delete cascade,
  cover_message   text,
  status          public.application_status not null default 'pending',
  applied_at      timestamptz not null default now(),
  unique (job_id, sitter_id)
  -- one application per (job, sitter) pair — enforced at DB level
);

create index idx_applications_job_id on public.applications(job_id);
create index idx_applications_sitter_id on public.applications(sitter_id);

create table public.hires (
  id           uuid        primary key default gen_random_uuid(),
  job_id       uuid        unique not null
                           references public.jobs(id) on delete cascade,
  -- unique: one hire per job
  sitter_id    uuid        not null
                           references public.sitter_profiles(user_id),
  hourly_rate  numeric(10,2) not null,
  -- SNAPSHOT at hire time — changing age_wage_tiers later must not alter past earnings
  hired_at     timestamptz not null default now()
);

create index idx_hires_sitter_id on public.hires(sitter_id);
```

### Migration 7 — Time Tracking and Wages

```sql
-- 20260501000007_time_wages.sql

-- Admin-configurable age-based wage tiers
create table public.age_wage_tiers (
  id              serial      primary key,
  min_age         int         not null check (min_age >= 0),
  max_age         int         not null check (max_age <= 100),
  hourly_rate     numeric(10,2) not null check (hourly_rate > 0),
  effective_from  date        not null default current_date,
  created_by      uuid        references public.users(id),
  constraint chk_age_range check (max_age >= min_age),
  unique (min_age, max_age, effective_from)
);

-- Default seed values (inserted in seed.sql):
-- (11, 12, 8.00, '2026-01-01')
-- (13, 14, 10.00, '2026-01-01')
-- (15, 16, 12.00, '2026-01-01')
-- (17, 17, 14.00, '2026-01-01')

create table public.time_entries (
  id                uuid        primary key default gen_random_uuid(),
  hire_id           uuid        not null references public.hires(id)
                                on delete cascade,
  sitter_id         uuid        not null
                                references public.sitter_profiles(user_id),
  clock_in_at       timestamptz not null,
  clock_out_at      timestamptz,
  clock_in_lat      double precision,
  clock_in_lng      double precision,
  clock_out_lat     double precision,
  clock_out_lng     double precision,
  geofence_passed   boolean,
  -- true = within radius, false = outside but allowed (soft-warn default)
  computed_minutes  int,
  -- filled on clock_out by server RPC
  computed_wage     numeric(12,2),
  -- filled on clock_out by server RPC; numeric not float
  created_at        timestamptz not null default now()
);

create index idx_time_entries_hire_id on public.time_entries(hire_id);
create index idx_time_entries_sitter_id on public.time_entries(sitter_id);

-- A sitter must have AT MOST one open shift at any time. Enforce this at the
-- database level with a partial unique index — this is impossible to defeat
-- via concurrent RPC calls, race conditions, or buggy clients. Without it,
-- two simultaneous clock_in requests can create two open rows because the
-- "no open entry" SELECT and the INSERT are not atomic in PL/pgSQL by default.
create unique index uq_one_open_time_entry
  on public.time_entries(sitter_id)
  where clock_out_at is null;

-- System configuration table: key-value store for platform-wide settings.
-- VALUE is jsonb. ALL seeds must be valid JSON literals — booleans as
-- 'true'::jsonb/'false'::jsonb, strings as '"value"'::jsonb (note the inner
-- double quotes), numbers as '42'::jsonb. Reading code MUST go through the
-- cfg_bool() / cfg_text() / cfg_int() helpers (defined in 20260501000015_helpers.sql)
-- — never cast .value::text::boolean directly because raw jsonb 'true' renders
-- as the string 'true' but jsonb '"true"' would also cast to "true" silently.
create table public.system_config (
  key        text        primary key,
  value      jsonb       not null,
  updated_at timestamptz not null default now(),
  updated_by uuid        references public.users(id)
);
```

The full seed lives in `seed.sql` — values shown using JSON-literal syntax:

```sql
-- supabase/seed.sql excerpt
insert into public.system_config (key, value) values
  ('min_sitter_age',             '11'::jsonb),
  ('max_sitter_age',             '17'::jsonb),
  ('default_geofence_radius_m',  '150'::jsonb),
  ('geofence_hard_block',        'false'::jsonb),
  ('platform_fee_pct',           '0'::jsonb),
  -- Block 5 — pluggable provider flags. 'mock' => Edge Function logs only;
  -- 'live'  => Edge Function calls the real provider with the corresponding secret.
  ('fcm_provider',               '"mock"'::jsonb),
  ('email_provider',             '"mock"'::jsonb),
  ('email_from',                 '"StarSitters <noreply@starsitters.app>"'::jsonb)
on conflict (key) do nothing;
```

### Migration 8 — Chat

```sql
-- 20260501000008_chat.sql

create table public.conversations (
  id          uuid        primary key default gen_random_uuid(),
  job_id      uuid        not null references public.jobs(id) on delete cascade,
  family_id   uuid        not null references public.family_profiles(user_id),
  sitter_id   uuid        not null references public.sitter_profiles(user_id),
  created_at  timestamptz not null default now(),
  unique (job_id, sitter_id)
  -- one conversation per (job, sitter) pair
);

create index idx_conversations_family_id on public.conversations(family_id);
create index idx_conversations_sitter_id on public.conversations(sitter_id);

create table public.messages (
  id               uuid        primary key default gen_random_uuid(),
  conversation_id  uuid        not null
                               references public.conversations(id) on delete cascade,
  sender_id        uuid        not null references public.users(id),
  body             text        not null check (char_length(body) between 1 and 4000),
  read_at          timestamptz,
  -- null = unread
  created_at       timestamptz not null default now()
);

-- Most common query: "give me the last N messages in this conversation"
create index idx_messages_conv_created
  on public.messages(conversation_id, created_at desc);
```

### Migration 9 — Wallet and Ledger

```sql
-- 20260501000009_wallet.sql

create table public.wallets (
  sitter_id          uuid        primary key
                                 references public.sitter_profiles(user_id)
                                 on delete cascade,
  available_balance  numeric(12,2) not null default 0
                                   check (available_balance >= 0),
  pending_balance    numeric(12,2) not null default 0
                                   check (pending_balance >= 0),
  lifetime_earnings  numeric(12,2) not null default 0
                                   check (lifetime_earnings >= 0),
  updated_at         timestamptz  not null default now()
);

create trigger trg_wallets_updated_at
  before update on public.wallets
  for each row execute function public.touch_updated_at();

create table public.ledger_entries (
  id               uuid        primary key default gen_random_uuid(),
  sitter_id        uuid        not null
                               references public.wallets(sitter_id) on delete cascade,
  type             public.ledger_type not null,
  amount           numeric(12,2) not null,
  -- positive = earning/credit; negative = withdrawal/debit
  reference_type   text,
  -- 'time_entry' | 'withdrawal_request' | 'adjustment'
  reference_id     uuid,
  balance_after    numeric(12,2) not null,
  -- snapshot of available_balance after this entry
  created_at       timestamptz not null default now()
);

create index idx_ledger_sitter_id_created
  on public.ledger_entries(sitter_id, created_at desc);

create table public.withdrawal_requests (
  id            uuid        primary key default gen_random_uuid(),
  sitter_id     uuid        not null
                            references public.wallets(sitter_id) on delete cascade,
  amount        numeric(12,2) not null check (amount > 0),
  method        text        not null,
  -- 'bank_transfer' | 'cash' | 'easypaisa' | 'jazzcash'
  account_info  jsonb       default '{}',
  -- encrypted/masked bank details
  status        text        not null default 'pending',
  -- 'pending' | 'approved' | 'paid' | 'rejected'
  requested_at  timestamptz not null default now(),
  paid_at       timestamptz,
  paid_by       uuid        references public.users(id)
);

create index idx_withdrawal_sitter_id on public.withdrawal_requests(sitter_id);
create index idx_withdrawal_status on public.withdrawal_requests(status);
```

### Migration 10 — Notifications

```sql
-- 20260501000010_notifications.sql

create table public.devices (
  id           uuid        primary key default gen_random_uuid(),
  user_id      uuid        not null references public.users(id) on delete cascade,
  fcm_token    text        not null,
  platform     text        not null default 'android',
  -- 'android' | 'ios'
  last_seen_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);

create index idx_devices_user_id on public.devices(user_id);

create table public.notifications (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references public.users(id) on delete cascade,
  type        text        not null,
  -- 'new_application' | 'hired' | 'new_message' | 'bg_check_result' |
  -- 'cert_result' | 'withdrawal_paid'
  title       text,
  body        text,
  data        jsonb       default '{}',
  read_at     timestamptz,
  created_at  timestamptz not null default now()
);

create index idx_notifications_user_id_created
  on public.notifications(user_id, created_at desc);
```

### Migration 11 — Admin and Audit

```sql
-- 20260501000011_admin_audit.sql

create table public.admin_users (
  id           uuid      primary key references public.users(id) on delete cascade,
  permissions  text[]    not null default '{}',
  -- future: ['verify_bg_checks', 'manage_wages', 'view_reports']
  created_at   timestamptz not null default now()
);

create table public.audit_logs (
  id           uuid        primary key default gen_random_uuid(),
  actor_id     uuid        references public.users(id) on delete set null,
  action       text        not null,
  -- 'bg_check_approved' | 'cert_approved' | 'withdrawal_paid' | 'hire_created' etc.
  entity_type  text,
  -- table name: 'background_checks' | 'certifications' | 'hires' etc.
  entity_id    uuid,
  before_state jsonb,
  after_state  jsonb,
  ip_address   inet,
  user_agent   text,
  created_at   timestamptz not null default now()
);

-- audit_logs is append-only: no updates, no deletes
-- enforced by RLS (no UPDATE or DELETE policy for any role)
create index idx_audit_logs_actor_id on public.audit_logs(actor_id);
create index idx_audit_logs_entity on public.audit_logs(entity_type, entity_id);
create index idx_audit_logs_created on public.audit_logs(created_at desc);
```

### Migration 12 — Shared Helpers (admin_only, write_audit_log, cfg_*)

These helpers are referenced everywhere — by RLS policies, by every admin RPC,
by the Edge Functions when they read feature flags. Defining them in one place
keeps the contract single-source.

```sql
-- 20260501000015_helpers.sql

-- ============================================================
-- admin_only(): raises if the current JWT does not belong to an admin.
-- Use as the first statement in every admin RPC: `perform admin_only();`.
-- Also callable from RLS policies via `(public.admin_only_bool())` if needed,
-- though the recommended pattern is for admin operations to go through
-- SECURITY DEFINER RPCs and bypass RLS entirely.
-- ============================================================
create or replace function public.admin_only()
returns void
language plpgsql security definer
set search_path = public as $$
begin
  if not exists (
    select 1 from public.admin_users where id = auth.uid()
  ) then
    raise exception 'unauthorized: admin role required'
      using errcode = '42501';   -- insufficient_privilege
  end if;
end;
$$;

-- Boolean variant for use inside RLS USING/WITH CHECK clauses.
create or replace function public.admin_only_bool()
returns boolean
language sql stable security definer
set search_path = public as $$
  select exists (select 1 from public.admin_users where id = auth.uid());
$$;

-- ============================================================
-- write_audit_log(): single helper for inserting into audit_logs.
-- Captures actor_id from auth.uid(), supports before/after state,
-- accepts arbitrary entity references. Called by every admin RPC.
-- ============================================================
create or replace function public.write_audit_log(
  p_action       text,
  p_entity_type  text,
  p_entity_id    uuid,
  p_before       jsonb default null,
  p_after        jsonb default null
)
returns void
language plpgsql security definer
set search_path = public as $$
begin
  insert into public.audit_logs (
    actor_id, action, entity_type, entity_id, before_state, after_state, created_at
  ) values (
    auth.uid(), p_action, p_entity_type, p_entity_id, p_before, p_after, now()
  );
end;
$$;

-- ============================================================
-- system_config readers. ALWAYS use these instead of selecting .value directly.
-- jsonb has type-safe extraction operators that the helpers wrap cleanly.
-- ============================================================
create or replace function public.cfg_bool(p_key text, p_default boolean default false)
returns boolean language sql stable as $$
  select coalesce((select value::boolean from public.system_config where key = p_key), p_default);
$$;

create or replace function public.cfg_text(p_key text, p_default text default '')
returns text language sql stable as $$
  -- ->> strips JSON quotes; cast to text for consistency
  select coalesce((select value #>> '{}' from public.system_config where key = p_key), p_default);
$$;

create or replace function public.cfg_int(p_key text, p_default int default 0)
returns int language sql stable as $$
  select coalesce((select (value)::int from public.system_config where key = p_key), p_default);
$$;
```

### Migration 13 — Immutability Triggers (role + sitter activation locks)

RLS policies say "a user may UPDATE their own row" — but Postgres RLS
operates at row-level, not column-level. Without these triggers, a malicious
client could send `update users set role = 'admin' where id = auth.uid()`
and RLS would happily approve it. These triggers are the column-level
enforcement that makes the security claims in §6 actually true.

```sql
-- 20260501000016_immutability_triggers.sql

-- ============================================================
-- Shared helper: detects the transaction-local "bypass" GUC that
-- SECURITY DEFINER server functions set when they need to write privileged
-- columns (admin_* RPCs, confirm_guardian_consent). The GUC is always
-- transaction-scoped (`set_config(..., is_local => true)`) so it cannot leak.
-- ============================================================
create or replace function public.tx_immutability_bypass()
returns boolean
language sql stable as $$
  -- current_setting(..., true) returns NULL if the GUC is not set,
  -- avoiding the "unrecognized configuration parameter" error.
  select coalesce(current_setting('app.bypass_immutability', true), 'false') = 'true';
$$;

-- ============================================================
-- Block any non-admin from changing their own role.
-- Bypass only when an admin RPC explicitly sets app.bypass_immutability.
-- ============================================================
create or replace function public.fn_prevent_role_change()
returns trigger language plpgsql as $$
begin
  if old.role is distinct from new.role
     and not public.tx_immutability_bypass()
     and not public.admin_only_bool()
  then
    raise exception 'role is immutable for non-admins'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger trg_users_role_immutable
  before update on public.users
  for each row execute function public.fn_prevent_role_change();

-- ============================================================
-- Block sitters from self-activating. Only admins (or server functions
-- that set the bypass GUC, like confirm_guardian_consent) may flip is_active
-- or guardian_consent_status. The legitimate flow is: sitter submits cert →
-- admin approves → admin_approve_certification() RPC flips is_active.
-- ============================================================
create or replace function public.fn_sitter_lock_admin_fields()
returns trigger language plpgsql as $$
begin
  if not public.tx_immutability_bypass() and not public.admin_only_bool() then
    if old.is_active is distinct from new.is_active then
      raise exception 'is_active is admin-only' using errcode = '42501';
    end if;
    if old.guardian_consent_status is distinct from new.guardian_consent_status then
      raise exception 'guardian_consent_status is admin-only' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_sitter_lock_admin_fields
  before update on public.sitter_profiles
  for each row execute function public.fn_sitter_lock_admin_fields();

-- Same protection on family_profiles.bg_check_status (column added in §31.6).
create or replace function public.fn_family_lock_admin_fields()
returns trigger language plpgsql as $$
begin
  if not public.tx_immutability_bypass() and not public.admin_only_bool() then
    if old.bg_check_status is distinct from new.bg_check_status then
      raise exception 'bg_check_status is admin-only' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_family_lock_admin_fields
  before update on public.family_profiles
  for each row execute function public.fn_family_lock_admin_fields();
```

> Note on `family_profiles.bg_check_status`: the column does not exist in the
> base table definition (Migration 4) — it is added in §31.6 Block 8 for the
> admin app. The trigger above is created **after** the §31 migration runs.
> If you stage Block 8 separately, also stage this trigger separately. The
> repo migration order is: extensions → enums → users → family → sitter →
> marketplace → time/wages → chat → wallet → notifications → admin_audit →
> helpers (12) → admin_schema (§31.6) → immutability_triggers (13) → RLS →
> RPCs → admin_rpcs.

### Migration 14 — Sitter Aggregate Trigger (replaces stale §31 fn_update_sitter_totals)

```sql
-- 20260501000014_sitter_aggregates.sql

-- After every UPDATE that fills clock_out_at + computed_minutes + computed_wage,
-- bump sitter_profiles.total_minutes_worked and total_earnings. This is what
-- the admin "Babysitters" page reads instead of doing a 1M-row aggregate every
-- request. INSERT-time the row has no clock_out, so we skip — only UPDATE.
create or replace function public.fn_update_sitter_totals()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  -- only when this UPDATE just *closed* the entry
  if old.clock_out_at is null
     and new.clock_out_at is not null
     and new.computed_minutes is not null
     and new.computed_wage is not null
  then
    update public.sitter_profiles
       set total_minutes_worked = total_minutes_worked + new.computed_minutes,
           total_earnings       = total_earnings + new.computed_wage,
           updated_at           = now()
     where user_id = new.sitter_id;
  end if;
  return new;
end;
$$;

create trigger trg_update_sitter_totals
  after update of clock_out_at, computed_minutes, computed_wage
  on public.time_entries
  for each row execute function public.fn_update_sitter_totals();
```

### Triggers Summary Table

| Trigger | Fires on | Purpose | Migration |
|---|---|---|---|
| `trg_users_updated_at` | BEFORE UPDATE on `users` | Stamp `updated_at` | 3 |
| `trg_on_auth_user_created` | AFTER INSERT on `auth.users` | Mirror auth row → public.users | 3 |
| `trg_sitter_profiles_updated_at` | BEFORE UPDATE on `sitter_profiles` | Stamp `updated_at` | 5 |
| `trg_create_wallet_for_sitter` | AFTER INSERT on `sitter_profiles` | Auto-create wallet row | 5 |
| `trg_users_role_immutable` | BEFORE UPDATE on `users` | Block role change unless admin | 13 |
| `trg_sitter_lock_admin_fields` | BEFORE UPDATE on `sitter_profiles` | Block self-activation | 13 |
| `trg_family_lock_admin_fields` | BEFORE UPDATE on `family_profiles` | Block self bg-check approval | 13 |
| `trg_update_sitter_totals` | AFTER UPDATE on `time_entries` | Maintain denorm aggregates | 14 |
| `trg_wallets_updated_at` | BEFORE UPDATE on `wallets` | Stamp `updated_at` | 9 |

### Auth Configuration (must-do checklist)

These settings live in the Supabase Dashboard, **not** in migrations. Document
once, set once, never change without bumping a deployment doc.

| Setting | Required value | Where | Why |
|---|---|---|---|
| **Confirm email** | **ON** | Authentication → Providers → Email | Without this, an attacker can sign up as `victim@example.com` without owning the inbox, then access the victim's account once they actually sign up |
| **Email rate limits** | Default (Supabase auto-throttles per-IP) | Authentication → Rate Limits | Supabase Auth applies per-IP/per-route throttling; documented at supabase.com/docs/guides/auth/rate-limits — these are not configurable per project |
| **Session length** | 1 hour access token + 7-day refresh | Authentication → Settings → JWT | Mobile apps refresh silently; web admin re-prompts every 7 days |
| **Google OAuth redirect URI** | `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback` | Google Cloud Console → OAuth 2.0 Client → Authorized redirect URIs | Must match Supabase's callback exactly; case-sensitive; no trailing slash |
| **Google OAuth Authorized Origins** | `https://YOUR_PROJECT_REF.supabase.co` | Google Cloud Console → OAuth 2.0 Client → Authorized JavaScript origins | Required for the OAuth pop-up flow used by the admin web app |
| **Apple Sign-In** | Deferred until Apple Developer account arrives | Authentication → Providers → Apple | v0.2 — see §27 |

#### Password reset and Auth transactional email (built-in mailer vs SMTP)

Password reset, signup confirmation, and magic links are sent by **Supabase Auth (GoTrue)** when clients call APIs such as `resetPasswordForEmail`. This path is **separate** from the `send_guardian_consent_email` Edge Function (`system_config.email_provider` / Resend) in §8.2 — that function only sends guardian consent mail. Do **not** implement a second password-reset API in Postgres or Edge unless you have a rare compliance reason; use Auth’s flow end-to-end.

| Transport | Best for | Security of reset links | Deliverability / operations |
|---|---|---|---|
| **Supabase built-in mailer** | Local dev (emails captured by **Inbucket** when `[inbucket] enabled = true` in `supabase/config.toml`), demos, very low volume hosted tests | GoTrue issues short-lived signed links either way; rate limits apply | Shared sending infrastructure; stricter caps; less control over SPF/DKIM/DMARC and bounce monitoring on *your* domain |
| **Custom SMTP** (Dashboard → Authentication → **SMTP** / custom provider) | **Production** — recommended in this spec | **Same** link signing and token handling as built-in; attack surface for the *credential exchange* is still Supabase Auth | You send from your domain with proper **SPF, DKIM, DMARC**; better inbox placement, ESP dashboards, rotation of SMTP secrets in the Dashboard (never committed to git) |

**Conclusion:** For **critical production** use, **custom SMTP on your own domain** is the more robust end-to-end choice (deliverability, branding, compliance). It does not replace Supabase’s token logic — it only changes *who delivers the envelope*. The built-in mailer remains acceptable for development and early MVPs.

**Outside this repo (hosted Supabase — you must do manually):**

1. **Authentication → URL configuration:** Set **Site URL** to your production admin (or app) origin. Under **Redirect URLs**, add every exact URL prefix your clients use for recovery, including `https://<your-admin-host>/reset-password` and local dev URLs if you test against the hosted project.
2. **Authentication → Emails → SMTP:** Enable custom SMTP and fill host, port, username, password, and **Sender email** (must be allowed by your provider).
3. **Authentication → Email templates:** Review “Reset password” template; the `{{ .ConfirmationURL }}` must point through Supabase’s verify endpoint (default templates do this).
4. **Confirm email** row in the table above: leave **ON** for production signups; coordinate with `enable_confirmations` behavior on local CLI config (`supabase/config.toml` may use `false` for local convenience — do not copy that to production).

**Local dev:** Run `supabase start`, then `supabase status` — open the **Inbucket** URL and trigger `resetPasswordForEmail` from the admin app; messages appear in Inbucket, not a real inbox.

---

## 6. Row-Level Security — All Policies

Every table has RLS enabled. Default is DENY ALL. Explicit ALLOW policies are listed here.

```sql
-- 20260501000012_rls_policies.sql

-- ============================================================
-- Enable RLS on all tables
-- ============================================================
alter table public.users enable row level security;
alter table public.family_profiles enable row level security;
alter table public.children enable row level security;
alter table public.background_checks enable row level security;
alter table public.sitter_profiles enable row level security;
alter table public.guardian_consents enable row level security;
alter table public.certifications enable row level security;
alter table public.jobs enable row level security;
alter table public.applications enable row level security;
alter table public.hires enable row level security;
alter table public.age_wage_tiers enable row level security;
alter table public.time_entries enable row level security;
alter table public.system_config enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.wallets enable row level security;
alter table public.ledger_entries enable row level security;
alter table public.withdrawal_requests enable row level security;
alter table public.devices enable row level security;
alter table public.notifications enable row level security;
alter table public.admin_users enable row level security;
alter table public.audit_logs enable row level security;

-- ============================================================
-- Helper functions used by RLS policies below.
--
-- current_user_role() — pulls the row from public.users for the current JWT.
-- is_admin()          — alias for admin_only_bool() defined in Migration 12;
--                       kept for backward-compatibility because the rest of
--                       this file's RLS policies were written before the
--                       admin_only() consolidation. Both helpers query the
--                       same table (public.admin_users) so they always agree.
--                       New code should call admin_only_bool() directly.
-- ============================================================
create or replace function public.current_user_role()
returns public.user_role language sql stable security definer
set search_path = public as $$
  select role from public.users where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = public as $$
  -- Single source of truth: admin_users membership.
  -- Equivalent to public.admin_only_bool().
  select exists (
    select 1 from public.admin_users where id = auth.uid()
  );
$$;

-- ============================================================
-- USERS
-- ============================================================
-- Anyone can read their own row
create policy "users: select own"
  on public.users for select
  using (id = auth.uid());

-- Admins can read all users
create policy "users: admin select all"
  on public.users for select
  using (public.is_admin());

-- Users may update their own row, but the role column is locked at the
-- trigger level (Migration 13: trg_users_role_immutable) and the email
-- column is owned by Supabase Auth — clients should call auth.updateUser()
-- to change email, never write directly to public.users.email.
--
-- Defense in depth: even though the trigger blocks role escalation, we keep
-- the RLS policy narrow by requiring id = auth.uid() (no row hijack) and
-- documenting the safe-write columns here.
--
-- Safe to write from a client: full_name, phone, avatar_url
-- Locked at DB level: role (trigger), email (managed by Auth), updated_at (trigger)
create policy "users: update own"
  on public.users for update
  using (id = auth.uid())
  with check (id = auth.uid());

-- ============================================================
-- FAMILY PROFILES
-- ============================================================
create policy "family_profiles: select own"
  on public.family_profiles for select
  using (user_id = auth.uid());

-- Sitters can see limited family info for jobs they applied to
create policy "family_profiles: sitter sees relevant families"
  on public.family_profiles for select
  using (
    public.current_user_role() = 'sitter'
    and exists (
      select 1 from public.jobs j
      join public.applications a on a.job_id = j.id
      where j.family_id = family_profiles.user_id
        and a.sitter_id = auth.uid()
    )
  );

create policy "family_profiles: admin select all"
  on public.family_profiles for select
  using (public.is_admin());

create policy "family_profiles: insert own"
  on public.family_profiles for insert
  with check (user_id = auth.uid());

-- Families may update their own profile row. The bg_check_status column
-- (added in §31.6) is locked at the trigger level by trg_family_lock_admin_fields
-- (Migration 13) — only admin RPCs may flip it.
--
-- Safe for a family to write: address fields, contact fields.
-- Admin-only: bg_check_status.
create policy "family_profiles: update own"
  on public.family_profiles for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ============================================================
-- CHILDREN
-- ============================================================
create policy "children: family select own"
  on public.children for select
  using (
    family_id = auth.uid()
  );

create policy "children: admin select all"
  on public.children for select
  using (public.is_admin());

create policy "children: family insert"
  on public.children for insert
  with check (family_id = auth.uid());

create policy "children: family update own"
  on public.children for update
  using (family_id = auth.uid())
  with check (family_id = auth.uid());

create policy "children: family delete own"
  on public.children for delete
  using (family_id = auth.uid());

-- ============================================================
-- BACKGROUND CHECKS
-- ============================================================
create policy "bg_checks: family select own"
  on public.background_checks for select
  using (family_id = auth.uid());

create policy "bg_checks: admin select all"
  on public.background_checks for select
  using (public.is_admin());

create policy "bg_checks: family insert own"
  on public.background_checks for insert
  with check (family_id = auth.uid());

-- Admin updates via admin_approve_bg_check() RPC only — direct update denied
-- No update policy for non-admins
create policy "bg_checks: admin update"
  on public.background_checks for update
  using (public.is_admin());

-- ============================================================
-- SITTER PROFILES
-- ============================================================
create policy "sitter_profiles: select own"
  on public.sitter_profiles for select
  using (user_id = auth.uid());

-- Families can see public sitter data for active sitters
create policy "sitter_profiles: family sees active sitters"
  on public.sitter_profiles for select
  using (
    public.current_user_role() = 'family'
    and is_active = true
  );

create policy "sitter_profiles: admin select all"
  on public.sitter_profiles for select
  using (public.is_admin());

create policy "sitter_profiles: insert own"
  on public.sitter_profiles for insert
  with check (user_id = auth.uid());

-- Sitters may update their own profile row, BUT the privileged columns
-- (is_active, guardian_consent_status, total_minutes_worked, total_earnings)
-- are locked at the trigger level by trg_sitter_lock_admin_fields (Migration 13).
-- That trigger calls admin_only_bool() and raises 42501 if any of those
-- columns change for a non-admin caller. So this RLS policy can stay broad —
-- the trigger is the column-level gate.
--
-- Safe for a sitter to write: bio, date_of_birth (within age constraint).
-- Admin-only (via admin_*  RPCs that bypass the trigger because they run
-- with admin_only_bool() = true): is_active, guardian_consent_status,
-- total_minutes_worked, total_earnings (the last two are also written by
-- the fn_update_sitter_totals trigger, which is SECURITY DEFINER).
create policy "sitter_profiles: update own"
  on public.sitter_profiles for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "sitter_profiles: admin update"
  on public.sitter_profiles for update
  using (public.is_admin());

-- ============================================================
-- GUARDIAN CONSENTS
-- ============================================================
-- Sitter can see their own consent record but NOT the consent_token
-- (token is in the row but we never SELECT it in the Flutter query — rely on column-level)
create policy "guardian_consents: sitter select own"
  on public.guardian_consents for select
  using (sitter_id = auth.uid());

create policy "guardian_consents: admin select all"
  on public.guardian_consents for select
  using (public.is_admin());

create policy "guardian_consents: sitter insert own"
  on public.guardian_consents for insert
  with check (sitter_id = auth.uid());

-- Consent update happens via Edge Function with service_role key (bypasses RLS)
-- No client update policy

-- ============================================================
-- CERTIFICATIONS
-- ============================================================
create policy "certifications: sitter select own"
  on public.certifications for select
  using (sitter_id = auth.uid());

-- Families can see approved certs of sitters who applied to their jobs
create policy "certifications: family sees approved certs"
  on public.certifications for select
  using (
    public.current_user_role() = 'family'
    and status = 'approved'
    and exists (
      select 1 from public.applications a
      join public.jobs j on j.id = a.job_id
      where a.sitter_id = certifications.sitter_id
        and j.family_id = auth.uid()
    )
  );

create policy "certifications: admin select all"
  on public.certifications for select
  using (public.is_admin());

create policy "certifications: sitter insert own"
  on public.certifications for insert
  with check (sitter_id = auth.uid());

create policy "certifications: admin update"
  on public.certifications for update
  using (public.is_admin());

-- ============================================================
-- JOBS
-- ============================================================
create policy "jobs: family select own"
  on public.jobs for select
  using (family_id = auth.uid());

-- Sitters see open jobs from approved families only
create policy "jobs: sitter sees open jobs"
  on public.jobs for select
  using (
    public.current_user_role() = 'sitter'
    and status = 'open'
    and exists (
      select 1 from public.family_profiles fp
      where fp.user_id = jobs.family_id
        and fp.bg_check_status = 'approved'
    )
  );

create policy "jobs: admin select all"
  on public.jobs for select
  using (public.is_admin());

-- Family creates jobs only when bg_check is approved
create policy "jobs: family insert"
  on public.jobs for insert
  with check (
    family_id = auth.uid()
    and exists (
      select 1 from public.family_profiles fp
      where fp.user_id = auth.uid()
        and fp.bg_check_status = 'approved'
    )
  );

create policy "jobs: family update own"
  on public.jobs for update
  using (family_id = auth.uid())
  with check (family_id = auth.uid());

-- ============================================================
-- APPLICATIONS
-- ============================================================
create policy "applications: sitter select own"
  on public.applications for select
  using (sitter_id = auth.uid());

create policy "applications: family sees own job applications"
  on public.applications for select
  using (
    exists (
      select 1 from public.jobs j
      where j.id = applications.job_id
        and j.family_id = auth.uid()
    )
  );

create policy "applications: admin select all"
  on public.applications for select
  using (public.is_admin());

-- Applications are created only via create_application() RPC — direct insert denied
-- (The RPC runs SECURITY DEFINER and validates sitter is_active)

-- ============================================================
-- HIRES
-- ============================================================
create policy "hires: family sees own job hires"
  on public.hires for select
  using (
    exists (
      select 1 from public.jobs j
      where j.id = hires.job_id
        and j.family_id = auth.uid()
    )
  );

create policy "hires: sitter sees own hires"
  on public.hires for select
  using (sitter_id = auth.uid());

create policy "hires: admin select all"
  on public.hires for select
  using (public.is_admin());

-- Hires created only via create_hire() RPC — direct insert denied

-- ============================================================
-- AGE WAGE TIERS
-- ============================================================
-- All authenticated users can read wage tiers (used for wage preview)
create policy "age_wage_tiers: authenticated read"
  on public.age_wage_tiers for select
  using (auth.uid() is not null);

-- Only admins can insert/update
create policy "age_wage_tiers: admin write"
  on public.age_wage_tiers for all
  using (public.is_admin())
  with check (public.is_admin());

-- ============================================================
-- TIME ENTRIES
-- ============================================================
create policy "time_entries: sitter select own"
  on public.time_entries for select
  using (sitter_id = auth.uid());

create policy "time_entries: family sees entries for their hires"
  on public.time_entries for select
  using (
    exists (
      select 1 from public.hires h
      join public.jobs j on j.id = h.job_id
      where h.id = time_entries.hire_id
        and j.family_id = auth.uid()
    )
  );

create policy "time_entries: admin select all"
  on public.time_entries for select
  using (public.is_admin());

-- No direct inserts/updates by clients — all via clock_in / clock_out RPCs

-- ============================================================
-- SYSTEM CONFIG
-- ============================================================
-- All authenticated users can read config (some values like min wage rate are public)
create policy "system_config: authenticated read"
  on public.system_config for select
  using (auth.uid() is not null);

-- Only admins can write
create policy "system_config: admin write"
  on public.system_config for all
  using (public.is_admin())
  with check (public.is_admin());

-- ============================================================
-- CONVERSATIONS
-- ============================================================
create policy "conversations: participants select"
  on public.conversations for select
  using (
    family_id = auth.uid()
    or sitter_id = auth.uid()
  );

create policy "conversations: admin select all"
  on public.conversations for select
  using (public.is_admin());

-- Conversations created only via create_hire() RPC — direct insert denied

-- ============================================================
-- MESSAGES
-- ============================================================
create policy "messages: participants select"
  on public.messages for select
  using (
    exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.family_id = auth.uid() or c.sitter_id = auth.uid())
    )
  );

create policy "messages: participants insert"
  on public.messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.family_id = auth.uid() or c.sitter_id = auth.uid())
    )
  );

-- Messages are never updated or deleted (immutable)

-- ============================================================
-- WALLETS
-- ============================================================
create policy "wallets: sitter select own"
  on public.wallets for select
  using (sitter_id = auth.uid());

create policy "wallets: admin select all"
  on public.wallets for select
  using (public.is_admin());

-- No client writes to wallets — updated only by clock_out and admin_pay_withdrawal RPCs

-- ============================================================
-- LEDGER ENTRIES
-- ============================================================
create policy "ledger_entries: sitter select own"
  on public.ledger_entries for select
  using (sitter_id = auth.uid());

create policy "ledger_entries: admin select all"
  on public.ledger_entries for select
  using (public.is_admin());

-- Ledger entries are append-only, written only by server RPCs

-- ============================================================
-- WITHDRAWAL REQUESTS
-- ============================================================
create policy "withdrawal_requests: sitter select own"
  on public.withdrawal_requests for select
  using (sitter_id = auth.uid());

create policy "withdrawal_requests: admin select all"
  on public.withdrawal_requests for select
  using (public.is_admin());

-- Sitter creates request via request_withdrawal() RPC
-- Admin marks paid via admin_pay_withdrawal() RPC

-- ============================================================
-- DEVICES (FCM tokens)
-- ============================================================
create policy "devices: user select own"
  on public.devices for select
  using (user_id = auth.uid());

create policy "devices: user upsert own"
  on public.devices for insert
  with check (user_id = auth.uid());

create policy "devices: user update own"
  on public.devices for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "devices: user delete own"
  on public.devices for delete
  using (user_id = auth.uid());

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
create policy "notifications: user select own"
  on public.notifications for select
  using (user_id = auth.uid());

-- Mark as read — users can update read_at on their own notifications only
create policy "notifications: user update own read_at"
  on public.notifications for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Notifications are created only by server (Edge Functions with service_role)

-- ============================================================
-- ADMIN USERS
-- ============================================================
create policy "admin_users: admin select all"
  on public.admin_users for select
  using (public.is_admin());

-- ============================================================
-- AUDIT LOGS
-- ============================================================
create policy "audit_logs: admin select all"
  on public.audit_logs for select
  using (public.is_admin());

-- audit_logs: no update, no delete for anyone (append-only enforced by no policies)
```

### Why admin operations don't violate RLS

Reading this section, you may notice there are very few "admin can update X"
policies. That is intentional. **Admin writes do not flow through the RLS
layer at all.**

The pattern is:

1. Admin web app calls a `public.admin_*()` RPC via the Supabase client.
2. The RPC is declared `SECURITY DEFINER` — Postgres runs it with the
   privileges of the function's owner (the `postgres` role), not the caller's
   role. RLS does not apply to the function body's queries.
3. The first line of every admin RPC is `perform admin_only();` (Migration 12).
   That helper queries `public.admin_users` for `auth.uid()` and raises 42501
   if the caller is not in the table.
4. The RPC writes are atomic — multiple table updates inside a single
   transaction, with `write_audit_log()` capturing the action.

This means:
- A misconfigured RLS policy cannot leak admin power to a non-admin (RLS is
  not the gate; `admin_only()` is).
- A bug in the admin web app's UI cannot bypass the audit log (the RPC writes
  it unconditionally).
- The list of admin operations is exactly the list of `admin_*` RPCs in §7
  and §31. Anything not on that list cannot be done by an admin from a
  client at all.

The same principle protects the Edge Functions: when an Edge Function uses
the service role key, it bypasses RLS entirely — so we never grant client-side
write policies for tables Edge Functions should own (notifications,
guardian_consents post-confirmation, time_entries clock-out totals, etc.).

---

## 7. Server-Side RPCs — Full Bodies

All RPCs use `SECURITY DEFINER` with explicit `set search_path = public` to prevent search_path injection. All validate `auth.uid()` at the top. All write to `audit_logs`. All run as a single transaction.

```sql
-- 20260501000013_rpcs.sql

-- ============================================================
-- 1. create_application(job_id, cover_message)
-- Called by: Sitter, from JobDetailScreen
-- ============================================================
create or replace function public.create_application(
  p_job_id        uuid,
  p_cover_message text default null
)
returns public.applications
language plpgsql security definer
set search_path = public as $$
declare
  v_sitter_id uuid := auth.uid();
  v_app       public.applications;
  v_is_active boolean;
begin
  -- 1. Validate sitter is active (guardian consent + admin approved)
  select is_active into v_is_active
    from public.sitter_profiles where user_id = v_sitter_id;

  if not found then
    raise exception 'sitter profile not found';
  end if;
  if not v_is_active then
    raise exception 'your profile must be approved before applying to jobs';
  end if;

  -- 2. Validate job is open
  if not exists (
    select 1 from public.jobs
    where id = p_job_id and status = 'open'
  ) then
    raise exception 'job is not open for applications';
  end if;

  -- 3. Insert application
  insert into public.applications (job_id, sitter_id, cover_message)
  values (p_job_id, v_sitter_id, p_cover_message)
  returning * into v_app;

  -- 4. Audit log
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_sitter_id, 'application_created', 'applications', v_app.id,
    to_jsonb(v_app)
  );

  return v_app;
end;
$$;

-- ============================================================
-- 2. withdraw_application(application_id)
-- Called by: Sitter
-- ============================================================
create or replace function public.withdraw_application(
  p_application_id uuid
)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_sitter_id uuid := auth.uid();
begin
  update public.applications
     set status = 'withdrawn'
   where id = p_application_id
     and sitter_id = v_sitter_id
     and status = 'pending';

  if not found then
    raise exception 'application not found or cannot be withdrawn';
  end if;

  insert into public.audit_logs (actor_id, action, entity_type, entity_id)
  values (v_sitter_id, 'application_withdrawn', 'applications', p_application_id);
end;
$$;

-- ============================================================
-- 3. create_hire(application_id)
-- Called by: Family, from job detail screen
-- One transaction: accept this app, reject others, create hire,
--                  open conversation, update job status
-- ============================================================
create or replace function public.create_hire(
  p_application_id uuid
)
returns public.hires
language plpgsql security definer
set search_path = public as $$
declare
  v_family_id   uuid := auth.uid();
  v_app         public.applications;
  v_job         public.jobs;
  v_rate        numeric(10,2);
  v_sitter_age  int;
  v_hire        public.hires;
  v_conv_id     uuid;
begin
  -- 1. Fetch application and verify family owns the job
  select a.* into v_app
    from public.applications a
    join public.jobs j on j.id = a.job_id
   where a.id = p_application_id
     and j.family_id = v_family_id
     and a.status = 'pending'
     and j.status = 'open'
  for update;

  if not found then
    raise exception 'application not found or job already hired';
  end if;

  -- 2. Fetch job
  select * into v_job from public.jobs where id = v_app.job_id;

  -- 3. Get sitter's current age and snapshot wage rate.
  -- Use full-year arithmetic on the date itself so a sitter that turned 13 yesterday
  -- is treated as 13 today (extract(year from age()) gives the same answer here, but
  -- this form is unambiguous and matches the chk_sitter_age constraint logic).
  select (date_part('year', age(current_date, date_of_birth)))::int
    into v_sitter_age
    from public.sitter_profiles
   where user_id = v_app.sitter_id;

  select hourly_rate into v_rate
    from public.age_wage_tiers
   where v_sitter_age between min_age and max_age
   order by effective_from desc
   limit 1;

  if v_rate is null then
    raise exception 'no wage tier configured for sitter age %', v_sitter_age;
  end if;

  -- 4. Accept this application
  update public.applications
     set status = 'accepted'
   where id = p_application_id;

  -- 5. Reject all other pending applications for this job
  update public.applications
     set status = 'rejected'
   where job_id = v_app.job_id
     and id <> p_application_id
     and status = 'pending';

  -- 6. Create hire with snapshotted rate
  insert into public.hires (job_id, sitter_id, hourly_rate)
  values (v_app.job_id, v_app.sitter_id, v_rate)
  returning * into v_hire;

  -- 7. Update job status to hired
  update public.jobs
     set status = 'hired'
   where id = v_app.job_id;

  -- 8. Open conversation
  insert into public.conversations (job_id, family_id, sitter_id)
  values (v_app.job_id, v_family_id, v_app.sitter_id)
  on conflict (job_id, sitter_id) do nothing
  returning id into v_conv_id;

  -- 9. Audit
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_family_id, 'hire_created', 'hires', v_hire.id,
    jsonb_build_object(
      'job_id', v_hire.job_id,
      'sitter_id', v_hire.sitter_id,
      'hourly_rate', v_hire.hourly_rate
    )
  );

  return v_hire;
end;
$$;

-- ============================================================
-- 4. clock_in(hire_id, lat, lng)
-- Called by: Sitter, from Active Job screen
-- ============================================================
create or replace function public.clock_in(
  p_hire_id uuid,
  p_lat     double precision,
  p_lng     double precision
)
returns public.time_entries
language plpgsql security definer
set search_path = public as $$
declare
  v_sitter_id     uuid := auth.uid();
  v_hire          public.hires;
  v_job           public.jobs;
  v_entry         public.time_entries;
  v_geofence_ok   boolean;
  v_dist_m        double precision;
  v_hard_block    boolean;
begin
  -- 0. Take a per-sitter advisory lock so two simultaneous clock_in calls
  --    serialize. Belt-and-suspenders alongside the partial unique index
  --    uq_one_open_time_entry — that index will reject duplicates with a
  --    clean unique-violation error, but the advisory lock guarantees the
  --    rest of this transaction (job status flip, audit log) sees a
  --    consistent state. The lock is automatically released at COMMIT.
  perform pg_advisory_xact_lock(hashtext('clock_in:' || v_sitter_id::text));

  -- 1. Validate hire belongs to this sitter and job is 'hired'
  select h.* into v_hire
    from public.hires h
    join public.jobs j on j.id = h.job_id
   where h.id = p_hire_id
     and h.sitter_id = v_sitter_id
     and j.status = 'hired'
  for update;

  if not found then
    raise exception 'hire not found or job not in hired state';
  end if;

  -- 2. Pre-check (defensive). The partial unique index uq_one_open_time_entry
  --    is the authoritative gate — if this check passes but a concurrent
  --    transaction inserts first, the index will raise a unique_violation
  --    on our own INSERT below and the whole transaction rolls back.
  if exists (
    select 1 from public.time_entries
    where sitter_id = v_sitter_id and clock_out_at is null
  ) then
    raise exception 'sitter already has an open time entry'
      using errcode = '23505';   -- mimic unique_violation for consistent UI handling
  end if;

  -- 3. Fetch job for geofence
  select * into v_job from public.jobs where id = v_hire.job_id;

  -- 4. Geofence check (Haversine via earthdistance extension)
  v_dist_m := earth_distance(
    ll_to_earth(v_job.location_lat, v_job.location_lng),
    ll_to_earth(p_lat, p_lng)
  );
  v_geofence_ok := v_dist_m <= v_job.geofence_radius_m;

  -- 5. Hard-block config (read via cfg_bool helper — see Migration 12).
  --    Direct casts of system_config.value can silently misfire when the
  --    JSON-encoded value is the string 'true' vs the boolean true; cfg_bool
  --    handles both safely.
  v_hard_block := public.cfg_bool('geofence_hard_block', false);

  if not v_geofence_ok and v_hard_block then
    raise exception 'you are %.0f meters from the job location. must be within %sm.',
      v_dist_m, v_job.geofence_radius_m;
  end if;

  -- 6. Update job to active
  update public.jobs set status = 'active' where id = v_job.id;

  -- 7. Insert time entry. The partial unique index will reject this row
  --    if any other open entry for this sitter exists.
  insert into public.time_entries (
    hire_id, sitter_id, clock_in_at,
    clock_in_lat, clock_in_lng, geofence_passed
  )
  values (
    p_hire_id, v_sitter_id, now(),
    p_lat, p_lng, v_geofence_ok
  )
  returning * into v_entry;

  -- 8. Audit
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_sitter_id, 'clock_in', 'time_entries', v_entry.id,
    jsonb_build_object(
      'geofence_passed', v_geofence_ok,
      'distance_m', round(v_dist_m::numeric, 2),
      'lat', p_lat, 'lng', p_lng
    )
  );

  return v_entry;
end;
$$;

-- ============================================================
-- 5. clock_out(hire_id, lat, lng)
-- Called by: Sitter, from Active Job screen
-- One transaction: close time entry, calculate exact-minute wage,
--                  insert ledger entry, update wallet, complete job
-- ============================================================
create or replace function public.clock_out(
  p_hire_id uuid,
  p_lat     double precision,
  p_lng     double precision
)
returns public.time_entries
language plpgsql security definer
set search_path = public as $$
declare
  v_sitter_id     uuid := auth.uid();
  v_entry         public.time_entries;
  v_hire          public.hires;
  v_job           public.jobs;
  v_sitter_age    int;
  v_dist_m        double precision;
  v_geofence_ok   boolean;
  v_total_seconds numeric;
  v_minutes       int;
  v_wage          numeric(12,2);
  v_new_balance   numeric(12,2);
begin
  -- 1. Fetch open time entry for this hire, owned by this sitter
  select te.* into v_entry
    from public.time_entries te
   where te.hire_id = p_hire_id
     and te.sitter_id = v_sitter_id
     and te.clock_out_at is null
  for update;

  if not found then
    raise exception 'no open clock-in found for this job';
  end if;

  -- 2. Fetch hire and job
  select * into v_hire from public.hires where id = p_hire_id;
  select * into v_job  from public.jobs  where id = v_hire.job_id;

  -- 3. Geofence at clock-out
  v_dist_m := earth_distance(
    ll_to_earth(v_job.location_lat, v_job.location_lng),
    ll_to_earth(p_lat, p_lng)
  );
  v_geofence_ok := v_dist_m <= v_job.geofence_radius_m;

  -- 4. Compute exact-minute wage using SNAPSHOTTED rate from hires table
  --    Formula: minutes = ceil(seconds / 60)
  --             wage    = (minutes / 60.0) * hourly_rate
  --    Using hire.hourly_rate (snapshotted at hire time — immutable)
  v_total_seconds := extract(epoch from (now() - v_entry.clock_in_at));
  v_minutes := ceil(v_total_seconds / 60.0)::int;
  v_wage := round((v_minutes::numeric / 60.0) * v_hire.hourly_rate, 2);

  -- 5. Update time entry
  update public.time_entries
     set clock_out_at    = now(),
         clock_out_lat   = p_lat,
         clock_out_lng   = p_lng,
         geofence_passed = v_geofence_ok,
         computed_minutes = v_minutes,
         computed_wage    = v_wage
   where id = v_entry.id
  returning * into v_entry;

  -- 6. Update wallet (available_balance + lifetime_earnings)
  update public.wallets
     set available_balance = available_balance + v_wage,
         lifetime_earnings = lifetime_earnings + v_wage,
         updated_at        = now()
   where sitter_id = v_sitter_id
  returning available_balance into v_new_balance;

  -- Wallet row must exist (created during sitter onboarding)
  if not found then
    raise exception 'wallet not found for sitter';
  end if;

  -- 7. Insert ledger entry
  insert into public.ledger_entries (
    sitter_id, type, amount, reference_type, reference_id, balance_after
  )
  values (
    v_sitter_id, 'earning', v_wage, 'time_entry', v_entry.id, v_new_balance
  );

  -- 8. Mark job completed
  update public.jobs set status = 'completed' where id = v_job.id;

  -- 9. Audit
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_sitter_id, 'clock_out', 'time_entries', v_entry.id,
    jsonb_build_object(
      'minutes', v_minutes,
      'wage', v_wage,
      'balance_after', v_new_balance,
      'geofence_passed', v_geofence_ok
    )
  );

  return v_entry;
end;
$$;

-- ============================================================
-- 6. request_withdrawal(amount, method, account_info)
-- Called by: Sitter, from WithdrawScreen
-- ============================================================
create or replace function public.request_withdrawal(
  p_amount       numeric(12,2),
  p_method       text,
  p_account_info jsonb default '{}'
)
returns public.withdrawal_requests
language plpgsql security definer
set search_path = public as $$
declare
  v_sitter_id    uuid := auth.uid();
  v_balance      numeric(12,2);
  v_request      public.withdrawal_requests;
begin
  -- 1. Check available balance
  select available_balance into v_balance
    from public.wallets where sitter_id = v_sitter_id
  for update;

  if not found then
    raise exception 'wallet not found';
  end if;
  if p_amount <= 0 then
    raise exception 'withdrawal amount must be positive';
  end if;
  if p_amount > v_balance then
    raise exception 'insufficient balance: available %.2f, requested %.2f',
      v_balance, p_amount;
  end if;

  -- 2. Deduct from available balance immediately (reserved)
  update public.wallets
     set available_balance = available_balance - p_amount,
         pending_balance   = pending_balance   + p_amount
   where sitter_id = v_sitter_id;

  -- 3. Create withdrawal request
  insert into public.withdrawal_requests (sitter_id, amount, method, account_info)
  values (v_sitter_id, p_amount, p_method, p_account_info)
  returning * into v_request;

  -- 4. Ledger entry for deduction
  insert into public.ledger_entries (
    sitter_id, type, amount, reference_type, reference_id, balance_after
  )
  values (
    v_sitter_id, 'withdrawal', -p_amount, 'withdrawal_request', v_request.id,
    v_balance - p_amount
  );

  -- 5. Audit
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, after_state)
  values (
    v_sitter_id, 'withdrawal_requested', 'withdrawal_requests', v_request.id,
    jsonb_build_object('amount', p_amount, 'method', p_method)
  );

  return v_request;
end;
$$;

-- ============================================================
-- 7. admin_approve_bg_check(family_id, decision, notes)
-- Called by: Admin (via Supabase Studio or future admin web)
-- ============================================================
create or replace function public.admin_approve_bg_check(
  p_family_id uuid,
  p_decision  text,  -- 'approved' | 'rejected'
  p_notes     text default null
)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_admin_id uuid := auth.uid();
begin
  -- Standard admin RPC preamble: gate + immutability bypass for the bg_check_status flip.
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  if p_decision not in ('approved', 'rejected') then
    raise exception 'decision must be approved or rejected';
  end if;

  update public.background_checks
     set status      = p_decision::public.verification_status,
         reviewed_by = v_admin_id,
         reviewed_at = now(),
         admin_notes = p_notes
   where family_id = p_family_id;

  -- Update family_profile bg_check_status for fast RLS checks
  update public.family_profiles
     set bg_check_status = p_decision::public.verification_status
   where user_id = p_family_id;

  perform public.write_audit_log(
    'bg_check_' || p_decision,
    'background_checks',
    (select id from public.background_checks where family_id = p_family_id),
    null,
    jsonb_build_object('decision', p_decision, 'notes', p_notes, 'family_id', p_family_id)
  );

  -- Notification to family (insert row; Edge Function will push FCM)
  insert into public.notifications (user_id, type, title, body)
  values (
    p_family_id,
    'bg_check_result',
    case when p_decision = 'approved' then 'Background Check Approved'
         else 'Background Check Update' end,
    case when p_decision = 'approved'
         then 'Your background check has been approved. You can now post jobs.'
         else coalesce(p_notes, 'Your background check requires attention.') end
  );
end;
$$;

-- ============================================================
-- 8. admin_approve_certification(cert_id, decision, notes)
-- Called by: Admin
-- ============================================================
create or replace function public.admin_approve_certification(
  p_cert_id  uuid,
  p_decision text,
  p_notes    text default null
)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_admin_id  uuid := auth.uid();
  v_sitter_id uuid;
begin
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  if p_decision not in ('approved', 'rejected') then
    raise exception 'decision must be approved or rejected';
  end if;

  select sitter_id into v_sitter_id from public.certifications where id = p_cert_id;
  if not found then raise exception 'certification not found'; end if;

  update public.certifications
     set status      = p_decision::public.verification_status,
         reviewed_by = v_admin_id,
         reviewed_at = now(),
         admin_notes = p_notes
   where id = p_cert_id;

  -- If this is the first approved cert AND guardian consent is in place,
  -- flip sitter is_active. The trigger fn_sitter_lock_admin_fields permits
  -- this because we set the bypass GUC above.
  if p_decision = 'approved' then
    update public.sitter_profiles
       set is_active = true
     where user_id = v_sitter_id
       and guardian_consent_status = 'approved';
  end if;

  perform public.write_audit_log(
    'cert_' || p_decision,
    'certifications',
    p_cert_id,
    null,
    jsonb_build_object('decision', p_decision, 'sitter_id', v_sitter_id, 'notes', p_notes)
  );

  insert into public.notifications (user_id, type, title, body)
  values (
    v_sitter_id, 'cert_result',
    case when p_decision = 'approved' then 'Certification Approved' else 'Certification Update' end,
    case when p_decision = 'approved'
         then 'Your certification has been verified. You can now apply to jobs.'
         else coalesce(p_notes, 'Your certification requires attention.') end
  );
end;
$$;

-- ============================================================
-- 9. admin_pay_withdrawal(request_id)
-- Called by: Admin, after physically transferring funds
-- ============================================================
create or replace function public.admin_pay_withdrawal(
  p_request_id uuid
)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_admin_id  uuid := auth.uid();
  v_request   public.withdrawal_requests;
begin
  perform public.admin_only();

  select * into v_request
    from public.withdrawal_requests
   where id = p_request_id and status = 'pending'
  for update;

  if not found then raise exception 'pending withdrawal not found'; end if;

  update public.withdrawal_requests
     set status  = 'paid',
         paid_at = now(),
         paid_by = v_admin_id
   where id = p_request_id;

  update public.wallets
     set pending_balance = pending_balance - v_request.amount
   where sitter_id = v_request.sitter_id;

  perform public.write_audit_log(
    'withdrawal_paid',
    'withdrawal_requests',
    p_request_id,
    null,
    jsonb_build_object('amount', v_request.amount, 'sitter_id', v_request.sitter_id)
  );

  insert into public.notifications (user_id, type, title, body)
  values (
    v_request.sitter_id, 'withdrawal_paid',
    'Withdrawal Processed',
    format('Your withdrawal of $%.2f has been sent.', v_request.amount)
  );
end;
$$;
```

---

## 8. Edge Functions

Edge Functions run as Deno TypeScript. They are called via database webhooks on specific table events. They use the `SUPABASE_SERVICE_ROLE_KEY` secret (never exposed to clients) to bypass RLS for trusted server-to-server writes.

### 8.1 send_push — FCM HTTP v1 (OAuth 2.0 service-account flow)

Triggered by: database webhook on `INSERT INTO public.notifications`.

**Critical correctness note.** The legacy "FCM server key as Bearer token"
flow Google deprecated in June 2024 will not work — `https://fcm.googleapis.com/v1/...`
requires an OAuth 2.0 access token signed by the Firebase service account.
This function:

1. Loads the service-account JSON from `FCM_SERVICE_ACCOUNT_JSON` secret.
2. Builds a JWT (RS256) with the FCM scope, signs it with the private key.
3. Exchanges the JWT for a 1-hour access token at Google's OAuth endpoint.
4. Caches the access token in module scope (Edge Functions are reused across
   invocations within a worker) so we exchange roughly once per hour, not
   once per push.
5. Skips the live HTTP call entirely when `system_config.fcm_provider = 'mock'`
   (demo mode without a Firebase project).

```typescript
// supabase/functions/send_push/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { create as createJwt, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const SUPABASE_URL      = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SRK      = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID    = Deno.env.get("FCM_PROJECT_ID") ?? "";
const FCM_SA_JSON       = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ?? "";
const WEBHOOK_SECRET    = Deno.env.get("WEBHOOK_SECRET")!;

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const TOKEN_URL = "https://oauth2.googleapis.com/token";
const FCM_URL   = `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`;

interface NotificationRecord {
  id: string;
  user_id: string;
  type: string;
  title: string | null;
  body: string | null;
  data: Record<string, unknown>;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

// In-process token cache. Edge Functions reuse workers across invocations,
// so this dramatically cuts cold-start latency on a hot path.
let cachedToken: { token: string; expiresAt: number } | null = null;

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(cleaned), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 60) {
    return cachedToken.token;
  }

  const key = await importPrivateKey(sa.private_key);
  const jwt = await createJwt(
    { alg: "RS256", typ: "JWT" },
    {
      iss:   sa.client_email,
      scope: FCM_SCOPE,
      aud:   TOKEN_URL,
      iat:   getNumericDate(0),
      exp:   getNumericDate(60 * 60),
    },
    key,
  );

  const resp = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion:  jwt,
    }),
  });
  if (!resp.ok) {
    throw new Error(`token exchange failed: ${resp.status} ${await resp.text()}`);
  }
  const json = await resp.json();
  cachedToken = {
    token: json.access_token,
    expiresAt: now + (json.expires_in ?? 3600),
  };
  return cachedToken.token;
}

async function withRetry<T>(fn: () => Promise<T>, attempts = 3): Promise<T> {
  let lastErr: unknown;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (e) {
      lastErr = e;
      // Exponential backoff: 200ms, 800ms, 3200ms
      await new Promise((r) => setTimeout(r, 200 * Math.pow(4, i)));
    }
  }
  throw lastErr;
}

serve(async (req) => {
  // 1. Verify webhook secret (constant-time-ish comparison would be better;
  // for v0.1 a string compare is acceptable — webhook URL is unguessable too).
  const secret = req.headers.get("x-webhook-secret");
  if (!secret || secret !== WEBHOOK_SECRET) {
    return new Response("Unauthorized", { status: 401 });
  }

  const payload = await req.json();
  const record: NotificationRecord = payload.record;
  if (!record?.id) return new Response("bad payload", { status: 400 });

  const admin = createClient(SUPABASE_URL, SUPABASE_SRK, {
    auth: { persistSession: false },
  });

  // 2. Read provider flag. 'mock' = demo mode → log + exit 200.
  const { data: cfgRow } = await admin
    .from("system_config").select("value").eq("key", "fcm_provider").maybeSingle();
  const provider = (cfgRow?.value as string | null) ?? "mock";

  if (provider !== "live") {
    console.log(JSON.stringify({
      lvl: "info", fn: "send_push", mode: "mock",
      notif_id: record.id, user_id: record.user_id, type: record.type,
    }));
    return new Response("mock-ok", { status: 200 });
  }

  if (!FCM_PROJECT_ID || !FCM_SA_JSON) {
    console.error(JSON.stringify({
      lvl: "error", fn: "send_push", err: "fcm_provider=live but secrets missing",
      notif_id: record.id,
    }));
    return new Response("config missing", { status: 500 });
  }

  // 3. Fetch device tokens for this user
  const { data: devices, error } = await admin
    .from("devices")
    .select("fcm_token, platform")
    .eq("user_id", record.user_id);

  if (error || !devices?.length) {
    console.log(JSON.stringify({
      lvl: "info", fn: "send_push", notif_id: record.id, devices: 0,
    }));
    return new Response("no devices", { status: 200 });
  }

  // 4. Get access token (cached)
  let sa: ServiceAccount;
  try {
    sa = JSON.parse(FCM_SA_JSON);
  } catch {
    return new Response("invalid service account json", { status: 500 });
  }
  const accessToken = await getAccessToken(sa);

  // 5. Send one FCM message per device. Use idempotency via the
  // notification.id — FCM doesn't dedupe natively but our DB webhook is
  // single-fire so duplicates only appear if Supabase retries us.
  const sends = devices.map((device) =>
    withRetry(async () => {
      const fcmPayload = {
        message: {
          token: device.fcm_token,
          notification: {
            title: record.title ?? "Star Sitters",
            body:  record.body  ?? "",
          },
          data: {
            notification_id: record.id,
            type: record.type,
            ...Object.fromEntries(
              Object.entries(record.data ?? {}).map(([k, v]) => [k, String(v)]),
            ),
          },
          android: { priority: "high" },
          apns: { headers: { "apns-priority": "10" } },
          fcm_options: { analytics_label: record.type },
        },
      };
      const resp = await fetch(FCM_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmPayload),
      });
      if (!resp.ok) {
        const errText = await resp.text();
        // 404/410 → token expired/uninstalled → prune
        if (resp.status === 404 || resp.status === 410
            || errText.includes("UNREGISTERED") || errText.includes("NOT_FOUND")) {
          await admin.from("devices")
            .delete()
            .eq("user_id", record.user_id)
            .eq("fcm_token", device.fcm_token);
          return; // do not retry — token is permanently bad
        }
        throw new Error(`fcm ${resp.status}: ${errText}`);
      }
    })
  );

  const results = await Promise.allSettled(sends);
  const ok = results.filter((r) => r.status === "fulfilled").length;
  const fail = results.length - ok;
  console.log(JSON.stringify({
    lvl: "info", fn: "send_push", notif_id: record.id,
    devices: results.length, ok, fail,
  }));
  return new Response("ok", { status: 200 });
});
```

**Required Edge Function secrets (Block 1 deployment commands already updated):**

| Secret | Value | Source |
|---|---|---|
| `SUPABASE_URL` | auto-set by Supabase | Project settings |
| `SUPABASE_SERVICE_ROLE_KEY` | auto-set by Supabase | Project settings |
| `WEBHOOK_SECRET` | random 32-byte hex | `openssl rand -hex 32` |
| `FCM_PROJECT_ID` | Firebase project id (e.g. `starsitters-prod`) | Firebase console → Project settings |
| `FCM_SERVICE_ACCOUNT_JSON` | full JSON of the SA private key | Firebase console → Service accounts → Generate new private key |

### 8.2 send_guardian_consent_email

Triggered by: database webhook on `INSERT INTO public.guardian_consents`.

**Two modes:**
- `email_provider = 'mock'` → log the consent link to Edge Function logs.
  Demo-friendly without an email account.
- `email_provider = 'resend'` → POST to Resend's HTTP API
  (`https://api.resend.com/emails`) with the rendered HTML.

**Token expiry:** the consent link is valid for 24 hours, enforced by
`public.confirm_guardian_consent()` in §8.3 (NOT in this Edge Function —
that gate is server-side at consent time, not at email send time).

```typescript
// supabase/functions/send_guardian_consent_email/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL   = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SRK   = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const WEBHOOK_SECRET = Deno.env.get("WEBHOOK_SECRET")!;
const APP_BASE_URL   = Deno.env.get("APP_BASE_URL")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";

interface GuardianConsentRecord {
  id: string;
  sitter_id: string;
  guardian_name: string;
  guardian_email: string;
  consent_token: string;
}

async function withRetry<T>(fn: () => Promise<T>, attempts = 3): Promise<T> {
  let lastErr: unknown;
  for (let i = 0; i < attempts; i++) {
    try { return await fn(); }
    catch (e) {
      lastErr = e;
      await new Promise((r) => setTimeout(r, 200 * Math.pow(4, i)));
    }
  }
  throw lastErr;
}

serve(async (req) => {
  const secret = req.headers.get("x-webhook-secret");
  if (!secret || secret !== WEBHOOK_SECRET) {
    return new Response("Unauthorized", { status: 401 });
  }

  const payload = await req.json();
  const record: GuardianConsentRecord = payload.record;
  if (!record?.id) return new Response("bad payload", { status: 400 });

  const admin = createClient(SUPABASE_URL, SUPABASE_SRK, {
    auth: { persistSession: false },
  });

  // Read provider + from-address from system_config
  const { data: cfgRows } = await admin
    .from("system_config")
    .select("key, value")
    .in("key", ["email_provider", "email_from"]);
  const cfg: Record<string, string> = {};
  (cfgRows ?? []).forEach((r: { key: string; value: unknown }) => {
    cfg[r.key] = r.value as string;
  });
  const provider = cfg.email_provider ?? "mock";
  const fromAddr = cfg.email_from ?? "StarSitters <noreply@starsitters.app>";

  // Sitter name for the email
  const { data: user } = await admin
    .from("users").select("full_name").eq("id", record.sitter_id).maybeSingle();
  const sitterName = user?.full_name ?? "your child";

  const consentLink = `${APP_BASE_URL}/consent?token=${record.consent_token}`;
  const subject = `Guardian consent for ${sitterName} — Star Sitters`;
  const html = `
    <h2>Guardian Consent Required — Star Sitters</h2>
    <p>Hi ${record.guardian_name},</p>
    <p>${sitterName} has registered on Star Sitters, a teen babysitting marketplace.</p>
    <p>To activate their account, click the button below within 24 hours:</p>
    <p><a href="${consentLink}" style="
      background:#2B7FFF;color:white;padding:12px 24px;
      border-radius:8px;text-decoration:none;display:inline-block;
    ">Give Consent</a></p>
    <p>This link is one-time use and expires in 24 hours.</p>
    <p>If you did not expect this email, you can safely ignore it.</p>
  `;
  const text = `Guardian consent for ${sitterName}\n\nClick to consent (valid 24h): ${consentLink}\n\nIgnore if unexpected.`;

  // Mock mode: log the link, don't send.
  if (provider === "mock") {
    console.log(JSON.stringify({
      lvl: "info", fn: "send_guardian_consent_email", mode: "mock",
      to: record.guardian_email, link: consentLink,
    }));
    return new Response("mock-ok", { status: 200 });
  }

  if (provider === "resend") {
    if (!RESEND_API_KEY) {
      console.error(JSON.stringify({
        lvl: "error", fn: "send_guardian_consent_email",
        err: "email_provider=resend but RESEND_API_KEY missing",
      }));
      return new Response("config missing", { status: 500 });
    }
    await withRetry(async () => {
      const r = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json",
          // Resend supports an Idempotency-Key header for safe retries
          "Idempotency-Key": `consent:${record.id}`,
        },
        body: JSON.stringify({
          from: fromAddr,
          to: [record.guardian_email],
          subject,
          html,
          text,
          tags: [{ name: "type", value: "guardian_consent" }],
        }),
      });
      if (!r.ok) {
        throw new Error(`resend ${r.status}: ${await r.text()}`);
      }
    });
    console.log(JSON.stringify({
      lvl: "info", fn: "send_guardian_consent_email", provider: "resend",
      consent_id: record.id, to: record.guardian_email,
    }));
    return new Response("ok", { status: 200 });
  }

  // Unknown provider — fail loud
  console.error(JSON.stringify({
    lvl: "error", fn: "send_guardian_consent_email",
    err: `unknown email_provider=${provider}`,
  }));
  return new Response("unknown provider", { status: 500 });
});
```

**Required Edge Function secrets when `email_provider = 'resend'`:**

| Secret | Source | Notes |
|---|---|---|
| `RESEND_API_KEY` | resend.com → API Keys | only the `Sending` scope needed |
| `APP_BASE_URL` | your project URL | for the consent link host |

When the Resend account isn't ready yet, leave `email_provider = 'mock'` in
`system_config`. The function logs the consent link to the Edge Function
output — sufficient for the Friday demo and for QA.

### 8.3 update_guardian_consent (public RPC, no auth required)

This is the function called when the guardian clicks the consent link. It is a Postgres function (not an Edge Function) called anonymously:

```sql
-- in 20260501000013_rpcs.sql (add at end)

create or replace function public.confirm_guardian_consent(
  p_token uuid
)
returns boolean
language plpgsql security definer
set search_path = public as $$
declare
  v_sitter_id        uuid;
  v_consent_created  timestamptz;
  v_token_ttl_hours  int := 24;
begin
  -- Mark this transaction as a server-side privileged write so the
  -- fn_sitter_lock_admin_fields trigger lets us flip guardian_consent_status.
  -- The GUC is transaction-scoped (set local) so it cannot leak to other
  -- sessions.
  perform set_config('app.bypass_immutability', 'true', true);

  -- 1. Atomically claim the token. This single UPDATE both checks (token
  --    exists, not yet used, not expired) and consumes (sets consent_given_at).
  --    Two concurrent guardians clicking the same link will see exactly one
  --    success because the row is locked by the UPDATE.
  update public.guardian_consents
     set consent_given_at = now(),
         consent_ip       = inet_client_addr()
   where consent_token   = p_token
     and consent_given_at is null
     and created_at      > now() - make_interval(hours => v_token_ttl_hours)
  returning sitter_id, created_at
        into v_sitter_id, v_consent_created;

  if not found then
    -- Either the token doesn't exist, was already consumed, or expired.
    -- Don't leak which one — a 24h-old token vs a fake token both return false.
    return false;
  end if;

  -- 2. Update sitter profile consent status. The trigger respects our GUC.
  update public.sitter_profiles
     set guardian_consent_status = 'approved'
   where user_id = v_sitter_id;

  -- 3. Notify sitter
  insert into public.notifications (user_id, type, title, body)
  values (
    v_sitter_id, 'guardian_consent_given',
    'Guardian Consent Received',
    'Your guardian has given consent. Your profile is now under admin review.'
  );

  -- 4. Audit (no actor — guardian is unauthenticated)
  insert into public.audit_logs (action, entity_type, entity_id, after_state)
  values ('guardian_consent_confirmed', 'guardian_consents', v_sitter_id,
          jsonb_build_object('confirmed_at', now()));

  return true;
end;
$$;
```

The trigger from Migration 13 must respect the GUC bypass set above. Update
`fn_sitter_lock_admin_fields` to look like this (replace the body in
Migration 13 with):

```sql
create or replace function public.fn_sitter_lock_admin_fields()
returns trigger language plpgsql as $$
declare
  v_bypass boolean;
begin
  -- Server-side server-issued writes (like confirm_guardian_consent and the
  -- admin_* RPCs) set this GUC for the duration of their transaction.
  v_bypass := coalesce(current_setting('app.bypass_immutability', true), 'false') = 'true';

  if not v_bypass and not public.admin_only_bool() then
    if old.is_active is distinct from new.is_active then
      raise exception 'is_active is admin-only' using errcode = '42501';
    end if;
    if old.guardian_consent_status is distinct from new.guardian_consent_status then
      raise exception 'guardian_consent_status is admin-only' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;
```

Apply the same pattern to `fn_family_lock_admin_fields` and
`fn_prevent_role_change`. Every admin RPC starts with:

```sql
perform admin_only();
perform set_config('app.bypass_immutability', 'true', true);
```

This makes the immutability triggers a "deny by default; explicitly bypass via
SECURITY DEFINER + GUC" gate. Non-admin clients have no way to set the GUC
because `set_config(... is_local => true)` only affects the current
transaction, and they don't run inside one of these RPCs.

---

## 9. Storage Buckets + Access Policies

All buckets are created in Supabase Storage with the following configuration:

| Bucket | Public | Purpose | Max file size |
|---|---|---|---|
| `avatars` | Yes | Profile pictures | 5 MB |
| `bg-check-docs` | No | Family background check documents | 20 MB |
| `cert-docs` | No | Sitter certification documents | 20 MB |
| `guardian-consent-docs` | No | Uploaded guardian consent forms | 20 MB |

Storage policies (configured in Supabase dashboard or via `config.toml`):

**avatars (public):**
- Any authenticated user can upload to `avatars/{user_id}/*`
- All reads are public (no auth required for display)

**bg-check-docs (private):**
- Family can upload to `bg-check-docs/{family_id}/*`
- Family can read `bg-check-docs/{family_id}/*`
- Admins can read everything under `bg-check-docs/`
- No other access

**cert-docs (private):**
- Sitter can upload to `cert-docs/{sitter_id}/*`
- Sitter can read `cert-docs/{sitter_id}/*`
- Admins can read everything
- No other access

**guardian-consent-docs (private):**
- Sitter can upload to `guardian-consent-docs/{sitter_id}/*`
- Admins can read everything
- No other access

---

## 10. Auth Flow

### 10.1 Family signup (multi-step wizard)

```
Step 1: Name + Email + Phone
         → supabase.auth.signUp(email, password, {data: {role: 'family', full_name: name}})
         → trigger creates users row + family_profiles row
         → navigate to step 2

Step 2: Home address + location
         → supabase.from('family_profiles').update({home_address, home_lat, home_lng})

Step 3: Add children
         → supabase.from('children').insert([{family_id, name, age},...])

Step 4: Emergency contact + babysitter preferences
         → supabase.from('family_profiles').update({emergency_contact, babysitter_prefs})
         → navigate to HomeScreen

Note: bg_check_status starts as 'not_submitted'.
      Family sees a banner on HomeScreen: "Complete your background check to post jobs."
```

### 10.2 Sitter signup (multi-step wizard)

```
Step 1: Name + Email + Phone + Date of Birth
         → validate age: 11–17 (client + DB constraint)
         → supabase.auth.signUp(email, password, {data: {role: 'sitter', full_name, dob}})
         → trigger creates users row + sitter_profiles row

Step 2: Bio + availability preferences
         → supabase.from('sitter_profiles').update({bio, ...})

Step 3: Guardian info (name, email, phone)
         → supabase.from('guardian_consents').insert({sitter_id, guardian_name, guardian_email, guardian_phone})
         → DB webhook fires send_guardian_consent_email Edge Function
         → guardian receives magic link

Step 4–6: Upload certifications (optional before admin review)
         → supabase.storage.from('cert-docs').upload(...)
         → supabase.from('certifications').insert({cert_type, document_path})

Final: Navigate to profile_under_review_screen.dart
       Listen to supabase.from('sitter_profiles').stream().eq('user_id', uid)
       When is_active flips to true → navigate to HomeScreen
```

### 10.3 Google OAuth

```dart
// In AuthRepo
Future<void> signInWithGoogle() async {
  await supabase.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: 'io.supabase.starsitters://login-callback/',
  );
  // On redirect back: auth trigger creates users row with role from metadata
  // Role selection screen shown if raw_user_meta_data.role is missing
}
```

### 10.4 AuthGate — routes by role

```dart
// packages/star_sitters_core/lib/src/widgets/auth_gate.dart
class AuthGate extends ConsumerWidget {
  final Widget familyHome;
  final Widget sitterHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return session.when(
      loading: () => const SplashScreen(),
      error: (e, _) => SignInScreen(),
      data: (s) {
        if (s == null) return SignInScreen();
        final role = s.user.userMetadata?['role'];
        if (role == 'sitter') return sitterHome;
        if (role == 'family') return familyHome;
        return RoleSelectionScreen(); // new OAuth user with no role yet
      },
    );
  }
}
```

---

## 11. Wage Engine Spec

### Formula (server-side only, in `clock_out` RPC)

```
total_seconds = clock_out_at - clock_in_at (in seconds)
total_minutes = ceil(total_seconds / 60)       -- always round UP to favor sitter
hourly_rate   = age_wage_tiers WHERE sitter_age BETWEEN min_age AND max_age
                ORDER BY effective_from DESC LIMIT 1
wage          = ROUND((total_minutes / 60.0) * hourly_rate, 2)  -- numeric(12,2)
```

### Default seed tiers

```sql
-- seed.sql
insert into public.age_wage_tiers (min_age, max_age, hourly_rate, effective_from)
values
  (11, 12, 8.00,  '2026-01-01'),
  (13, 14, 10.00, '2026-01-01'),
  (15, 16, 12.00, '2026-01-01'),
  (17, 17, 14.00, '2026-01-01');
```

### Critical design decisions

- **Rate is snapshotted at hire time** into `hires.hourly_rate`. If an admin changes `age_wage_tiers` next week, all historical wages are unaffected.
- **`numeric(10,2)` not float.** Postgres `numeric` is exact decimal. `0.1 + 0.2 = 0.30` guaranteed.
- **Rounding direction: `ceil()`** on minutes. This is in the sitter's favor. Consistent, predictable.
- **The client cannot forge the wage.** The Flutter app sends `hire_id`, `lat`, `lng`. The server reads the clock-in timestamp from the DB and computes duration itself. There is no `duration` parameter.
- **Wage preview (pre-hire):** The sitter can call a lightweight helper function to estimate: `SELECT round(((extract(epoch from (end_time - start_time))/60.0)/60.0) * hourly_rate, 2) as estimated_wage FROM jobs j JOIN age_wage_tiers awt ON ... WHERE j.id = ...`

---

## 12. Geofencing Spec

### Algorithm

```sql
-- earthdistance extension (loaded in Migration 1)
-- earth_distance(ll_to_earth(lat1, lng1), ll_to_earth(lat2, lng2)) returns meters

SELECT earth_distance(
  ll_to_earth(job.location_lat, job.location_lng),  -- center
  ll_to_earth(sitter.current_lat, sitter.current_lng) -- sitter
) as distance_meters;
```

### Parameters

| Parameter | Value | Configured in |
|---|---|---|
| Default geofence radius | 150 m | `jobs.geofence_radius_m` default + `system_config` |
| Hard block (clock_in denied if outside) | false (soft-warn) | `system_config.geofence_hard_block` |
| Audit on every clock event | Always | `audit_logs` row on every clock_in and clock_out |
| Family notification on geofence fail | Yes | notification insert after clock_in |

### Why soft-warn is the default

GPS inside a building on a mobile phone typically drifts ±50-100 m depending on signal strength. A hard-block default on day one means sitters working inside a house fail to clock in, file support tickets you don't have time to handle, and the family is left with no time-tracking record. The audit log captures the `distance_m` so the family can see it. Hard-block can be enabled via `system_config` once the client explicitly requests it.

### Setting per-job radius

The family fills in the radius when posting the job (advanced option, defaults to 150 m):

```dart
// In post_new_job_step1 (advanced options)
// Default: 150; range: 50–500 m; shown as a slider
job.geofenceRadiusM = sliderValue.round();
```

---

## 13. Real-Time Chat Spec

### Channel naming convention

```
conversation:{conversation_id}
```

Each conversation gets its own Realtime channel. Only the two participants can subscribe (enforced by RLS on `messages` table — Realtime respects row-level security).

### Flutter implementation pattern

```dart
// In ChatRepo
Stream<List<Message>> streamMessages(String conversationId) {
  return supabase
    .from('messages')
    .stream(primaryKey: ['id'])
    .eq('conversation_id', conversationId)
    .order('created_at', ascending: true)
    .map((rows) => rows.map(Message.fromJson).toList());
}

Future<void> sendMessage(String conversationId, String body) async {
  await supabase.from('messages').insert({
    'conversation_id': conversationId,
    'sender_id': supabase.auth.currentUser!.id,
    'body': body,
  });
  // RLS enforces sender_id = auth.uid() and user is a participant
}
```

### Message ordering guarantee

Messages are inserted with a server-generated `created_at` (`timestamptz default now()`). The stream queries `ORDER BY created_at ASC`. Because `created_at` is server-side, client clock drift cannot reorder messages.

### Reconnect strategy

`supabase_flutter` Realtime handles reconnect automatically. On reconnect, the stream query refetches the last-known state. Add a "last_seen_message_id" cursor in `ChatRepo` so on reconnect we backfill only new messages, not the full history:

```dart
// On reconnect: fetch messages after lastSeenId
final backfill = await supabase
  .from('messages')
  .select()
  .eq('conversation_id', conversationId)
  .gt('created_at', lastSeenTimestamp)
  .order('created_at');
```

### Mark-as-read

When the user opens a conversation, fire:

```dart
// supabase_flutter v2 uses isFilter() for IS NULL / IS NOT NULL checks.
// (.is_() does not exist on PostgrestFilterBuilder in v2 — using it will
// throw a NoSuchMethodError at runtime.)
await supabase.from('messages')
  .update({'read_at': DateTime.now().toIso8601String()})
  .eq('conversation_id', conversationId)
  .neq('sender_id', supabase.auth.currentUser!.id)
  .isFilter('read_at', null);
```

### Reading system_config from Flutter

For boolean / int / text values like `geofence_hard_block`,
`default_geofence_radius_m`, `email_from`, prefer the typed RPC helpers
defined in §5 Migration 12. They handle JSON-encoded values consistently
across Postgres types, instead of casting raw `jsonb` text on the client:

```dart
// Boolean — recommended:
final hardBlock = await supabase
  .rpc('cfg_bool', params: { 'p_key': 'geofence_hard_block', 'p_default': false });
// hardBlock is bool

// String:
final emailFrom = await supabase
  .rpc('cfg_text', params: { 'p_key': 'email_from' });

// Int:
final radius = await supabase
  .rpc('cfg_int', params: { 'p_key': 'default_geofence_radius_m', 'p_default': 150 });
```

Avoid `select value from system_config` followed by client-side casts —
JSON-encoded values like `'true'` (string) vs `true` (boolean) silently
coerce differently across Dart and Postgres and have caused bugs before.

---

## 14. Push Notification Pipeline

### Flow

```
Row inserted into public.notifications
       ↓
Supabase Database Webhook (configured in dashboard)
       ↓ HTTP POST with row payload + x-webhook-secret header
Supabase Edge Function: send_push/index.ts
       ↓ reads devices table for user's FCM tokens
FCM HTTP v1 API: https://fcm.googleapis.com/v1/projects/{id}/messages:send
       ↓
Firebase Cloud Messaging
       ↓
Android device push notification
```

### Notification types and triggers

| Event | Notification type | Recipient |
|---|---|---|
| New application submitted | `new_application` | Family |
| Hire confirmed | `hired` | Sitter |
| New message received | `new_message` | Other party in conversation |
| Background check approved/rejected | `bg_check_result` | Family |
| Certification approved/rejected | `cert_result` | Sitter |
| Guardian consent received | `guardian_consent_given` | Sitter |
| Withdrawal paid | `withdrawal_paid` | Sitter |
| Geofence fail on clock-in | `geofence_warning` | Family |

### Device token registration (Flutter)

```dart
// On app start, after login
final token = await FirebaseMessaging.instance.getToken();
if (token != null) {
  await supabase.from('devices').upsert({
    'user_id': supabase.auth.currentUser!.id,
    'fcm_token': token,
    'platform': Platform.isAndroid ? 'android' : 'ios',
    'last_seen_at': DateTime.now().toIso8601String(),
  }, onConflict: 'user_id, fcm_token');
}

// Refresh token
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
  await supabase.from('devices').upsert({...newToken...});
});
```

---

## 15. Security & DDoS Hardening

This is a platform handling **financial transactions for minors**. Security is non-negotiable at every layer.

### Layer 1 — Network / Transport

- **HTTPS enforced everywhere.** Supabase enforces TLS 1.2+ on all connections. There is no HTTP fallback.
- **Supabase is behind Cloudflare.** All Supabase projects are reverse-proxied by Cloudflare, which provides:
  - Free-tier DDoS protection (L3/L4) — absorbs volumetric attacks automatically.
  - SSL offloading at the edge.
  - IP reputation filtering.
- **No self-hosted infrastructure to expose.** There is no server IP to target. Supabase's REST API and WebSocket endpoints are on shared infrastructure. DDoS against a single customer is impractical.

### Layer 2 — Authentication

- **JWT expiry set to 1 hour** (Supabase default). Refresh tokens rotate on use. Stolen access tokens expire fast.
- **Refresh token rotation.** Each refresh issues a new refresh token and invalidates the old. One-time use.
- **`auth.uid()` is derived from the JWT, not a request parameter.** Client cannot spoof another user's ID. All RPCs and RLS policies call `auth.uid()` — they do not accept a `user_id` parameter from the client.
- **Email verification required** before sign-in completes. Bot sign-ups get blocked before they can post jobs or submit applications.
- **Rate limits on auth endpoints (Supabase built-in):** signup, login, password reset, OTP — all have per-IP rate limits configurable in the Supabase dashboard. Set to: 5 failed login attempts per 15 minutes per IP before temporary lockout.

### Layer 3 — Authorization (Defense in Depth)

- **RLS on every table, default DENY.** Even if an Edge Function has a bug, the database refuses unauthorized reads/writes.
- **`SECURITY DEFINER` functions with explicit `search_path`.** Prevents privilege escalation via search_path injection.
- **Sensitive columns protected at application layer too.** `consent_token` in `guardian_consents` is never included in any SELECT used by a Flutter query. It only travels from the DB to the Edge Function (which has service_role access). This is defense-in-depth on top of RLS.
- **Role cannot be changed by the user.** The `users.role` column is set by the auth trigger from `raw_user_meta_data`. There is no RLS policy allowing the user to update their own `role` field.
- **Admin role is separate from OAuth.** `admin_users` table is populated manually by the developer. OAuth users get `family` or `sitter` role only.

### Layer 4 — Business Logic Integrity

- **All financial mutations are server-side RPCs with `SECURITY DEFINER`.** `clock_out`, `request_withdrawal`, `admin_pay_withdrawal` are atomic Postgres transactions. A race condition, interrupted connection, or duplicate request cannot result in double-payment or corrupted balance.
- **Idempotency guard on clock_in:** raises exception if an open time_entry already exists for the hire. Prevents double-clocking.
- **Balance check before withdrawal:** `request_withdrawal` checks `available_balance >= amount` inside a `FOR UPDATE` lock. Prevents overdraft even with concurrent requests.
- **Wage rate snapshotted at hire time.** Immutable. Cannot be retroactively changed via admin panel.
- **Children's data gated strictly.** Only the parent can read their own children's records. Sitters never see children's data in any query.

### Layer 5 — Storage Security

- All sensitive document buckets are private with path-scoped policies.
- Signed URLs expire in 1 hour. Sharing a signed URL beyond 1 hour yields a 403.
- File type validation: only `image/jpeg`, `image/png`, `application/pdf` accepted. Enforced in Flutter before upload + enforceable in a storage policy.
- File size limits prevent large-file abuse (20 MB max).

### Layer 6 — Edge Function Security

- All Edge Functions verify a `x-webhook-secret` header before processing. This prevents external parties from triggering push notifications by POSTing to the function URL directly.
- `SUPABASE_SERVICE_ROLE_KEY` is stored as a Supabase secret, never in code or git.
- Edge Functions run in an isolated Deno runtime per invocation.

### Layer 7 — Data Compliance (minors)

- **Minimum data collection.** We collect date_of_birth for wage calculation. No location stored long-term (clock-in/out coordinates stored in time_entries for audit but not streamed to other users).
- **Guardian consent is mandatory before any sitter activity.** `is_active = false` is the default. Sitter cannot apply to jobs until both guardian consent and admin cert approval flip `is_active`.
- **Data retention.** Add a scheduled function in v0.2 to delete `time_entries`, `messages`, and `audit_logs` older than 24 months per GDPR/COPPA guidance.
- **No PII in FCM payloads.** Push notification data field contains only `notification_id` and `type`. The Flutter app fetches the full notification from Supabase — no sensitive data in transit over FCM.

### What "DDoS protection" means practically for this project

| Attack type | Protection |
|---|---|
| Volumetric (flood of packets) | Cloudflare absorbs at network edge — zero config required |
| Application-layer (HTTP flood against auth endpoints) | Supabase Auth rate limits (configurable per project) |
| Credential stuffing | Auth rate limits + email verification + JWT expiry |
| Data scraping (enumerate all jobs/sitters) | RLS blocks cross-user reads; pagination required for all list queries |
| Replay attacks | JWT is short-lived (1hr); refresh token is single-use |
| Injection (SQL injection) | Supabase client uses parameterized queries exclusively; no raw string interpolation in RPCs |
| Privilege escalation | `search_path = public` on all `SECURITY DEFINER` functions; role is immutable after signup |
| Financial fraud (fake clock-out) | Server computes duration from its own timestamps; no client-supplied duration |

---

## 16. Shared Flutter Package — star_sitters_core

### pubspec.yaml

```yaml
name: star_sitters_core
version: 0.1.0

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.5.0
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  riverpod_generator: ^2.3.0
  flutter_test:
    sdk: flutter
```

### Key model example — Job

```dart
// packages/star_sitters_core/lib/src/models/job.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'job.freezed.dart';
part 'job.g.dart';

enum JobStatus { draft, open, hired, active, completed, cancelled }

@freezed
class Job with _$Job {
  const factory Job({
    required String id,
    required String familyId,
    required String title,
    String? description,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required int numberOfChildren,
    required double locationLat,
    required double locationLng,
    required Map<String, dynamic> locationAddress,
    @Default(150) int geofenceRadiusM,
    required JobStatus status,
    required DateTime createdAt,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}
```

### Key repo example — JobRepo

```dart
// packages/star_sitters_core/lib/src/repos/job_repo.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';

class JobRepo {
  final SupabaseClient _client;
  JobRepo(this._client);

  // Stream of open jobs for sitter browse/home feed
  Stream<List<Job>> streamAvailableJobs() {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('status', 'open')
        .order('start_time', ascending: true)
        .map((rows) => rows.map(Job.fromJson).toList());
  }

  // Stream of this family's jobs
  Stream<List<Job>> streamMyJobs(String familyId) {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Job.fromJson).toList());
  }

  // Create a new job
  Future<Job> createJob(Map<String, dynamic> jobData) async {
    final response = await _client
        .from('jobs')
        .insert(jobData)
        .select()
        .single();
    return Job.fromJson(response);
  }

  // RPC: hire a sitter
  Future<Map<String, dynamic>> createHire(String applicationId) async {
    return await _client.rpc('create_hire', params: {
      'p_application_id': applicationId,
    });
  }
}
```

### Riverpod providers

```dart
// packages/star_sitters_core/lib/src/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repos/job_repo.dart';
import '../repos/chat_repo.dart';
import '../repos/wallet_repo.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final sessionProvider = StreamProvider<Session?>(
  (ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange
      .map((event) => event.session),
);

final jobRepoProvider = Provider<JobRepo>(
  (ref) => JobRepo(ref.watch(supabaseClientProvider)),
);

final availableJobsProvider = StreamProvider<List<Job>>(
  (ref) => ref.watch(jobRepoProvider).streamAvailableJobs(),
);

// families pass their ID
final myJobsProvider = StreamProvider.family<List<Job>, String>(
  (ref, familyId) => ref.watch(jobRepoProvider).streamMyJobs(familyId),
);

// etc. for chat, wallet, applications...
```

---

## 17. Screen-by-Screen Wiring Map

### Family App (`Star_Sitter_Family`)

| File | Change required |
|---|---|
| `main.dart` | Initialize Supabase + Firebase, use `AuthGate` as home. (`ProviderScope` / Riverpod optional unless you adopt §16 providers.) |
| `onboarding_flow.dart` | No change — UI only, no data |
| `sign_in_screen.dart` | Replace `pushAndRemoveUntil(HomeScreen)` with `AuthRepo.signIn()`. `AuthGate` handles routing. Add Google OAuth button. |
| `forgot_password_screen.dart` | `supabase.auth.resetPasswordForEmail(email)` |
| `create_new_password_screen.dart` | `supabase.auth.updateUser(UserAttributes(password: ...))` |
| `create_account_screen.dart` | Step 1: `supabase.auth.signUp(...)` with `{role: 'family'}` metadata |
| `create_account_step2_screen.dart` | Write `family_profiles` home address |
| `create_account_step3_screen.dart` | Write `children` rows |
| `create_account_step4_screen.dart` | Write `family_profiles` emergency_contact + prefs |
| `home_screen.dart` | Replace hardcoded job list with `ref.watch(myJobsProvider(familyId))`. Replace hardcoded sitter list with `SitterRepo.streamRecommended()`. |
| `hire_screen.dart` | Replace mock sitter list with `SitterRepo.streamPublicActive(filters)` |
| `notifications_screen.dart` | Stream `notifications` table for current user |
| `jobs_details_screen.dart` | Show real `applications` for this job. "Hire" button → `JobRepo.createHire(applicationId)` |
| `job_detailss_screen.dart` | **Removed** from repo (use `jobs_details_screen.dart` only). |
| `job_details_weekend_screen.dart` | **Removed** from repo. |
| `my_posted_jobs_screen.dart` | Stream `myJobsProvider` |
| `emma_johnson_profile_screen.dart` | Load real sitter profile from `sitter_profiles` + `certifications` |
| `emma_johnson_chat_screen.dart` | Replace stub with `ChatRepo.streamMessages(conversationId)` + `ChatRepo.sendMessage(...)` |
| `messages_screen.dart` | Stream `conversations` for this family's jobs |
| `post_new_job_step1_screen.dart` | Collect form fields (no DB write yet) |
| `post_new_job_step2_screen.dart` | Collect form fields (no DB write yet) |
| `post_new_job_step3_screen.dart` | Collect form fields (no DB write yet) |
| `post_new_job_step4_screen.dart` | Final step: `JobRepo.createJob({all collected fields})` |
| `hire_emma_johnson_step1-4_screen.dart` | Steps collect data; Step 4: `JobRepo.createHire(applicationId)` |
| `hire_emma_johnson_request_sent_screen.dart` | No change — just confirmation UI |
| `profile_screen.dart` | Load `users` + `family_profiles` row |
| `edit_profile_screen.dart` | `supabase.from('users').update(...)` + `family_profiles.update(...)` |
| `personal_information_screen.dart` | Read from real profile |
| `change_password_screen.dart` | `supabase.auth.updateUser(UserAttributes(password: ...))` |
| `privacy_settings_screen.dart` | No backend in v0.1 |
| `manage_billing_screen.dart` | No backend in v0.1 (Stripe deferred) |
| `billing_history_screen.dart` | No backend in v0.1 |
| `payment_method_screen.dart` | No backend in v0.1 |
| `home_address_screen.dart` | `family_profiles.update({home_address, home_lat, home_lng})` |
| `home_safety_information_screen.dart` | `family_profiles.update({home_safety_info})` |
| `emergency_contact_screen.dart` | `family_profiles.update({emergency_contact})` |
| `children_information_screen.dart` | Read/write `children` table |
| `babysitter_preferences_screen.dart` | `family_profiles.update({babysitter_prefs})` |
| `bottom_nav_bar.dart` | **FIX:** replace `Navigator.push` with `setState(() => _selectedIndex = index)` using `IndexedStack` like the sitter app already does. |

### Babysitter App (`Star_Sitter_Baby_Sitter`)

| File | Change required |
|---|---|
| `main.dart` | Initialize Supabase + Firebase, `AuthGate` as home (same Riverpod note as family). |
| `sign_in_screen.dart` | `AuthRepo.signIn()` + Google OAuth |
| `create_account_screen.dart` | Step 1: `supabase.auth.signUp(...)` with `{role: 'sitter'}` metadata |
| `create_account_step2-6_screen.dart` | Steps 2-6 write to `sitter_profiles`, `guardian_consents`, `certifications` |
| `profile_under_review_screen.dart` | Stream `sitter_profiles.is_active`; navigate to Home when it flips true |
| `home_screen.dart` | Replace `_HomeTab` hardcoded lists with real repos |
| `browse_tab.dart` / `browse_screen.dart` | `ref.watch(availableJobsProvider)` replaces `_jobs` static list |
| `job_detail_screen.dart` | "Apply" → `rpc('create_application', {...})`. `_applied` state persisted in `applications` table. |
| `my_applications_screen.dart` | Stream `applications` for this sitter |
| `job_history_screen.dart` | Stream completed `hires` for this sitter |
| `chat_screen.dart` | `ChatRepo.streamMessages(conversationId)` + `sendMessage` |
| `messages_tab.dart` / `messages_screen.dart` | Stream `conversations` for this sitter |
| `wallet_screen.dart` | Replace static `_transactions` with `WalletRepo.streamLedger(sitterId)` |
| `earnings_screen.dart` | Sum from `ledger_entries` where type = 'earning' |
| `withdraw_screen.dart` | `rpc('request_withdrawal', {amount, method, account_info})` |
| `withdrawal_success_screen.dart` | No change — confirmation UI |
| `all_transactions_screen.dart` | Paginated `ledger_entries` stream |
| `transaction_details_screen.dart` | Load single `ledger_entries` row |
| `certifications_screen.dart` (existing or new) | Stream `certifications` for this sitter; "Upload" → Storage + insert cert row |
| `quiz_screen.dart` | Keep local — quiz is a certification training tool; on pass, `certifications.insert({cert_type: 'quiz_1', status: 'pending'})` to trigger admin review |
| `quiz_pass_screen.dart` | Trigger cert submission |
| `notification_screen.dart` | Stream `notifications` table |
| `profile_screen.dart` | Load `users` + `sitter_profiles` + `certifications` |
| `personal_information_screen.dart` | Read/write real profile |
| `edit_personal_information_screen.dart` | `sitter_profiles.update(...)` |
| `guardian_details_screen.dart` | Read `guardian_consents` row |
| `edit_guardian_details_screen.dart` | `guardian_consents.update(...)` (triggers new consent email) |
| `documents_screen.dart` | Stream `certifications`; file uploads to `cert-docs` bucket |
| `settings_screen.dart` | Local-only in v0.1 |
| `help_center_screen.dart` | Static in v0.1 |
| **NEW** `active_job_screen.dart` | Clock In button → `rpc('clock_in', {hire_id, lat, lng})`. Timer counting elapsed seconds. Live wage estimate. Clock Out → `rpc('clock_out', {hire_id, lat, lng})`. Navigate to `wallet_screen` on complete. |

---

## 18. 5-Day Execution Plan

### 18.0 Local Tuesday demo — what this monorepo already covers

Run **`supabase start`** (or link a project and **`supabase db reset`**) so all migrations apply, then run each Flutter app with your **`SUPABASE_URL`** / **`SUPABASE_ANON_KEY`** `dart-define`s. That gives a **proper local app**: jobs, applications, hire, chat, messages, wallet, clock in/out (with location permission), notifications, profile header, family **IndexedStack** shell (no duplicate bottom-nav roots), and **no** duplicate `job_detailss_*` screens.

| Still on you (hosting / rehearsal) | Not required for “UI + DB” local demo |
|---|---|
| Hosted Supabase project + `supabase link`, or keep using local stack | Firebase + `google-services.json` if you skip FCM |
| **`supabase functions deploy`** + secrets for email/push when you want real pushes | DB webhooks calling Edge Functions until configured |
| Physical devices + Tuesday script 3× | — |

---

### Day 1 — Foundation + Auth
**Goal:** Supabase initialized, schema deployed, both apps can sign up and sign in with real auth.

- [x] Create Supabase **hosted** project (optional if using **`supabase start`** only). *(When using hosted: project linked; keys in local `.env` / Edge secrets — rotate if ever pasted in chat.)*
- [x] Create Firebase project + FCM + `google-services.json` (**skip for local** until you need push). *(Configure when enabling `fcm_provider=live`; not required for mock push.)*
- [x] Create `starsitters-backend` GitHub repo (private). *([`T361/starsitters-backend`](https://github.com/T361/starsitters-backend).)*
- [x] Install Supabase CLI. `supabase init`. `supabase link` (or use local only). *(CLI binary install + PATH: `starsitters-backend/scripts/install-supabase-cli.sh` + `README.md`.)*
- [x] **Migrations in repo:** schema, RLS, RPCs, storage, admin, realtime publication (`starsitters-backend/supabase/migrations/`).
- [x] **`supabase db push` / `db reset`** on *your* machine — confirm migrations apply clean. *(Linked hosted project + pushed migrations; `supabase/config.toml` `[db] major_version` aligned to remote Postgres 17 — see `starsitters-backend/README.md`.)*
- [x] Storage buckets **`avatars`**, **`bg-check-docs`**, **`cert-docs`**, **`guardian-consent-docs`** created via migration + policies.
- [x] **`send_guardian_consent_email`** Edge Function source in repo.
- [x] Deploy **`send_guardian_consent_email`** Edge Function to **hosted** Supabase (`supabase functions deploy send_guardian_consent_email --no-verify-jwt`).
- [x] Configure DB webhook: `guardian_consents` INSERT → `send_guardian_consent_email` (**hosted** project). *(Done in Supabase Dashboard; re-verify in Integrations → Database Webhooks.)*
- [x] **`star_sitters_core`** + **`AuthGate`** + Supabase init on both apps.
- [x] Family app: `main.dart` init + `SignInScreen` → real Supabase auth.
- [x] Sitter app: same.
- [x] Sign up as family / sitter → **`users`** + **`family_profiles`** / **`sitter_profiles`** via **`handle_new_auth_user`** trigger (see `20260209100024_auth_user_profiles.sql`). RLS: verify in Studio as needed.

**Day 1 gate:** auth works end-to-end. Both apps land on their respective HomeScreen with a real session.

---

### Day 2 — Marketplace
**Goal:** Parent posts a job. Sitter sees it. Sitter applies. Parent sees application.

- [x] **`JobsRepository`**: `createJob`, `openJobs` / streams for family jobs, `getJob`, `hireForJob`.
- [x] Wire family create-account **steps 2–4** to persist `family_profiles` / `children` (step 1 + DB trigger already create base rows). *(Steps 2–4: `ProfileRepository.updateFamily`, `replaceFamilyChildren`, `mergeFamilyBabysitterPrefs` for terms + plan; **Step 3** uploads government ID + selfie to `bg-check-docs` via `uploadFamilyBgCheckBytes`, then stores paths under `babysitter_prefs.onboarding.identity`.)*
- [x] Wire sitter create-account wizard end-to-end for `guardian_consents` + cert rows (approve **`is_active`** in Studio for demo). *(Step 2 inserts `guardian_consents` → webhook email; Step 4 persists composed bio/skills/experience to `sitter_profiles.bio`. Course catalog / `sitter_submit_certification` intentionally unwired in apps until published `courses` exist — Certifications UI is a placeholder.)*
- [x] **`PostNewJobStep4`** → **`JobsRepository.createJob`**.
- [x] Sitter **`_HomeTab`** + job flows use **`openJobs`** / applications stream.
- [x] Sitter **`JobDetailScreen`** Apply → **`create_application`** RPC.
- [x] Family **`JobsDetailsScreen`** streams **`applications`** for the job.
- [x] **`ApplicationsRepository`**: job applications + sitter’s applications + hire.

**Day 2 gate:** on two devices — family posts job, sitter sees it appear, sitter applies, family sees the application in job detail. Full end-to-end with real data.

---

### Day 3 — Hire + Chat + Clock in/out + Wallet
**Goal:** Full happy path from application to wage in wallet.

- [x] **`create_hire`** / hire path: family job detail **Hire** uses **`ApplicationsRepository.hire`** (RPC-backed).
- [ ] Legacy **`HireEmmaJohnsonStep4`** mock flow → replace with real **`create_hire`** when you retire demo-only hire screens.
- [x] **`MessagesRepository`** stream + send (family + sitter chat UIs).
- [x] **`EmmaJohnsonChatScreen`** + **`ChatScreen`** use live messages when **`conversationId`** is set.
- [x] **`MessagesScreen` / `messages_tab`** stream **`conversations`**.
- [x] **`active_job_screen.dart`**: Clock In / Out + timer + **`WorkRepository`**.
- [x] **`geolocator`** + Android / iOS location permission strings for clock RPCs.
- [x] Clock In / Out → **`clock_in`** / **`clock_out`** RPCs with lat/lng.
- [x] **`WalletRepository`**: wallet row + ledger stream.
- [x] **`WalletScreen`** reads real **`wallets`** + **`ledger_entries`**.
- [x] **`AllTransactionsScreen`** streams **`ledger_entries`** for the signed-in sitter (filters + detail navigation).
- [x] **`MyApplicationsScreen`** loads **`ApplicationsRepository.fetchMyApplicationsWithJobs()`** (nested `jobs` read; requires sitter **`jobs`** RLS via applications/hires — migration `20260512120000_jobs_sitter_application_hire_select.sql`; confirm applied on hosted).
- [x] **`JobHistoryScreen`** loads **`JobsRepository.sitterHireHistoryWithJobs()`** (same RLS dependency as above).

**Day 3 gate:** post → apply → hire → chat → clock in → 30s → clock out → wallet shows earned amount.

---

### Day 4 — Push Notifications + Polish + Tuesday Demo
**Goal:** FCM push works. Profile screens real. Demo runs 3x clean.

- [x] Deploy **`send_push`** Edge Function to **hosted** Supabase (`supabase functions deploy send_push --no-verify-jwt`).
- [x] Configure DB webhooks: **`notifications` INSERT → `send_push`**. *(Dashboard; redeploy functions with `--no-verify-jwt`.)*
- [ ] Test push: new application → family phone buzzes. Hire → sitter phone buzzes.
- [x] **`NotificationsScreen`** (family) + **`NotificationScreen`** (sitter) stream **`notifications`** + mark read.
- [x] Profile headers load **`users`** via **`ProfileRepository.currentUserRow()`** (family **`ProfileScreen`**, sitter **`ProfileTab`**).
- [ ] Wire **`EditProfileScreen`** / sitter edit screens to **`users` / profile** updates (still mock navigation in places).
- [x] Family **`BottomNavBar`**: **`IndexedStack`** shell — no nested root pushes for main tabs.
- [x] Removed duplicate **`job_detailss_screen.dart`** and **`job_details_weekend_screen.dart`** from the family app.
- [ ] Run full demo script 3 times on two Android phones.
- [ ] Fix any demo-breaking issues found in rehearsals.

**TUESDAY DEMO** (see Section 19).

---

### Day 5 — Remaining Flows + Friday Demo
**Goal:** Background-check, certifications, withdrawal, full hardening.

- [x] Background-check upload flow: family uploads doc to `bg-check-docs` bucket, `background_checks` row inserted. Admin approves via `admin_approve_bg_check()` in Studio. *(`BackgroundCheckSubmitScreen` + `ProfileRepository.uploadFamilyBgCheckBytes` + `family_submit_background_check` RPC.)*
- [x] Cert upload flow (backend): Storage **`cert-docs`** policies + **`register_certification_document`** RPC + tightened sitter **`certifications` INSERT** RLS + seeded **published `courses`** (`20260513100000_cert_document_rpc_courses_seed_rls_tighten.sql`). *Flutter: `CertificationsRepository` + **`DocumentsScreen`** (live stream, upload, signed download).*
- [x] Sitter `is_active` gates: enforced in **`create_application`** (RPC raises if `sitter_profiles.is_active` is false). *(QA: confirm on device.)*
- [x] Family job-posting gate: enforced by **`jobs: family insert`** RLS + **`family_bg_check_approved()`** (`20260215133000_break_jobs_family_profiles_rls_cycle.sql`). *(QA: confirm on device.)*
- [x] Withdrawal request flow: `WithdrawScreen` → `request_withdrawal` → `WithdrawalSuccessScreen`. Admin marks paid in Studio. *(Sitter app: live balance from `wallets`, RPC `request_withdrawal`; bank UI still placeholder copy.)*
- [x] Write RLS regression tests: for each policy, assert it blocks what it should block and allows what it should allow (as psql script or pgTAP). *(Expanded manual matrix: `starsitters-backend/supabase/tests/rls_smoke.sql` — still not full automated pgTAP.)*
- [x] Install Sentry on both Flutter apps (`sentry_flutter` package). *(Both apps depend on `sentry_flutter`; `main.dart` calls `SentryFlutter.init` only when `SENTRY_DSN` is set in `.env` — omit DSN locally if you want zero upload.)*
- [x] Write `DEPLOY.md`, `ENV.md`. *(Implemented under `starsitters-backend/docs/DEPLOY.md` and `docs/ENV.md`.)*
- [ ] Tag `v0.1.0`.
- [ ] Rehearse Friday demo script.

**FRIDAY DEMO** (see Section 20).

### Day 6 — Buffer
- Absorb any spillover from Days 1-5.
- Polish: loading skeletons, error toasts, empty states, retry on network error.
- Capture screenshots and 3-minute screen recording for client deck.

---

## 19. Tuesday Demo Script

**Setup required before demo starts:**
1. Supabase Studio open on laptop, `users` table visible.
2. Two Android phones with both apps installed (debug APK or release).
3. Both phones on WiFi (FCM push needs internet).
4. One seed `age_wage_tiers` row: `(11, 17, 12.00, '2026-01-01')` for simplicity.
5. Both apps show sign-in screen (signed out).

**Script (~8 minutes):**

**[0:00]** "I'm going to show you a complete transaction — from a parent signing up to a teenager getting paid — on two real devices, connected to a live database."

**[0:30]** Phone 1 (Family): Open family app → Sign in with Google → Fill name, address, add one child → Land on Home screen.

**[1:00]** Phone 1: "Post New Job" → Fill in title "Saturday Babysitting", date, time, number of children → Submit. Point at laptop: `jobs` table now has a row, `status = 'open'`.

**[1:45]** Phone 2 (Babysitter): Open babysitter app → Sign up with email → Fill name, date of birth (enter 16 years old), guardian's email. On laptop: flip `sitter_profiles.is_active = true` to skip waiting on email for demo. App navigates past `profile_under_review` to Home.

**[2:30]** Phone 2: Browse tab populates with the job we just posted in real time. Tap the job → tap Apply. On laptop: `applications` table shows the new row.

**[3:00]** Phone 1 buzzes — FCM push: "New application from Emma." Tap notification → job detail → see application. Tap "Hire".

**[3:30]** Phone 2 buzzes — "You've been hired for Saturday Babysitting." Conversations tab shows chat with the family.

**[4:00]** Both phones in Messages — send a message from Phone 1, watch it appear instantly on Phone 2 in real time. Send back. "This is Supabase Realtime — WebSocket-based, no polling."

**[4:30]** Phone 2: "Active Job" screen → tap "Clock In." On laptop: `time_entries` row shows `clock_in_at` and `geofence_passed`.

**[5:00]** Wait 30 seconds. "In a real session, the timer runs for hours. The sitter watches their earned amount tick up."

**[5:30]** Phone 2: tap "Clock Out." Show wallet — "Earned $0.20." Walk through the math out loud: the `clock_out` RPC computes minutes with `ceil(seconds / 60)` and pays full minutes — 30 elapsed seconds rounds up to 1 minute, then `wage = round((1/60) × $12, 2) = $0.20`. (Same formula scales: 1h 5min = 65min × $12 / 60 = $13.00.) Show the `ledger_entries` row on laptop with `type = 'earning'` and `balance_after`. "Server-side numeric math, no floating-point drift."

**[6:00]** Talking points for Q&A:
- "RLS means it is physically impossible for one sitter to read another sitter's wallet — the DB refuses it."
- "The wage calculation runs inside a Postgres transaction on the server. The app sends clock-in and clock-out GPS coords — the server computes the wage. You can't fake earnings."
- "The audit log records every single action with timestamp, actor, and before/after state."
- "On Friday I'll show the background-check upload, admin approval, geofencing enforcement, and the withdrawal flow."

---

## 20. Friday Demo Script

**Everything from Tuesday, plus:**

**[after Tuesday script, ~10 min additional]**

1. **Background check flow (2 min):** Phone 1 (Family): Settings → Background Check → Upload ID photo (pick from gallery) → Submit. Laptop: `background_checks` row has `status = 'pending'`. Run `select public.admin_approve_bg_check('<family_id>', 'approved', null)` in Studio SQL editor. Phone 1: notification fires — "Background Check Approved." Job-post button is now enabled.

2. **Certification flow (1.5 min):** Phone 2 (Sitter): Profile → Certifications → Upload CPR cert photo. Laptop: `certifications` row, `status = 'pending'`. Run `select public.admin_approve_certification('<cert_id>', 'approved', null)`. Phone 2: notification fires.

3. **Geofencing demo (1.5 min):** Enable Android developer options → enable "Fake GPS location" app → set fake location 5 km from the job address. Sitter tries Clock In. Show `time_entries.geofence_passed = false` and `distance_m` in the `audit_logs` row. "If we flip `system_config.geofence_hard_block` to `true`, this would be a hard block." Show the config row.

4. **Withdrawal (1 min):** Phone 2: Wallet → Withdraw → Enter $0.10 → Submit. `withdrawal_requests` row appears. Laptop: run `select public.admin_pay_withdrawal('<request_id>')`. Phone 2 gets notification — wallet `pending_balance` drops to zero.

5. **Audit log (1 min):** Show `audit_logs` table on laptop — scroll through every action with timestamps. "Every admin action, every clock event, every hire, is here with actor ID, timestamp, before/after state."

6. **Admin control plane (1.5 min) — proves the admin pipeline works end-to-end without the Next.js admin app.** Open Supabase Studio → SQL editor → run an admin RPC live in front of the audience:

```sql
-- Approve the pending certification we just uploaded
select public.admin_approve_certification(
  (select id from public.certifications
   where status = 'pending' order by submitted_at desc limit 1),
  'approved',
  'CPR certification valid through 2027.'
);
```

Phone 2 buzzes — push notification "Certification Approved." On laptop, switch to `audit_logs` and `notifications` tables. Show the new `cert_approved` audit row, the new notification row, and (if showing logs) the `send_push` Edge Function log line confirming `provider=mock` (or `provider=resend` if keys are wired).

Talking point: **"Everything you just saw on the admin side runs through the same Postgres functions the Next.js admin web app will call next week. The web app is a polish layer — the security and the audit trail live in the database."**

---

## 21. Deployment & Environment Setup

### Supabase setup (Day 1, ~30 min)

```bash
# Install CLI
npm install -g supabase

# Log in
supabase login

# Initialize in starsitters-backend repo
supabase init

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Run migrations
supabase db push

# Confirm
supabase db diff  # should show no drift
```

### Edge Function deployment

```bash
# Deploy all functions (use --no-verify-jwt: DB webhooks are not user JWTs)
supabase functions deploy send_push --no-verify-jwt
supabase functions deploy send_guardian_consent_email --no-verify-jwt

# Set secrets (FCM v1 OAuth flow — see §8.1 for details)
supabase secrets set FCM_PROJECT_ID=your-firebase-project-id
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat fcm-service-account.json)"
supabase secrets set WEBHOOK_SECRET=$(openssl rand -hex 32)
supabase secrets set APP_BASE_URL=https://your-app-or-marketing-site.example
# Optional — only when email_provider is flipped to 'resend' in system_config:
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxxxxxx
supabase secrets set EMAIL_FROM="StarSitters <noreply@starsitters.app>"
```

### Database webhooks (Dashboard only — there is no `supabase db webhook` CLI)

Use **Integrations → Database Webhooks** (or **Database → Webhooks** in older UI). There is **no** `supabase` subcommand to register these; optional SQL triggers are documented [here](https://supabase.com/docs/guides/database/webhooks).

| Webhook name | Table | Events | URL |
|---|---|---|---|
| `notify_on_insert` | `notifications` | INSERT | `{SUPABASE_URL}/functions/v1/send_push` |
| `guardian_consent_email` | `guardian_consents` | INSERT | `{SUPABASE_URL}/functions/v1/send_guardian_consent_email` |

Add header: `x-webhook-secret: {your WEBHOOK_SECRET}`.

### Flutter setup

```bash
# In Star_Sitter_Family/
flutter pub add supabase_flutter firebase_core firebase_messaging \
  flutter_riverpod freezed_annotation json_annotation geolocator

# Add star_sitters_core to pubspec.yaml (git dependency)
# Run codegen
dart run build_runner build --delete-conflicting-outputs

# Place google-services.json in android/app/
# Add to AndroidManifest.xml: FCM service declaration
```

### Create admin user (one-time)

```sql
-- In Supabase Studio SQL Editor
-- 1. Sign up via the app as a normal user (any role)
-- 2. Find the user's UUID in auth.users
-- 3. Run:
UPDATE public.users SET role = 'admin' WHERE id = '<your_uuid>';
INSERT INTO public.admin_users (id) VALUES ('<your_uuid>');
```

---

## 22. Environment Variable Inventory

### Supabase Edge Functions (set via `supabase secrets set`)

| Variable | Who owns it | Purpose |
|---|---|---|
| `SUPABASE_URL` | Auto-injected | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Auto-injected | Full DB access — never expose to clients |
| `FCM_PROJECT_ID` | You (Firebase console) | Your Firebase project ID |
| `FCM_SERVICE_ACCOUNT_JSON` | You (Firebase console → Service accounts) | Full SA JSON; used by `send_push` for OAuth 2.0 token exchange |
| `WEBHOOK_SECRET` | You (`openssl rand -hex 32`) | Validates DB webhook calls to Edge Functions |
| `APP_BASE_URL` | You | Base URL for consent link in guardian email |
| `RESEND_API_KEY` | You (resend.com) | Required only when `system_config.email_provider = 'resend'` |
| `EMAIL_FROM` | You | Display + envelope sender, e.g. `"StarSitters <noreply@starsitters.app>"` |

### Flutter apps (in `.env` files — gitignored — or `--dart-define`)

| Variable | Who owns it | Purpose |
|---|---|---|
| `SUPABASE_URL` | You (from Supabase dashboard) | Supabase project URL |
| `SUPABASE_ANON_KEY` | You (from Supabase dashboard) | Public anon key — safe to embed in mobile app |
| `GOOGLE_OAUTH_CLIENT_ID_ANDROID` | Muhammad Ali (Google Cloud Console) | Google Sign-In for Android |
| `GOOGLE_OAUTH_CLIENT_ID_IOS` | Muhammad Ali (when ready) | Google Sign-In for iOS |

### Muhammad Ali needs from you

1. `SUPABASE_URL`
2. `SUPABASE_ANON_KEY`
3. `google-services.json` (Firebase Android config)

He puts these in the Flutter apps. You keep `SUPABASE_SERVICE_ROLE_KEY`, `FCM_SERVICE_ACCOUNT_JSON`, `WEBHOOK_SECRET`, and `RESEND_API_KEY` on the backend side only — they must never appear in either Flutter repo or the admin web repo bundle.

---

## 23. Observability & Logging

### Supabase built-in

- **Postgres logs:** available in Supabase Dashboard → Logs → Postgres. All slow queries (>100ms) logged. All RLS policy violations return a generic error (no information leakage to clients).
- **Edge Function logs:** Dashboard → Logs → Edge Functions. Console.log output + errors.
- **Auth logs:** Dashboard → Logs → Auth. All sign-in attempts, failures, token refreshes.
- **API logs:** Dashboard → Logs → API. Every HTTP request to PostgREST/Auth with response status and duration.

### Sentry (Flutter)

```dart
// In main.dart (both apps)
await SentryFlutter.init(
  (options) {
    options.dsn = 'YOUR_SENTRY_DSN';
    options.tracesSampleRate = 0.3; // 30% of transactions
    options.environment = const String.fromEnvironment(
      'SENTRY_ENV', defaultValue: 'development'
    );
  },
  appRunner: () => runApp(
    ProviderScope(child: const MyApp()),
  ),
);
```

Captures: unhandled exceptions, Supabase call failures, slow DB queries (add performance tracing), navigation events.

### `audit_logs` as business observability

Beyond error tracking, the `audit_logs` table is your business observability layer. Run these queries in Supabase Studio to monitor health:

```sql
-- Jobs per day
SELECT date_trunc('day', created_at), count(*) FROM jobs GROUP BY 1 ORDER BY 1 DESC;

-- Hire rate (applications that became hires)
SELECT
  count(*) FILTER (WHERE status = 'accepted') as accepted,
  count(*) FILTER (WHERE status = 'pending')  as pending,
  count(*) FILTER (WHERE status = 'rejected') as rejected,
  count(*)                                     as total
FROM applications;

-- Average time between clock_in and clock_out
SELECT round(avg(computed_minutes)::numeric, 1) as avg_minutes
FROM time_entries
WHERE clock_out_at IS NOT NULL;

-- Pending admin reviews
SELECT
  (SELECT count(*) FROM background_checks WHERE status = 'pending') as pending_bg_checks,
  (SELECT count(*) FROM certifications WHERE status = 'pending')     as pending_certs,
  (SELECT count(*) FROM withdrawal_requests WHERE status = 'pending') as pending_withdrawals;
```

---

## 24. CI/CD Pipeline

```yaml
# .github/workflows/db-push.yml
name: Supabase DB Push

on:
  push:
    branches: [main]
    paths:
      - 'supabase/migrations/**'
      - 'supabase/seed.sql'

jobs:
  db-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: supabase/setup-cli@v1
        with:
          version: latest

      - name: Link project
        run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}

      - name: Push migrations
        run: supabase db push
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
```

```yaml
# .github/workflows/flutter-analyze.yml
name: Flutter Analyze (star_sitters_core)

on:
  push:
    branches: [main]
    paths:
      - 'packages/star_sitters_core/**'
  pull_request:
    paths:
      - 'packages/star_sitters_core/**'

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'

      - name: Get dependencies
        working-directory: packages/star_sitters_core
        run: flutter pub get

      - name: Analyze
        working-directory: packages/star_sitters_core
        run: flutter analyze

      - name: Test
        working-directory: packages/star_sitters_core
        run: flutter test
```

GitHub Actions secrets needed:
- `SUPABASE_PROJECT_REF` — your project ref (from Supabase dashboard URL)
- `SUPABASE_ACCESS_TOKEN` — your personal access token (Supabase Account Settings)

---

## 25. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| AI-generated migrations have bugs | High | High | Run `supabase db reset` locally before `db push`. Hand-review every migration file. Write one SELECT against each table post-migration. |
| RLS policy is too permissive (data leak) | Medium | Critical | Write a psql test for each policy on Day 5. Test: "can sitter A read sitter B's wallet?" — assert error. |
| Supabase Realtime drops during chat demo | Low | Medium | Add `_handleReconnect` backfill in `ChatRepo`. Test by toggling airplane mode on demo device. |
| FCM token not registered before demo | Medium | High | Register token on every app start (upsert). Test push 24h before demo. Have fallback: show notification in `notifications_screen` even without push. |
| GPS unavailable inside building during clock-in demo | High | Medium | `geofence_hard_block = false` (soft-warn). Clock-in succeeds regardless. Geofence result shown for illustration. |
| Day 1 migration takes longer than expected | Medium | High | Pre-generate full migration SQL with Cursor in one session. Target < 3 hours total for all 14 migrations. |
| Muhammad Ali breaks a screen before demo | Medium | Medium | Coordinate on a feature branch per screen. Only merge to main when tested. |
| Supabase free tier connection limit (60 connections) | Low | Low | During demo: only two phones + one Studio browser tab. Not an issue. Upgrade to Pro ($25) if needed. |
| Solo dev burnout / Day 6 needed | High | Low | Day 6 buffer explicitly planned. Tuesday demo is Day 4 only — not everything needs to be done. |

---

## 26. v0.2 Backlog

These are deliberately out of scope for v0.1 but fully designed for here.

| Feature | What's needed | Estimated effort |
|---|---|---|
| **Stripe Connect** payouts | Stripe Connect Express onboarding for sitters. Replace manual withdrawal with `POST /v1/transfers`. Update `admin_pay_withdrawal` RPC. | 2-3 days |
| **Checkr/Sterling** background checks | Webhook integration: family submits → Checkr receives → result webhook → `admin_approve_bg_check` called automatically. | 2 days |
| **Apple Sign-In** | Activate in Supabase Auth. Add `apple_developer_team_id`. Configure APNs in Firebase. | 0.5 days (after accounts ready) |
| **iOS push (APNs)** | Upload APNs auth key to Firebase. Done — no code changes needed. | 0.25 days |
| **Next.js admin dashboard** | Full custom web admin. All existing RPCs remain the same. | 3-5 days |
| **Redis caching** | Cache `streamAvailableJobs` results (materialized view or Upstash Redis). Useful at 1000+ DAU. | 1 day |
| **Custom rate limiting** | Per-user-per-minute counter for message sends and clock events. Implement as a Postgres function called at top of relevant RPCs. | 0.5 days |
| **Data retention cron** | Scheduled Edge Function: delete `time_entries`, `messages`, `audit_logs` older than 24 months. | 0.25 days |
| **Facebook OAuth** | Activate provider in Supabase Auth dashboard. Zero code changes. | 0.25 days |
| **2FA on admin** | Supabase Auth MFA (TOTP). Enable in Auth settings. | 0.25 days |
| **Refund / dispute flow** | New `disputes` table. Admin mediates. Ledger adjustment RPC. | 1.5 days |
| **Recurring bookings** | `job_templates` table. Cron function creates recurring job instances. | 2 days |
| **Advanced analytics** | Materialized views refreshed hourly. Custom admin dashboard charts. | 2 days |
| **End-to-end encryption for chat** | Client-side encryption (Signal protocol or simpler symmetric key per conversation). Complex — evaluate need first. | 3-5 days |

---

## 27. External Service Integration Points (Pluggable Keys)

The team has confirmed that API keys, OAuth credentials, and developer accounts will arrive **during** the sprint, not before it starts. This section is the integration playbook: every external service is designed as a **pluggable adapter** so the backend works in "demo mode" without keys and switches to "production mode" the moment a key lands — with zero schema changes, zero RPC rewrites, and zero client-app rebuilds beyond a config push.

### 27.1 Design philosophy: Adapter Pattern + Feature Flags

Every external dependency follows the same shape:

```
┌───────────────────────────────────────────────────────────────┐
│  RPC / Edge Function (the business operation)                 │
│           │                                                   │
│           ▼                                                   │
│  Provider Adapter (interface)                                 │
│           │                                                   │
│     ┌─────┴─────┐                                             │
│     ▼           ▼                                             │
│  Mock         Real                                            │
│  Adapter      Adapter (Stripe, Checkr, Apple, etc.)           │
│                                                               │
│  Selected by system_config.{provider}_mode = 'mock'|'live'    │
└───────────────────────────────────────────────────────────────┘
```

Two consequences:

1. **Today (no keys)**: every adapter runs in `mock` mode. The system end-to-end works — manual admin approval replaces external verification, virtual ledger replaces Stripe, Android-only replaces APNs.
2. **Tomorrow (key arrives)**: change one row in `system_config`, deploy the new adapter code, no DB migration. Existing data and flows continue uninterrupted.

### 27.2 Master integration table

| Service | What it does | Demo mode (now) | Production mode (when key arrives) | Where to plug in |
|---|---|---|---|---|
| **Supabase** | DB, Auth, Realtime, Storage | Required Day 1 | Same — already production | All migrations + Flutter client |
| **Firebase Cloud Messaging** | Push notifications (Android) | Required Day 4 (free) | Same | Edge Function `send_push` |
| **Google OAuth** | "Sign in with Google" | Required Day 1 (free Google Cloud) | Same | Supabase Auth dashboard config |
| **Apple Developer Account** | iOS deployment, APNs push, Sign in with Apple | Skipped (Android-only demo) | iOS build + APNs cert + Apple OAuth | Supabase Auth dashboard + Firebase APNs upload + Xcode signing |
| **Facebook OAuth (Meta for Developers)** | "Sign in with Facebook" | Skipped | Add provider in Supabase Auth | Zero code change |
| **Stripe Connect** | Real payouts to sitters | Mock — virtual ledger + manual admin pay | Stripe Connect Express onboarding + transfers API | New Edge Function `process_withdrawal_stripe` |
| **Checkr / Sterling** | Automated background checks | Mock — admin manually approves uploaded docs | Webhook integration: submit → Checkr → result webhook → auto-approve | New Edge Function `checkr_webhook` |
| **Google Maps Platform** | Address geocoding + place autocomplete | Optional — Flutter `geolocator` works without it | Add Maps SDK key for autocomplete + reverse geocoding in address pickers | Flutter side only |
| **SendGrid / Resend (email)** | Transactional email (guardian consent, password reset) | Supabase's built-in SMTP relay (free, low deliverability) | Configure Supabase Auth SMTP to point at SendGrid | Supabase Auth dashboard config |
| **Sentry** | Error tracking | Required Day 5 (free tier) | Same | Flutter `sentry_flutter` SDK |
| **Render / Railway** | Backend hosting | Not needed — Supabase is the backend | Only needed if a Node.js admin API is added later (v0.2) | New Next.js admin in v0.2 |

### 27.3 Stripe Connect — full integration plan (when keys arrive)

Stripe needs about a week of approval lead time. The day the keys arrive, here's the plan to plug in:

**Schema additions (one migration):**

```sql
-- Add to sitter_profiles
alter table public.sitter_profiles
  add column stripe_connect_account_id text,
  add column stripe_onboarding_status text default 'not_started';
  -- 'not_started' | 'pending' | 'active' | 'restricted'

-- Add to withdrawal_requests
alter table public.withdrawal_requests
  add column stripe_transfer_id text,
  add column stripe_payout_id text;

-- Update system_config
insert into public.system_config (key, value) values
  ('payout_provider', '"stripe"'::jsonb)
on conflict (key) do update set value = excluded.value;  -- was 'manual'
```

**New Edge Function: `stripe_create_connect_account`**
Triggered by sitter from a "Set up payouts" button. Returns a Stripe-hosted onboarding URL. Sitter completes KYC. Webhook updates `stripe_onboarding_status`.

**New Edge Function: `stripe_webhook`**
Receives `account.updated`, `transfer.created`, `payout.paid` events. Updates DB.

**Modified RPC: `admin_pay_withdrawal`**
Branches on `system_config.payout_provider`:
- `'manual'` → existing logic (mark paid, audit log)
- `'stripe'` → call Edge Function `stripe_initiate_transfer`, status remains `pending` until webhook fires

**Flutter changes:**
- New screen on sitter app: `payout_setup_screen.dart` — opens Stripe Connect onboarding URL in WebView.
- `withdraw_screen.dart` blocks submission if `stripe_onboarding_status != 'active'`.

**Estimated implementation time when keys arrive:** 2 days.

**What stays unchanged:** the entire wallet, ledger_entries, and withdrawal_requests structure. Stripe is purely the *execution* layer.

### 27.4 Checkr / Sterling — full integration plan

**Schema additions:**

```sql
alter table public.background_checks
  add column checkr_candidate_id text,
  add column checkr_report_id text,
  add column auto_verified boolean default false;

insert into public.system_config (key, value) values
  ('bg_check_provider', '"checkr"'::jsonb)
on conflict (key) do update set value = excluded.value;  -- was 'manual'
```

**New Edge Function: `checkr_submit`**
Called when family submits documents. Creates a Checkr Candidate, sends invite, stores `checkr_candidate_id`.

**New Edge Function: `checkr_webhook`**
Receives `report.completed` events. If `result == 'clear'`, calls existing `admin_approve_bg_check` RPC with `auto_verified = true`. If `result == 'consider'`, leaves `status = 'pending'` for human review.

**Modified RPC: `admin_approve_bg_check`**
Add optional `auto_verified` boolean parameter. Audit log records whether decision was human or automated.

**Flutter changes:** none. The family upload flow stays identical.

**Estimated time:** 1.5 days.

### 27.5 Apple Developer Account + iOS deployment

When the Apple Developer team ID arrives:

**Day 1 (1-2 hours):**
1. In Apple Developer Portal: create an App ID, an APNs auth key (.p8), and Sign-In-With-Apple service ID.
2. In Firebase Console: upload the `.p8` key to enable iOS push.
3. In Supabase Auth dashboard: enable Apple provider, paste service ID + team ID + key ID + .p8 contents.
4. In Xcode (Muhammad Ali handles): set development team, enable push notifications capability, enable Sign in with Apple capability.

**Schema/code changes:** **zero**. Push notifications, OAuth, and the entire backend continue to work. iOS just becomes a supported platform.

**Build a TestFlight-ready iOS .ipa:**
1. `flutter build ipa --release`
2. Upload via Transporter or Fastlane to App Store Connect.
3. Distribute via TestFlight to client.

**Estimated time when account arrives:** half a day.

### 27.6 Facebook OAuth (Meta for Developers)

Trivial integration:
1. Register app at developers.facebook.com.
2. Add Supabase callback URL to Facebook app settings.
3. In Supabase Auth dashboard: enable Facebook, paste App ID + App Secret.

**Code changes:** add Facebook button to `sign_in_screen.dart` calling `signInWithOAuth(OAuthProvider.facebook)`.

**Estimated time:** 15 minutes.

### 27.7 Google Maps Platform (Address autocomplete + reverse geocoding)

Used to improve UX when family enters home address (currently we let them type freely).

**Flutter changes only** — backend has no Google Maps dependency. We use the Postgres `earthdistance` extension for geofence math, not Google.

If/when the Maps key arrives:
1. Add `google_maps_flutter` and `flutter_google_places_sdk` to Family + Sitter apps.
2. Replace freeform address text fields with autocomplete.
3. On selection, store `place_id` and resolve `lat/lng` via Places API.

**Estimated time:** 1 day Flutter work (Muhammad Ali side, not backend).

### 27.8 SendGrid / Resend (transactional email)

Initially we use Supabase Auth's built-in SMTP relay. It works but has weak deliverability — emails to Gmail/Outlook may land in spam.

**When SendGrid/Resend key arrives:**
1. In Supabase Dashboard → Auth → SMTP Settings: enter SendGrid SMTP credentials.
2. Custom email templates (welcome, password reset, magic link) can be uploaded.

**Code changes:** zero. Supabase handles all email sending uniformly.

The `send_guardian_consent_email` Edge Function should be upgraded to call SendGrid HTTP API directly for better tracking — half a day's work.

### 27.9 Implementation order recommendation

When keys start arriving, plug them in this order:

1. **Apple Developer Account** (highest visibility — unblocks iOS demo to client)
2. **Facebook OAuth** (15 min, trivial win)
3. **Stripe Connect** (highest business value — real payouts)
4. **Checkr/Sterling** (operational efficiency — cuts admin workload)
5. **SendGrid** (deliverability polish)
6. **Google Maps** (UX polish — Muhammad Ali's work, not yours)

### 27.10 Feature flags — `system_config` keys reserved for adapter switching

```sql
-- Provider feature flags. Add to seed.sql alongside the §5 seeds.
-- Values are JSON-encoded (see §5 system_config convention + cfg_text helper).
insert into public.system_config (key, value) values
  ('payout_provider',         '"manual"'::jsonb),  -- 'manual' | 'stripe'
  ('bg_check_provider',       '"manual"'::jsonb),  -- 'manual' | 'checkr' | 'sterling'
  ('email_provider',          '"mock"'::jsonb),    -- 'mock' | 'resend' (§8.2)
  ('fcm_provider',            '"mock"'::jsonb),    -- 'mock' | 'live'   (§8.1)
  ('apple_signin_enabled',    'false'::jsonb),
  ('facebook_signin_enabled', 'false'::jsonb),
  ('ios_enabled',             'false'::jsonb)
on conflict (key) do nothing;
```

Flipping any of these does not require a code deploy — adapters check the value at runtime. This is critical for safe rollouts and instant rollbacks if an external service has an outage.

---

## 28. Deployment Strategy (Render / Firebase / TestFlight)

Per team alignment: backend is Supabase, push is Firebase, iOS distribution will be TestFlight. Here is the complete deployment topology.

### 28.1 What gets deployed where

```
┌──────────────────────────────────────────────────────────────┐
│  Production Deployment Topology                              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Component              Hosted On            Deploy Method   │
│  ─────────────────────  ─────────────────    ─────────────── │
│  Postgres database      Supabase Cloud       supabase db push│
│  Auth (OAuth + email)   Supabase Cloud       Dashboard config│
│  Realtime channels      Supabase Cloud       Auto (no deploy)│
│  Storage buckets        Supabase Cloud       Dashboard config│
│  Edge Functions         Supabase Cloud       supabase functions deploy │
│  RPCs / SQL functions   Supabase Cloud       supabase db push│
│  Migrations             Supabase Cloud       supabase db push│
│                                                              │
│  FCM (push)             Firebase Cloud       Console only    │
│  APNs cert (iOS)        Firebase Cloud       Console upload  │
│                                                              │
│  Family Flutter APK     Direct distribution  flutter build apk → share │
│  Sitter Flutter APK     Direct distribution  flutter build apk → share │
│  Family Flutter iOS     TestFlight           App Store Connect upload │
│  Sitter Flutter iOS     TestFlight           App Store Connect upload │
│                                                              │
│  Future Next.js admin   Vercel or Render     git push        │
│  (v0.2 only)                                                 │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 28.2 Why Render is **not** needed for v0.1

The team mentioned Render or Railway for backend hosting. **You do not need to host a separate backend server for v0.1.** Supabase *is* the backend:

- Database is Supabase Postgres (managed)
- API is auto-generated from Postgres tables (PostgREST)
- Auth is Supabase Auth (managed)
- Realtime is Supabase Realtime (managed)
- Server logic runs as Edge Functions (Deno, managed, deployed via `supabase functions deploy`)

There is no Node.js Express server, no Django backend, no FastAPI service. Everything you would normally host on Render is hosted by Supabase.

**When Render becomes useful (v0.2):**
- If a custom Next.js admin dashboard is built that needs server-side rendering with the Supabase service role key, Render is a good host (alternative: Vercel).
- If a custom REST API is added later for partner integrations, Render hosts that Node.js service.

For v0.1: skip Render entirely. Saves time, money, and one moving part.

### 28.3 Supabase deployment workflow

**Initial setup (Day 1, one-time):**

```bash
# 1. Create Supabase project at supabase.com (free tier)
#    Note: project ref, URL, anon key, service role key

# 2. In starsitters-backend repo:
supabase init

# 3. Link local repo to remote project
supabase link --project-ref YOUR_PROJECT_REF

# 4. Push initial schema
supabase db push

# 5. Deploy Edge Functions
supabase functions deploy send_push --no-verify-jwt
supabase functions deploy send_guardian_consent_email --no-verify-jwt

# 6. Set Edge Function secrets
#    FCM v1 uses a Google service account JSON for OAuth 2.0 access tokens.
#    Generate the service account at: Firebase Console → Project Settings →
#    Service accounts → Generate new private key. Then paste the JSON into the secret:
supabase secrets set FCM_PROJECT_ID=your-firebase-project-id
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat fcm-service-account.json)"
supabase secrets set WEBHOOK_SECRET=$(openssl rand -hex 32)
supabase secrets set APP_BASE_URL=https://your-app-or-marketing-site.example
# Optional (Block 5 — email): Resend or SendGrid
supabase secrets set RESEND_API_KEY=...      # only when email_provider=resend
supabase secrets set EMAIL_FROM="StarSitters <noreply@starsitters.app>"

# 7. Configure DB webhooks (Supabase Dashboard → Database → Webhooks)
#    - notifications INSERT → send_push function URL
#    - guardian_consents INSERT → send_guardian_consent_email function URL
#    - Both with x-webhook-secret header
```

**Ongoing deploys (every commit to main):**

```bash
# CI/CD does this automatically (see .github/workflows/db-push.yml)
supabase db push                    # Apply new migrations
supabase functions deploy send_push --no-verify-jwt
supabase functions deploy send_guardian_consent_email --no-verify-jwt
```

**Rollback strategy:**
- Migrations are forward-only — never use `supabase db reset` against production.
- For an emergency rollback: write a new migration that reverses the change.
- Edge Functions: `supabase functions deploy` with previous commit checkout.
- Database snapshot: Supabase takes daily backups on Pro plan ($25/mo); restore from dashboard.

### 28.4 Firebase deployment workflow

Firebase setup is **one-time** and almost entirely console-based:

1. Create Firebase project at console.firebase.google.com.
2. Add Android app (package name: `com.starsitters.family` and `com.starsitters.sitter` — coordinate with Muhammad Ali on actual package names).
3. Download `google-services.json` for each app, place in `android/app/`.
4. **No code in your backend repo deploys to Firebase.** All FCM calls happen from Supabase Edge Functions via HTTP.

**When Apple Developer account arrives:**
5. Add iOS app in Firebase project.
6. Download `GoogleService-Info.plist`, place in iOS Runner directory (Muhammad Ali handles in Xcode).
7. Upload APNs auth key (.p8) in Firebase Project Settings → Cloud Messaging → Apple app configuration.

**Cost:** $0 for FCM at any reasonable scale. Free forever.

### 28.5 Flutter app distribution

**Android (immediate, for Tuesday demo):**

```bash
# Muhammad Ali runs this in each Flutter repo:
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY

# Output: build/app/outputs/flutter-apk/app-release.apk
# Distribute: WhatsApp / Google Drive / Firebase App Distribution
```

For team distribution, **Firebase App Distribution** is recommended (free, professional):
1. Enable App Distribution in Firebase Console.
2. `firebase appdistribution:distribute app-release.apk --app YOUR_FIREBASE_APP_ID --groups "internal-testers"`
3. Testers receive an email with install link.

**iOS (when Apple account arrives):**

```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=...

# Output: build/ios/ipa/star_sitter_family.ipa
# Upload via Xcode → Organizer → Distribute → App Store Connect
# Then in App Store Connect → TestFlight → invite testers
```

**TestFlight** distribution requires:
- Active Apple Developer Program account ($99/year — client must provide)
- Development team ID (8-character string, in Apple Developer portal)
- App Store Connect entry created for each app
- Privacy policy URL (required for TestFlight review)
- App icons and screenshots

Initial TestFlight review takes **24-48 hours**. After that, builds are typically available within minutes.

### 28.6 Environment-specific configuration

The Supabase project becomes "production" the moment real users sign up. There is no separate staging environment in v0.1 (saves $25/month and complexity).

**For development testing:**
- Run Supabase locally with `supabase start` (Docker required).
- Local URL: `http://localhost:54321`. Local Studio at `http://localhost:54323`.
- Set `--dart-define=SUPABASE_URL=http://10.0.2.2:54321` for Android emulator (10.0.2.2 = host machine).

**For v0.2 production:**
- Spin up a second Supabase project as "staging".
- CI/CD branches: `staging` branch deploys to staging project, `main` deploys to production.
- Promote schema changes from staging to production by re-running `supabase db push` against production.

### 28.7 Domain and URLs

**v0.1 (no custom domain needed):**
- Supabase URL: `https://YOUR_PROJECT_REF.supabase.co`
- Edge Function URLs: `https://YOUR_PROJECT_REF.supabase.co/functions/v1/{name}`
- These are sufficient for Flutter apps (URLs are embedded at build time).

**v0.2 (custom domain):**
- Buy a domain (e.g. `starsitters.app`).
- Configure custom domain in Supabase Pro plan ($25/mo upgrade required).
- Update Flutter apps to point at `https://api.starsitters.app`.
- Apple/Google OAuth callback URLs need updating in respective consoles.

### 28.8 Deployment checklist (run before every demo)

- [ ] All migrations applied: `supabase db diff` shows no drift
- [ ] All Edge Functions deployed and visible in Supabase Dashboard → Edge Functions
- [ ] All DB webhooks configured and showing successful invocations in webhook logs
- [ ] FCM test push works: send a test from Firebase Console → Cloud Messaging → "Send your first message" to a real device token
- [ ] Both Flutter APKs built with the correct `--dart-define` variables and installed on demo phones
- [ ] Test sign-up + sign-in works on both apps
- [ ] One pre-seeded family + sitter pair exists in the DB so the demo doesn't break if signup hits a network blip
- [ ] Supabase Studio open on demo laptop, logged in
- [ ] Phones charged, on Wi-Fi, screen-mirroring tested
- [ ] Power cable for laptop, audio for screen-share

---

## 29. Appendix A — Full DDL (Runnable Block)

Copy this entire block into Supabase Studio SQL Editor to bootstrap the schema in one go (development/testing only — use migrations for production):

```sql
-- Extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";
create extension if not exists "cube";
create extension if not exists "earthdistance";

-- Enums
create type public.user_role as enum ('family', 'sitter', 'admin');
create type public.job_status as enum ('draft','open','hired','active','completed','cancelled');
create type public.application_status as enum ('pending','accepted','rejected','withdrawn');
create type public.verification_status as enum ('not_submitted','pending','approved','rejected');
create type public.ledger_type as enum ('earning','withdrawal','adjustment','refund');

-- Updated_at helper
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

-- users
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null,
  email text not null unique,
  full_name text, phone text, avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger trg_users_upd before update on public.users
  for each row execute function public.touch_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.users (id, role, email, full_name)
  values (new.id,
    coalesce((new.raw_user_meta_data->>'role')::public.user_role,'family'),
    new.email, coalesce(new.raw_user_meta_data->>'full_name',''))
  on conflict (id) do nothing;
  return new;
end; $$;
create trigger trg_on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- family_profiles
create table public.family_profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  home_address jsonb not null default '{}',
  home_lat double precision, home_lng double precision,
  home_safety_info text, emergency_contact jsonb default '{}',
  babysitter_prefs jsonb default '{}',
  bg_check_status public.verification_status not null default 'not_submitted',
  updated_at timestamptz not null default now()
);
create trigger trg_fp_upd before update on public.family_profiles
  for each row execute function public.touch_updated_at();

create table public.children (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.family_profiles(user_id) on delete cascade,
  name text not null check (char_length(name) between 1 and 100),
  age int not null check (age >= 0 and age <= 18),
  notes text, created_at timestamptz not null default now()
);
create index idx_children_family on public.children(family_id);

create table public.background_checks (
  id uuid primary key default gen_random_uuid(),
  family_id uuid unique not null references public.family_profiles(user_id) on delete cascade,
  documents jsonb not null default '[]',
  status public.verification_status not null default 'pending',
  reviewed_by uuid references public.users(id), reviewed_at timestamptz,
  admin_notes text, submitted_at timestamptz not null default now()
);

-- sitter_profiles
create table public.sitter_profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  date_of_birth date not null, bio text,
  is_active boolean not null default false,
  guardian_consent_status public.verification_status not null default 'not_submitted',
  total_minutes_worked int not null default 0,
  total_earnings numeric(12,2) not null default 0 check (total_earnings >= 0),
  updated_at timestamptz not null default now(),
  constraint chk_sitter_age check (
    date_of_birth <= (current_date - interval '11 years')::date
    and date_of_birth >  (current_date - interval '18 years')::date)
);
create trigger trg_sp_upd before update on public.sitter_profiles
  for each row execute function public.touch_updated_at();

create or replace function public.fn_create_wallet_for_sitter()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.wallets (sitter_id, available_balance, pending_balance,
                              lifetime_earnings, updated_at)
  values (new.user_id, 0, 0, 0, now())
  on conflict (sitter_id) do nothing;
  return new;
end;
$$;
create trigger trg_sp_wallet after insert on public.sitter_profiles
  for each row execute function public.fn_create_wallet_for_sitter();

create table public.guardian_consents (
  id uuid primary key default gen_random_uuid(),
  sitter_id uuid unique not null references public.sitter_profiles(user_id) on delete cascade,
  guardian_name text not null, guardian_email text not null, guardian_phone text,
  consent_token uuid not null default gen_random_uuid(),
  consent_given_at timestamptz, consent_ip inet, document_path text,
  created_at timestamptz not null default now()
);
create unique index idx_gc_token on public.guardian_consents(consent_token);

create table public.certifications (
  id uuid primary key default gen_random_uuid(),
  sitter_id uuid not null references public.sitter_profiles(user_id) on delete cascade,
  cert_type text not null, document_path text,
  status public.verification_status not null default 'not_submitted',
  reviewed_by uuid references public.users(id), reviewed_at timestamptz,
  admin_notes text, expires_at date, submitted_at timestamptz not null default now()
);

-- jobs
create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.family_profiles(user_id) on delete cascade,
  title text not null check (char_length(title) between 5 and 200),
  description text, date date not null,
  start_time timestamptz not null, end_time timestamptz not null,
  number_of_children int not null check (number_of_children between 1 and 10),
  child_ids uuid[] not null default '{}',
  location_lat double precision not null, location_lng double precision not null,
  location_address jsonb not null default '{}',
  geofence_radius_m int not null default 150 check (geofence_radius_m between 50 and 500),
  status public.job_status not null default 'open',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  constraint chk_job_times check (end_time > start_time)
);
create trigger trg_jobs_upd before update on public.jobs
  for each row execute function public.touch_updated_at();
create index idx_jobs_status_start on public.jobs(status, start_time);
create index idx_jobs_location on public.jobs using gist(ll_to_earth(location_lat, location_lng));

create table public.applications (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  sitter_id uuid not null references public.sitter_profiles(user_id) on delete cascade,
  cover_message text, status public.application_status not null default 'pending',
  applied_at timestamptz not null default now(), unique (job_id, sitter_id)
);

create table public.hires (
  id uuid primary key default gen_random_uuid(),
  job_id uuid unique not null references public.jobs(id) on delete cascade,
  sitter_id uuid not null references public.sitter_profiles(user_id),
  hourly_rate numeric(10,2) not null, hired_at timestamptz not null default now()
);

-- age_wage_tiers
create table public.age_wage_tiers (
  id serial primary key,
  min_age int not null check (min_age >= 0), max_age int not null check (max_age <= 100),
  hourly_rate numeric(10,2) not null check (hourly_rate > 0),
  effective_from date not null default current_date,
  created_by uuid references public.users(id),
  constraint chk_age_range check (max_age >= min_age),
  unique (min_age, max_age, effective_from)
);

-- time_entries
create table public.time_entries (
  id uuid primary key default gen_random_uuid(),
  hire_id uuid not null references public.hires(id) on delete cascade,
  sitter_id uuid not null references public.sitter_profiles(user_id),
  clock_in_at timestamptz not null, clock_out_at timestamptz,
  clock_in_lat double precision, clock_in_lng double precision,
  clock_out_lat double precision, clock_out_lng double precision,
  geofence_passed boolean, computed_minutes int, computed_wage numeric(12,2),
  created_at timestamptz not null default now()
);
create index idx_time_entries_hire on public.time_entries(hire_id);
create index idx_time_entries_sitter on public.time_entries(sitter_id);
-- Critical: at most one open time_entry per sitter (kills clock_in race condition)
create unique index uq_one_open_time_entry on public.time_entries(sitter_id)
  where clock_out_at is null;

-- system_config (values are JSON-encoded; readers go through cfg_bool/cfg_text/cfg_int)
create table public.system_config (
  key text primary key, value jsonb not null,
  updated_at timestamptz not null default now(), updated_by uuid references public.users(id)
);

-- chat
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  family_id uuid not null references public.family_profiles(user_id),
  sitter_id uuid not null references public.sitter_profiles(user_id),
  created_at timestamptz not null default now(), unique (job_id, sitter_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.users(id),
  body text not null check (char_length(body) between 1 and 4000),
  read_at timestamptz, created_at timestamptz not null default now()
);
create index idx_messages_conv_created on public.messages(conversation_id, created_at desc);

-- wallet
create table public.wallets (
  sitter_id uuid primary key references public.sitter_profiles(user_id) on delete cascade,
  available_balance numeric(12,2) not null default 0 check (available_balance >= 0),
  pending_balance numeric(12,2) not null default 0 check (pending_balance >= 0),
  lifetime_earnings numeric(12,2) not null default 0 check (lifetime_earnings >= 0),
  updated_at timestamptz not null default now()
);

create table public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  sitter_id uuid not null references public.wallets(sitter_id) on delete cascade,
  type public.ledger_type not null, amount numeric(12,2) not null,
  reference_type text, reference_id uuid,
  balance_after numeric(12,2) not null, created_at timestamptz not null default now()
);
create index idx_ledger_sitter on public.ledger_entries(sitter_id, created_at desc);

create table public.withdrawal_requests (
  id uuid primary key default gen_random_uuid(),
  sitter_id uuid not null references public.wallets(sitter_id) on delete cascade,
  amount numeric(12,2) not null check (amount > 0),
  method text not null, account_info jsonb default '{}',
  status text not null default 'pending',
  requested_at timestamptz not null default now(),
  paid_at timestamptz, paid_by uuid references public.users(id)
);

-- notifications
create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  fcm_token text not null, platform text not null default 'android',
  last_seen_at timestamptz not null default now(), unique (user_id, fcm_token)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  type text not null, title text, body text, data jsonb default '{}',
  read_at timestamptz, created_at timestamptz not null default now()
);
create index idx_notif_user on public.notifications(user_id, created_at desc);

-- admin + audit
create table public.admin_users (
  id uuid primary key references public.users(id) on delete cascade,
  permissions text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.users(id) on delete set null,
  action text not null, entity_type text, entity_id uuid,
  before_state jsonb, after_state jsonb,
  ip_address inet, user_agent text,
  created_at timestamptz not null default now()
);
create index idx_audit_entity on public.audit_logs(entity_type, entity_id);
create index idx_audit_created on public.audit_logs(created_at desc);

-- seed
insert into public.age_wage_tiers (min_age, max_age, hourly_rate, effective_from) values
  (11, 12, 8.00, '2026-01-01'),
  (13, 14, 10.00, '2026-01-01'),
  (15, 16, 12.00, '2026-01-01'),
  (17, 17, 14.00, '2026-01-01');

insert into public.system_config (key, value) values
  ('min_sitter_age',             '11'::jsonb),
  ('max_sitter_age',             '17'::jsonb),
  ('default_geofence_radius_m',  '150'::jsonb),
  ('geofence_hard_block',        'false'::jsonb),
  ('platform_fee_pct',           '0'::jsonb),
  ('fcm_provider',               '"mock"'::jsonb),
  ('email_provider',             '"mock"'::jsonb),
  ('email_from',                 '"StarSitters <noreply@starsitters.app>"'::jsonb)
on conflict (key) do nothing;
```

---

## 30. Appendix B — Full RLS (Runnable Block)

See Section 6 above — all policies are consolidated there and written as runnable SQL. Copy Section 6's SQL block in full and run it after the schema is deployed.

---

---

## 31. Admin Web Application — Complete Technical Breakdown

**Repository:** `StarSitters_Admin/starsitters-admin/` (cloned from `naqiiabbas/StarSitters`)  
**Live URL:** `star-sitters.vercel.app` (deployed on Vercel, 2 production deployments recorded)  
**Tech Stack:** Next.js 16, React 19, TypeScript 5, Tailwind CSS v4, Recharts 3, Lucide React 1.8, deployed on Vercel

---

### 31.1 What the Admin App IS Right Now

The current codebase is a **fully designed, pixel-perfect UI shell**. Every single page, modal, table, chart, and component is built out with real TypeScript types and realistic mock data. **Zero Supabase calls exist anywhere in the codebase today.** The app is:

- Statically rendered with hardcoded mock arrays inside each page component
- Actions (approve/reject/resolve) only mutate local React `useState` — nothing persists
- Authentication is a fake timeout that always succeeds and pushes to `/dashboard`
- Logout pushes to `/` with no session destruction

This means the admin app is a **demo-ready shell awaiting backend wiring**. The UI contract is complete and correct. The backend work is to replace every mock array and every action handler with real Supabase calls.

---

### 31.2 Repository & File Map

```
starsitters-admin/
├── src/
│   ├── app/
│   │   ├── (auth)/                      ← Auth route group (no sidebar/header)
│   │   │   ├── page.tsx                 ← /  — Login page
│   │   │   ├── forgot-password/page.tsx ← /forgot-password
│   │   │   └── reset-password/page.tsx  ← /reset-password
│   │   ├── (dashboard)/                 ← Dashboard route group (sidebar + header)
│   │   │   ├── layout.tsx               ← Shell: Sidebar + Header + mobile overlay
│   │   │   ├── dashboard/page.tsx       ← Overview stats + charts + recent onboarding
│   │   │   ├── families/page.tsx        ← Family management + approve/reject
│   │   │   ├── babysitters/page.tsx     ← Babysitter management + profiles
│   │   │   ├── certifications/page.tsx  ← Course list + certification approvals (tabbed)
│   │   │   ├── courses/page.tsx         ← Course CRUD management
│   │   │   ├── courses/create/page.tsx  ← Create new course form
│   │   │   ├── jobs/page.tsx            ← Jobs monitoring + timeline view
│   │   │   ├── wages/page.tsx           ← Age-based wage config + examples
│   │   │   ├── reports/page.tsx         ← Full analytics (bar/line/pie + tables)
│   │   │   ├── disputes/page.tsx        ← Dispute management + resolution
│   │   │   ├── notifications/page.tsx   ← Notification delivery logs
│   │   │   └── settings/page.tsx        ← Platform/security/data/audit tabs
│   │   ├── layout.tsx                   ← Root layout: Inter font, globals.css
│   │   └── globals.css                  ← Tailwind base + custom-scrollbar class
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx              ← Fixed 280px sidebar, active route highlight
│   │   │   ├── Header.tsx               ← Fixed topbar, search, notif bell, profile
│   │   │   ├── ProfileDropdown.tsx      ← Profile popover
│   │   │   └── NotificationPanel.tsx    ← Notification slide-in panel
│   │   └── ui/                          ← 26 modal components (see §31.3)
│   └── hooks/
│       └── useMediaQuery.ts             ← Responsive breakpoint hook
├── public/
│   ├── login-bg.png                     ← Full-screen starry background
│   ├── star-sitters-logo.png            ← Logo (used in sidebar + auth pages)
│   └── logo.png                         ← Secondary logo asset
├── next.config.ts                       ← Turbopack enabled
├── package.json                         ← name: "onlygigz-admin" (stale, rename later)
└── tsconfig.json
```

**Note:** `package.json` still says `"name": "onlygigz-admin"` — this is a leftover from the project's origin. It has no functional impact but should be renamed to `"starsitters-admin"` before production.

---

### 31.3 Complete Modal Inventory (26 Modals)

Every modal is in `src/components/ui/`. Each is a standalone client component accepting `isOpen`, `onClose`, `data`, and action callbacks:

| Modal | Purpose | Current Action |
|---|---|---|
| `OnboardingDetailsModal` | View family/sitter onboarding detail | Read-only |
| `BabysitterDetailsModal` | Full sitter profile + certifications + guardian | Read-only |
| `FamilyDetailsModal` | Full family profile + documents + background check | Read-only |
| `ApproveVerificationModal` | Confirm family approval | Updates local state |
| `RejectVerificationModal` | Confirm family rejection + reason | Updates local state |
| `ApproveCertificationModal` | Confirm cert approval (name + course + score) | Updates local state |
| `RejectCertificationModal` | Confirm cert rejection + reason | Updates local state |
| `CertificationSubmissionDetailsModal` | View cert submission detail | Read-only + opens sub-modals |
| `CourseDetailsModal` | Course profile view | Read-only |
| `ViewCourseModal` | Course detail + status change + edit trigger | Updates local state |
| `EditCourseModal` | Full course edit form | Updates local state |
| `DeleteCourseModal` | Confirm course delete (shows enrolled count) | Updates local state |
| `JobDetailsModal` | Job detail + timeline + location + wage | Read-only |
| `DisputeDetailsModal` | Dispute detail + message thread + resolve/escalate | Updates local state |
| `PaymentActionModal` | Payment action confirmation | Local only |
| `TransactionDetailsModal` | Transaction detail view | Read-only |
| `NotificationDetailsModal` | Notification detail | Read-only |
| `UserProfileModal` | Generic user profile | Read-only |
| `ContractHistoryModal` | Job contract history list | Read-only |
| `ViewContractModal` | Single contract detail | Read-only |
| `ConfirmationModal` | Generic yes/no confirmation | Callback |
| `SendWarningModal` | Send warning to user (message + reason) | Local only |
| `SuspendUserModal` | Suspend user (reason + duration) | Local only |
| `RevokePlacementModal` | Revoke job placement | Local only |
| `RemoveReviewModal` | Remove a review (reason required) | Local only |
| `Toast` | Global toast notification component | Utility |

**Also present (vestigial, must be deleted Day 6):**

These five modals are leftover from the `onlygigz` origin project — they
reference `scrapers` and `gigs`, concepts that do not exist in Star Sitters.
Delete them on Day 6 step 0 along with any imports:

```bash
# from StarSitters_Admin/starsitters-admin/
rm src/components/ui/RunScraperModal.tsx
rm src/components/ui/ScraperDetailsModal.tsx
rm src/components/ui/EditScrapedGigModal.tsx
rm src/components/ui/EditGigModal.tsx
rm src/components/ui/GigDetailsModal.tsx

# Then grep for stale imports and remove them:
grep -rn "RunScraperModal\|ScraperDetailsModal\|EditScrapedGigModal\|EditGigModal\|GigDetailsModal" src/
```

Once removed, run `npm run build` to confirm no remaining references.

---

### 31.4 Page-by-Page Backend Wiring Requirements

#### `/` — Login Page
**Current state:** Fake `setTimeout` always succeeds. No credential check.  
**Required wiring:**
```typescript
// Replace handleSubmit with:
import { createClient } from '@/lib/supabase/client'

const supabase = createClient()
const { error } = await supabase.auth.signInWithPassword({ email, password })
if (error) { setError(error.message); return; }
router.push('/dashboard')
```
**Security rules:**
- Only users in `public.admin_users` table must be allowed through
- After login, middleware must check `admin_users` membership before allowing dashboard access
- Lock out after 5 failed attempts (Supabase Auth rate limiting is built-in)

---

#### `/forgot-password` and `/reset-password`
**Current state:** Admin app (`starsitters-admin`) uses `resetPasswordForEmail` (forgot-password) and `updateUser({ password })` (reset-password). Configure Supabase Auth **Site URL**, **Redirect URLs** (include `/reset-password`), and email (SMTP or built-in) in the Supabase dashboard.  
**Reference wiring:**
```typescript
// forgot-password:
await supabase.auth.resetPasswordForEmail(email, {
  redirectTo: `${window.location.origin}/reset-password`
})

// reset-password:
await supabase.auth.updateUser({ password: newPassword })
```

---

#### `/dashboard` — Overview
**Current state:** All stats are hardcoded strings (`"247"`, `"235"`, etc.). Charts use static arrays.  
**Required wiring (Supabase RPCs):**

**Dashboard stats RPC:** the canonical version is in §31.6.1 — do not redeclare it
here. The page calls `supabase.rpc('admin_dashboard_stats')` and renders the
returned JSON object. Extend that RPC if more counters are needed; do not
add a parallel one. The label mapping for the UI cards is:

| UI card label | jsonb key from `admin_dashboard_stats()` |
|---|---|
| Total Families | `families_total` |
| Pending Verification | `families_pending_bg` |
| Verified Families | `families_approved_bg` |
| Total Babysitters | `sitters_total` |
| Active Babysitters | `sitters_active` |
| Pending Consent | `sitters_pending_consent` |
| Pending Cert Reviews | `certs_pending` |
| Open Jobs | `jobs_open` |
| Jobs in progress | `jobs_active` (`jobs.status = 'active'`) |
| Completed (30d) | `jobs_completed_30d` |
| Open Disputes | `disputes_open` |
| Pending Withdrawals | `withdrawals_pending` |

For trend charts, add small read-only RPCs:

```sql
create or replace function public.admin_registration_trend(p_months int default 6)
returns table (month date, families bigint, sitters bigint)
language sql security definer set search_path = public as $$
  select date_trunc('month', u.created_at)::date as month,
         count(*) filter (where u.role = 'family') as families,
         count(*) filter (where u.role = 'sitter') as sitters
    from public.users u
   where u.created_at > now() - make_interval(months => p_months)
   group by 1
   order by 1;
$$;
revoke execute on function public.admin_registration_trend(int) from public;
grant   execute on function public.admin_registration_trend(int) to authenticated;
-- The /api route calls admin_only() before invoking; safe to expose to authed.
```

Recent onboarding table = `select u.*, fp.bg_check_status from public.users u left join public.family_profiles fp on fp.user_id = u.id order by u.created_at desc limit 20` (sitter side analogous).

---

#### `/families` — Family Management
**Current state:** Static 5-family array. Approve/reject updates `useState` only.
**Required wiring (uses BASE schema column `bg_check_status`):**

```typescript
// fetch
const { data } = await supabase
  .from('family_profiles')
  .select('user_id, home_address, bg_check_status, rejection_reason, '
        + 'users:user_id (id, full_name, email, phone, created_at), '
        + 'documents:uploaded_documents!user_id (id, document_name, uploaded_at)')
  .order('updated_at', { ascending: false })
  .limit(50);

// approve / reject
await supabase.rpc('admin_approve_family', { p_user_id: row.user_id });
await supabase.rpc('admin_reject_family', { p_user_id: row.user_id, p_reason: reason });
```

The RPCs are defined once in §31.6.1 — do not redefine here. The UI maps
the label "Verification Status" to `bg_check_status` and renders the
`verification_status` enum values (`not_submitted | pending | approved | rejected`)
through a small lookup in `src/lib/labels.ts`.

---

#### `/babysitters` — Babysitter Management
**Current state:** Static 5-sitter array. Eye button opens read-only modal.
**Required wiring (uses BASE columns: `is_active`, `guardian_consent_status`,
`total_minutes_worked`, `total_earnings` from §5 Migration 5):**

```typescript
const { data } = await supabase
  .from('sitter_profiles')
  .select('user_id, date_of_birth, bio, is_active, guardian_consent_status, '
        + 'total_minutes_worked, total_earnings, suspension_reason, suspended_until, '
        + 'users:user_id (id, full_name, email, phone, created_at), '
        + 'certs:certifications!sitter_id (id, cert_type, status, expires_at), '
        + 'consent:guardian_consents!sitter_id (id, guardian_email, consent_given_at)')
  .order('updated_at', { ascending: false })
  .limit(50);

// Suspend
await supabase.rpc('admin_suspend_sitter', {
  p_user_id: row.user_id, p_reason: reason, p_until: optionalDate,
});
```

The "Account status" filter the UI shows is computed in the client from base
columns:

```typescript
// src/lib/labels.ts
export function sitterAccountStatus(p: SitterProfile): 'active'|'pending'|'suspended' {
  if (p.is_active) return 'active';
  if (p.suspended_until && new Date(p.suspended_until) > new Date()) return 'suspended';
  return 'pending';
}
```

---

#### `/certifications` — Certifications & Training
**Current state:** Tabbed page. "Course Management" tab lists 4 static courses.
"Certification Approvals" tab lists 10 static submissions.

The `courses` and `certification_submissions` tables are already defined in
§31.6 (canonical) — do not redeclare schema here. Wiring:

**Courses tab:**
- `select * from courses order by created_at desc` (RLS allows admin read)
- Create / edit / archive: direct `INSERT` / `UPDATE` (admins satisfy the
  RLS write policy in §31.7)

**Certification Approvals tab:**
- Read joined view:
  `select cs.*, u.full_name, c.name as course_name from certification_submissions cs
   join users u on u.id = cs.sitter_id
   join courses c on c.id = cs.course_id
   where cs.status = 'pending'`
- Approve → call existing `admin_approve_certification(p_cert_id, 'approved', notes)` (§7) — wires the same RPC the Friday demo uses
- Reject → `admin_approve_certification(p_cert_id, 'rejected', notes)`

---

#### `/courses` and `/courses/create` — Course Management
**Current state:** Full CRUD UI exists — view, edit, delete, create all have modals/pages. Currently mutates local state only.  
**Required wiring:**
- `GET` courses → `SELECT * FROM courses ORDER BY created_at DESC`
- Create → `INSERT INTO courses (...) VALUES (...)`
- Update → `UPDATE courses SET ... WHERE id = ?`
- Delete → `DELETE FROM courses WHERE id = ?`
- Status change (Draft → Active → Archived) → `UPDATE courses SET status = ? WHERE id = ?`
- All writes go through admin-only RPCs or `SECURITY DEFINER` functions with `admin_only()` check

---

#### `/jobs` — Jobs Monitoring
**Current state:** Static 5-job array. Status enum aligns with §5 base: `open | hired | active | completed | cancelled`.

The UI label "In Progress" maps to `jobs.status = 'active'` — do not introduce an `in_progress` value.

```sql
-- admin_list_jobs(p_status_filter text, p_search text, p_page int, p_page_size int)
-- Returns jobs joined to the family (jobs.family_id → family_profiles.user_id)
-- and the optional hire (hires.job_id → jobs.id, hires.sitter_id → sitter_profiles.user_id).
-- jobs has NO direct sitter_id column — the relation is through hires.
create or replace function public.admin_list_jobs(
  p_status_filter text default 'all',
  p_search        text default '',
  p_page          int  default 1,
  p_page_size     int  default 20
)
returns table (
  job_id          uuid,
  family_name     text,
  sitter_name     text,
  job_date        date,
  status          text,
  computed_minutes int,
  computed_wage   numeric(12,2),
  timeline        jsonb
)
language sql security definer set search_path = public as $$
  with rows as (
    select j.id as job_id,
           fu.full_name as family_name,
           su.full_name as sitter_name,
           j.date as job_date,
           j.status::text as status,
           te.computed_minutes,
           te.computed_wage,
           j.created_at,
           coalesce(
             jsonb_agg(
               jsonb_build_object(
                 'event_type', jt.event_type,
                 'title',      jt.title,
                 'created_at', jt.created_at
               ) order by jt.created_at
             ) filter (where jt.id is not null),
             '[]'::jsonb
           ) as timeline
      from public.jobs j
      join public.family_profiles fp on fp.user_id = j.family_id
      join public.users fu          on fu.id = fp.user_id
      left join public.hires h         on h.job_id = j.id
      left join public.sitter_profiles sp on sp.user_id = h.sitter_id
      left join public.users su         on su.id = sp.user_id
      left join public.time_entries te  on te.hire_id = h.id and te.clock_out_at is not null
      left join public.job_timeline_events jt on jt.job_id = j.id
     where (p_status_filter = 'all' or j.status::text = p_status_filter)
       and (p_search = ''
            or fu.full_name ilike '%' || p_search || '%'
            or coalesce(su.full_name,'') ilike '%' || p_search || '%'
            or j.id::text = p_search)
     group by j.id, fu.full_name, su.full_name, te.computed_minutes, te.computed_wage
     order by j.created_at desc
     limit p_page_size offset (p_page - 1) * p_page_size
  )
  select * from rows;
$$;
revoke execute on function public.admin_list_jobs(text,text,int,int) from public;
grant   execute on function public.admin_list_jobs(text,text,int,int) to authenticated;
-- The middleware enforces admin role; the function does NOT bypass RLS for
-- writes (it's read-only), and on read it joins tables the admin already has
-- read RLS on via §6 admin policies.
```

The `job_timeline_events` table is defined once in §31.6 (canonical). UI maps
DB event_type values to display labels:

```typescript
// src/lib/eventLabels.ts
export const EVENT_LABEL: Record<string, string> = {
  posted:    'Job posted',
  hired:     'Sitter hired',
  clock_in:  'Clocked in',
  clock_out: 'Clocked out',
  completed: 'Completed',
  cancelled: 'Cancelled',
  disputed:  'Dispute opened',
  resolved:  'Dispute resolved',
};
```

---

#### `/wages` — Wage Configuration
**Current state:** Fully functional local-only UI. Admin sets age-tier rates (11-12, 13-14, 15-17), time rounding rule, overtime rule. Save button only updates React state.  
**Required wiring:**
- Load current rates → `SELECT min_age, max_age, hourly_rate FROM age_wage_tiers WHERE effective_from <= now() ORDER BY min_age`
- Save rates → `admin_update_wage_tiers(rates jsonb)` RPC (atomic replace: delete old, insert new with new `effective_from`)
- Time rounding rule + overtime rule → `system_config` table rows: `time_rounding_rule`, `overtime_rule`

```sql
create or replace function admin_update_wage_tiers(p_rates jsonb)
returns void language plpgsql security definer as $$
declare
  rate jsonb;
begin
  perform admin_only();
  -- snapshot old rates before replacing
  insert into audit_logs (actor_id, action, entity_type, before_state)
  select auth.uid(), 'update_wage_tiers', 'age_wage_tiers',
         json_agg(row_to_json(awt))::jsonb
  from age_wage_tiers awt;
  -- insert new effective rates
  for rate in select * from jsonb_array_elements(p_rates)
  loop
    insert into age_wage_tiers (min_age, max_age, hourly_rate, effective_from)
    values (
      (rate->>'min_age')::int,
      (rate->>'max_age')::int,
      (rate->>'hourly_rate')::numeric,
      now()
    );
  end loop;
end;
$$;
```

This is critical: wage tier changes must be **append-only** (never delete old tiers — jobs already completed reference the rate that was active when they ran). The `clock_out` RPC snaps the rate at hire time.

---

#### `/reports` — Analytics
**Current state:** Six charts with static data arrays. Period selector and export buttons are UI-only.  
**Required wiring (all via RPCs):**

```sql
-- admin_report_jobs_per_month(months int) → [{month, jobs}]
-- admin_report_hours_per_month(months int) → [{month, hours}]
-- admin_report_wage_distribution() → [{name, value}] grouped by age tier
-- admin_report_job_status_distribution() → [{name, value}]
-- admin_report_user_growth(months int) → [{month, families, babysitters}]
-- admin_report_cert_stats() → {approval_rate, avg_processing_days, most_popular_course}
-- admin_report_summary(months int) → {total_revenue, total_jobs, total_hours, avg_duration}
```

Export CSV/PDF → Next.js API routes:
```
/api/admin/reports/export?format=csv&type=jobs&period=6months
/api/admin/reports/export?format=pdf&type=revenue&period=6months
```
These routes must be protected by admin session middleware.

---

#### `/disputes` — Dispute Management
**Current state:** 4 static disputes. Resolve updates `useState` with resolution notes.

The `disputes` table and the two admin RPCs (`admin_resolve_dispute`,
`admin_update_dispute_status`) are defined once in §31.6 and §31.6.1.
**Do not redeclare here.** Note: `disputes.reported_by_role` uses the
canonical `public.user_role` enum (`'family' | 'sitter'`), not `'babysitter'`.

```typescript
// fetch
const { data } = await supabase
  .from('disputes')
  .select('id, job_id, issue_type, priority, status, description, '
        + 'reported_by_user_id, reported_by_role, created_at, '
        + 'reporter:reported_by_user_id (full_name, email), '
        + 'job:job_id (id, date, status)')
  .order('created_at', { ascending: false })
  .limit(50);

// resolve
await supabase.rpc('admin_resolve_dispute', {
  p_dispute_id: row.id,
  p_notes: notes,
});

// update status (move open → investigating)
await supabase.rpc('admin_update_dispute_status', {
  p_dispute_id: row.id,
  p_status: 'investigating',
});
```

Disputes can also be **raised from the Flutter apps**: a family or sitter
taps "Report Issue" on a completed job → INSERT into `disputes` (the §31.7
RLS policy permits the reporter's own insert). The admin sees it in real
time via the Supabase Realtime subscription in §31.13.

---

#### `/notifications` — Notification Logs
**Current state:** 6 static log rows with delivery statuses.

The `delivery_status`, `trigger_type`, and `fcm_message_id` columns are
already declared once in §31.6 (#8). Do not redeclare here.

```typescript
// fetch the latest 200 notifications joined with the recipient user
const { data } = await supabase
  .from('notifications')
  .select('id, type, title, body, delivery_status, trigger_type, '
        + 'fcm_message_id, read_at, created_at, '
        + 'recipient:user_id (id, email, full_name, role)')
  .order('created_at', { ascending: false })
  .limit(200);
```

Delivery receipts: when the `send_push` Edge Function (§8.1) gets an FCM
response with a `name` (FCM message ID), it should `update notifications
set fcm_message_id = '...', delivery_status = 'delivered'` for that row
using `record.id` as the key. Failed sends set `delivery_status = 'failed'`.

---

#### `/settings` — System Settings
**Current state:** Four tabs (Platform, Security, Data, Audit Log). All toggles and selects update local state. Audit log table is hardcoded.  
**Required wiring:**

**Platform tab:**  
Every configurable value maps to `system_config` table:
- `system_notifications_enabled` → `true/false`
- `auto_verification_enabled` → `true/false`
- `min_sitter_age` → integer
- `max_job_duration_hours` → integer
- `gps_tracking_mode` → `required/optional/disabled`

Save → `admin_update_system_config(configs jsonb)` RPC

**Security tab:**  
Supabase Auth rate limiting handles login attempts. Session timeout and 2FA settings map to `system_config` as display/reference values. True 2FA enforcement requires Supabase MFA (TOTP) — enable in Supabase dashboard.

**Audit Log tab:**  
Wire to real `audit_logs` table:
```sql
SELECT al.created_at, u.email as admin, al.action, al.entity_type
FROM audit_logs al
LEFT JOIN users u ON u.id = al.actor_id
ORDER BY al.created_at DESC
LIMIT 100;
```

---

### 31.5 Admin Auth Architecture

The current login page has zero security. Here is the complete secure auth architecture:

#### Admin User Provisioning
Admins are NOT self-registered. They are provisioned manually:
```sql
-- 1. Create auth user in Supabase dashboard
-- 2. Insert into admin_users:
insert into public.admin_users (id, permissions)
values ('supabase-auth-user-uuid', ARRAY['all']);
```

#### Next.js Middleware (the security gate)

Create `src/middleware.ts`:
```typescript
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  const response = NextResponse.next({ request })
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { cookies: { /* cookie handlers */ } }
  )

  const { data: { user } } = await supabase.auth.getUser()
  const isAuthPage = request.nextUrl.pathname === '/' ||
                     request.nextUrl.pathname.startsWith('/forgot-password') ||
                     request.nextUrl.pathname.startsWith('/reset-password')

  if (!user && !isAuthPage) {
    return NextResponse.redirect(new URL('/', request.url))
  }

  if (user && !isAuthPage) {
    // Verify admin_users membership
    const { data: admin } = await supabase
      .from('admin_users')
      .select('id')
      .eq('id', user.id)
      .single()
    if (!admin) {
      await supabase.auth.signOut()
      return NextResponse.redirect(new URL('/', request.url))
    }
  }

  if (user && isAuthPage && request.nextUrl.pathname === '/') {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  return response
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.png$).*)'],
}
```

#### Supabase Client Utilities
Create `src/lib/supabase/client.ts` (browser) and `src/lib/supabase/server.ts` (SSR):
```typescript
// client.ts — for Client Components
import { createBrowserClient } from '@supabase/ssr'
export const createClient = () =>
  createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )

// server.ts — for Server Components / middleware
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
export const createServerSupabaseClient = async () => {
  const cookieStore = await cookies()
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { cookies: { getAll: () => cookieStore.getAll(), setAll: (c) => c.forEach(({ name, value, options }) => cookieStore.set(name, value, options)) } }
  )
}
```

#### Single source of truth for the admin gate

The `admin_users` table is the trust boundary. The helper function is defined
**once** in §5 Migration 12 — `public.admin_only()`. Do not redefine it here.

```sql
-- already defined in 20260501000015_helpers.sql (§5 Migration 12):
--   public.admin_only()      raises 42501 if not admin       (use in RPCs)
--   public.admin_only_bool() returns boolean                 (use in triggers)
--   public.is_admin()        alias of admin_only_bool()      (legacy/RLS)
--
-- Every admin RPC starts with:
--   perform public.admin_only();
--   perform set_config('app.bypass_immutability', 'true', true);
```

The middleware above ALSO enforces admin membership at the HTTP layer — even
when the browser sends a valid Supabase session JWT, if the user is not in
`admin_users`, the middleware signs them out and redirects to `/`. The
Postgres `admin_only()` is the second layer; the middleware is the first.

All `SECURITY DEFINER` RPCs callable from the admin panel call `perform admin_only();` as their first statement.

---

### 31.6 Admin-Specific Schema Additions (Delta from Section 5)

This is the **single source of truth** for the column and table additions
the admin web app needs on top of the base schema in §5. Every column name
here matches what the admin UI mocks display — when the UI says
"Background Check Status," it reads `family_profiles.bg_check_status`, the
same column the family Flutter app reads (defined in Migration 4 of §5).
We do **not** introduce parallel-named columns. The admin UI labels are
mapped to base columns in `src/lib/labels.ts` (one file in the admin repo).

**Migration order for the repo (matches §3 layout):**
1. Migrations 1-11 (§5 base schema) — including `bg_check_status` and
   `is_active` already defined there.
2. Migration 12 — helpers (`admin_only`, `write_audit_log`, `cfg_*`).
3. Migration §31.6 — admin schema additions (this section).
4. Migration 13 — immutability triggers (depends on `bg_check_status`).
5. Migration 14 — sitter aggregate trigger (depends on
   `total_minutes_worked` / `total_earnings` columns added below in
   §5 Migration 5).
6. RLS, base RPCs, admin RPCs.

```sql
-- 20260501000017_admin_schema.sql

-- ============================================================
-- 1. Family profile additions for the admin verification workflow.
--    bg_check_status is the existing column from §5 Migration 4. We add
--    rejection_reason + home_address. NOTHING ELSE.
-- ============================================================
alter table public.family_profiles
  add column if not exists rejection_reason text,
  add column if not exists home_address     text;

-- ============================================================
-- 2. Documents uploaded by families during verification.
--    FK on the actual PK of family_profiles, which is `user_id`.
-- ============================================================
create table if not exists public.uploaded_documents (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.users(id) on delete cascade,
  -- the family or sitter who uploaded the doc
  doc_kind      text not null
    check (doc_kind in ('bg_check','cert','consent_form','other')),
  document_name text not null,
  storage_path  text not null,
  uploaded_at   timestamptz not null default now()
);
create index idx_uploaded_documents_user on public.uploaded_documents(user_id, uploaded_at desc);

-- ============================================================
-- 3. Sitter profile additions: suspension fields. The aggregate columns
--    total_minutes_worked + total_earnings are already in §5 Migration 5.
--    We do NOT introduce account_status — the base column is_active
--    (Migration 5) is the single source of truth. The admin UI maps:
--        is_active = true                                  → "Active"
--        is_active = false AND suspended_until > now()     → "Suspended"
--        is_active = false AND suspended_until is null     → "Pending"
--    The mapping lives in src/lib/labels.ts in the admin repo.
-- ============================================================
alter table public.sitter_profiles
  add column if not exists suspension_reason text,
  add column if not exists suspended_until   timestamptz;

-- ============================================================
-- 4. Courses (managed by admin, taken by sitters)
-- ============================================================
create table if not exists public.courses (
  id                    uuid primary key default gen_random_uuid(),
  name                  text not null,
  category              text not null default 'General',
  status                text not null default 'draft'
    check (status in ('published','draft','archived')),
  description           text,
  modules               text[] not null default '{}',
  instructor            text,
  duration_hours        numeric(4,1),
  level                 text check (level in ('Beginner','Intermediate','Advanced')),
  price                 numeric(8,2) not null default 0,
  requirements          text,
  learning_objectives   text,
  provides_certificate  boolean not null default true,
  created_by            uuid references public.users(id),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create trigger trg_courses_updated_at
  before update on public.courses
  for each row execute function public.touch_updated_at();

-- ============================================================
-- 5. Certification submissions by sitters.
--    sitter_id references sitter_profiles(user_id), not a fictional
--    sitter_profiles.sitter_id PK. (sitter_profiles' PK is user_id.)
-- ============================================================
create table if not exists public.certification_submissions (
  id                  uuid primary key default gen_random_uuid(),
  sitter_id           uuid not null
                       references public.sitter_profiles(user_id) on delete cascade,
  course_id           uuid not null references public.courses(id) on delete cascade,
  score               numeric(5,2),
  questions_answered  int,
  correct_answers     int,
  time_taken_seconds  int,
  status              public.verification_status not null default 'pending',
  -- reuses the §5 enum rather than a parallel TEXT enum
  rejection_reason    text,
  submitted_at        timestamptz not null default now(),
  reviewed_at         timestamptz,
  reviewed_by         uuid references public.users(id),
  unique (sitter_id, course_id)  -- one submission per course; allow retakes via UPSERT
);
create index idx_cert_submissions_status
  on public.certification_submissions(status, submitted_at desc);

-- ============================================================
-- 6. Disputes. reported_by_role uses the SAME enum as user_role
--    ('family' | 'sitter') — no 'babysitter' synonym.
-- ============================================================
create table if not exists public.disputes (
  id                  uuid primary key default gen_random_uuid(),
  job_id              uuid not null references public.jobs(id) on delete cascade,
  reported_by_user_id uuid not null references public.users(id),
  reported_by_role    public.user_role not null
    check (reported_by_role in ('family','sitter')),
  issue_type          text not null
    check (issue_type in ('time_discrepancy','payment_issue','no_show','safety_concern','other')),
  description         text,
  priority            text not null default 'medium'
    check (priority in ('low','medium','high')),
  status              text not null default 'open'
    check (status in ('open','investigating','resolved')),
  resolution_notes    text,
  resolved_by         uuid references public.users(id),
  resolved_at         timestamptz,
  created_at          timestamptz not null default now()
);
create index idx_disputes_status on public.disputes(status, created_at desc);
create index idx_disputes_job    on public.disputes(job_id);

-- ============================================================
-- 7. Job timeline events. event_type is snake_case in the DB; the admin UI
--    maps DB values to display labels via src/lib/eventLabels.ts. The set
--    of values matches the §5 job_status enum plus per-clock events.
-- ============================================================
create table if not exists public.job_timeline_events (
  id          uuid primary key default gen_random_uuid(),
  job_id      uuid not null references public.jobs(id) on delete cascade,
  event_type  text not null
    check (event_type in (
      'posted','hired','clock_in','clock_out',
      'completed','cancelled','disputed','resolved'
    )),
  title       text,
  actor_id    uuid references public.users(id),
  created_at  timestamptz not null default now()
);
create index idx_timeline_job on public.job_timeline_events(job_id, created_at asc);

-- ============================================================
-- 8. Notification delivery tracking
-- ============================================================
alter table public.notifications
  add column if not exists delivery_status text not null default 'sent'
    check (delivery_status in ('sent','delivered','failed')),
  add column if not exists trigger_type    text,
  add column if not exists fcm_message_id  text;

-- ============================================================
-- 9. System config additions (JSON-encoded values per §5 convention)
-- ============================================================
insert into public.system_config (key, value) values
  ('system_notifications_enabled', 'true'::jsonb),
  ('auto_verification_enabled',    'false'::jsonb),
  ('gps_tracking_mode',            '"required"'::jsonb),
  ('time_rounding_rule',           '"exact"'::jsonb),
  ('overtime_rule',                '"disabled"'::jsonb),
  ('session_timeout_minutes',      '30'::jsonb),
  ('max_login_attempts',           '5'::jsonb),
  ('data_retention_months',        '24'::jsonb)
on conflict (key) do nothing;

-- ============================================================
-- 10. Trigger: auto-populate job_timeline_events when jobs.status flips.
--     Note: §5 job_status enum is canonical — uses 'active' (not 'in_progress').
-- ============================================================
create or replace function public.fn_jobs_timeline_trigger()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  if old.status is distinct from new.status then
    insert into public.job_timeline_events (job_id, event_type, title, actor_id)
    values (
      new.id,
      case new.status
        when 'open'      then 'posted'
        when 'hired'     then 'hired'
        when 'active'    then 'clock_in'
        when 'completed' then 'completed'
        when 'cancelled' then 'cancelled'
        else new.status::text
      end,
      'Status changed to ' || new.status::text,
      auth.uid()
    );
  end if;
  return new;
end;
$$;

create trigger trg_jobs_timeline
  after update of status on public.jobs
  for each row execute function public.fn_jobs_timeline_trigger();
```

> **Two columns moved to §5 Migration 5** (sitter_profiles.total_minutes_worked
> and total_earnings) and the corresponding `fn_update_sitter_totals` trigger
> is defined in §5 Migration 14 — both already updated in this document.

### 31.6.1 Admin RPCs (corrected — match base schema)

```sql
-- 20260501000018_admin_rpcs.sql

-- ============================================================
-- admin_dashboard_stats() — single read used by the admin /dashboard page.
-- Uses ONLY columns from §5 + §31.6.
-- ============================================================
create or replace function public.admin_dashboard_stats()
returns jsonb
language sql security definer
set search_path = public as $$
  select jsonb_build_object(
    'families_total',        (select count(*) from public.family_profiles),
    'families_pending_bg',   (select count(*) from public.family_profiles
                              where bg_check_status = 'pending'),
    'families_approved_bg',  (select count(*) from public.family_profiles
                              where bg_check_status = 'approved'),

    'sitters_total',         (select count(*) from public.sitter_profiles),
    'sitters_active',        (select count(*) from public.sitter_profiles
                              where is_active = true),
    'sitters_pending_consent',(select count(*) from public.sitter_profiles
                              where guardian_consent_status = 'pending'),
    'certs_pending',         (select count(*) from public.certification_submissions
                              where status = 'pending'),

    'jobs_open',             (select count(*) from public.jobs where status = 'open'),
    'jobs_active',           (select count(*) from public.jobs where status = 'active'),
    'jobs_completed_30d',    (select count(*) from public.jobs
                              where status = 'completed'
                                and updated_at > now() - interval '30 days'),

    'disputes_open',         (select count(*) from public.disputes where status = 'open'),
    'withdrawals_pending',   (select count(*) from public.withdrawal_requests
                              where status = 'pending')
  );
$$;
-- Wrap in admin gate at call site by checking admin_only_bool() in the
-- API route OR call from an RPC wrapper:
revoke execute on function public.admin_dashboard_stats from public;
grant execute on function public.admin_dashboard_stats to authenticated;
-- The middleware enforces admin role before invoking; for double safety the
-- /api route also calls admin_only() before this RPC.

-- ============================================================
-- admin_approve_family / admin_reject_family
-- ============================================================
create or replace function public.admin_approve_family(p_user_id uuid)
returns void
language plpgsql security definer
set search_path = public as $$
declare v_admin uuid := auth.uid();
begin
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  update public.family_profiles
     set bg_check_status = 'approved',
         rejection_reason = null
   where user_id = p_user_id;

  if not found then
    raise exception 'family_profile not found for user %', p_user_id;
  end if;

  perform public.write_audit_log(
    'admin_approve_family',
    'family_profiles',
    p_user_id,
    null,
    jsonb_build_object('approver_id', v_admin)
  );

  insert into public.notifications (user_id, type, title, body)
  values (p_user_id, 'bg_check_result',
          'Background check approved',
          'Your background check is approved. You can now post jobs.');
end;
$$;

create or replace function public.admin_reject_family(p_user_id uuid, p_reason text)
returns void
language plpgsql security definer
set search_path = public as $$
declare v_admin uuid := auth.uid();
begin
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  if p_reason is null or length(trim(p_reason)) < 5 then
    raise exception 'rejection reason must be at least 5 characters';
  end if;

  update public.family_profiles
     set bg_check_status  = 'rejected',
         rejection_reason = p_reason
   where user_id = p_user_id;

  if not found then
    raise exception 'family_profile not found for user %', p_user_id;
  end if;

  perform public.write_audit_log(
    'admin_reject_family',
    'family_profiles',
    p_user_id,
    null,
    jsonb_build_object('reason', p_reason, 'approver_id', v_admin)
  );

  insert into public.notifications (user_id, type, title, body)
  values (p_user_id, 'bg_check_result',
          'Background check rejected',
          'Reason: ' || p_reason);
end;
$$;

-- ============================================================
-- admin_suspend_sitter / admin_unsuspend_sitter
-- ============================================================
create or replace function public.admin_suspend_sitter(
  p_user_id uuid, p_reason text, p_until timestamptz default null
)
returns void
language plpgsql security definer
set search_path = public as $$
begin
  perform public.admin_only();
  perform set_config('app.bypass_immutability', 'true', true);

  update public.sitter_profiles
     set is_active = false,
         suspension_reason = p_reason,
         suspended_until   = p_until
   where user_id = p_user_id;

  perform public.write_audit_log(
    'admin_suspend_sitter', 'sitter_profiles', p_user_id, null,
    jsonb_build_object('reason', p_reason, 'until', p_until)
  );

  insert into public.notifications (user_id, type, title, body)
  values (p_user_id, 'account_suspended',
          'Your account is suspended',
          coalesce('Reason: ' || p_reason, 'Contact support for details.'));
end;
$$;

-- ============================================================
-- admin_update_wage_tiers — change tier rates.
-- effective_from defaults to TOMORROW so re-saving in the same day does
-- not violate the unique (min_age, max_age, effective_from) index.
-- ============================================================
create or replace function public.admin_update_wage_tiers(p_tiers jsonb)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_admin uuid := auth.uid();
  v_tier  jsonb;
  v_effective date := current_date + interval '1 day';
begin
  perform public.admin_only();

  if jsonb_typeof(p_tiers) <> 'array' then
    raise exception 'p_tiers must be a JSON array';
  end if;

  -- One transaction: insert new tier rows for tomorrow. Old rows stay
  -- (immutable history), the wage_engine reads the most-recent
  -- effective_from <= current_date for any given age — see §11.
  for v_tier in select jsonb_array_elements(p_tiers)
  loop
    insert into public.age_wage_tiers (
      min_age, max_age, hourly_rate, effective_from, created_by
    )
    values (
      (v_tier->>'min_age')::int,
      (v_tier->>'max_age')::int,
      (v_tier->>'hourly_rate')::numeric(10,2),
      v_effective,
      v_admin
    )
    on conflict (min_age, max_age, effective_from)
    do update set hourly_rate = excluded.hourly_rate,
                  created_by  = excluded.created_by;
  end loop;

  perform public.write_audit_log(
    'admin_update_wage_tiers', 'age_wage_tiers', null, null,
    jsonb_build_object('tiers', p_tiers, 'effective_from', v_effective)
  );
end;
$$;

-- ============================================================
-- admin_resolve_dispute / admin_update_dispute_status
-- ============================================================
create or replace function public.admin_resolve_dispute(
  p_dispute_id uuid, p_notes text
)
returns void
language plpgsql security definer
set search_path = public as $$
declare
  v_dispute public.disputes;
begin
  perform public.admin_only();

  select * into v_dispute from public.disputes
   where id = p_dispute_id and status <> 'resolved'
   for update;
  if not found then
    raise exception 'dispute not found or already resolved';
  end if;

  update public.disputes
     set status           = 'resolved',
         resolution_notes = p_notes,
         resolved_by      = auth.uid(),
         resolved_at      = now()
   where id = p_dispute_id;

  insert into public.job_timeline_events (job_id, event_type, title, actor_id)
  values (v_dispute.job_id, 'resolved', 'Dispute resolved', auth.uid());

  perform public.write_audit_log(
    'admin_resolve_dispute', 'disputes', p_dispute_id, null,
    jsonb_build_object('notes', p_notes)
  );

  insert into public.notifications (user_id, type, title, body)
  values (v_dispute.reported_by_user_id, 'dispute_resolved',
          'Your dispute has been resolved',
          coalesce(p_notes, 'See the job page for details.'));
end;
$$;

create or replace function public.admin_update_dispute_status(
  p_dispute_id uuid, p_status text
)
returns void
language plpgsql security definer
set search_path = public as $$
begin
  perform public.admin_only();
  if p_status not in ('open','investigating','resolved') then
    raise exception 'invalid status %', p_status;
  end if;

  update public.disputes set status = p_status where id = p_dispute_id;
  if not found then raise exception 'dispute not found'; end if;

  perform public.write_audit_log(
    'admin_update_dispute_status', 'disputes', p_dispute_id, null,
    jsonb_build_object('status', p_status)
  );
end;
$$;
```

---

### 31.7 RLS Policies for Admin Tables

All policies use `public.is_admin()` (alias of `admin_only_bool()`) for the
admin-side check — single source of truth for the helper, defined in §6.

```sql
-- 20260501000019_admin_rls.sql

-- admin_users: only readable by themselves; admin writes go through
-- migrations or Supabase Studio (not the admin web app).
alter table public.admin_users enable row level security;
create policy "Admin can read own row" on public.admin_users
  for select using (id = auth.uid());

-- courses: anyone signed in can read published courses (sitters browse them);
-- admins manage all course state (drafts, archive, etc.).
alter table public.courses enable row level security;
create policy "Anyone reads published courses" on public.courses
  for select using (status = 'published');
create policy "Admins read all courses" on public.courses
  for select using (public.is_admin());
create policy "Admins write courses" on public.courses
  for all using (public.is_admin())
  with check (public.is_admin());

-- certification_submissions: sitter sees own (sitter_id matches user_id);
-- admin sees all and may insert/update via admin RPCs.
alter table public.certification_submissions enable row level security;
create policy "Sitter sees own submissions" on public.certification_submissions
  for select using (sitter_id = auth.uid());
create policy "Sitter inserts own submissions" on public.certification_submissions
  for insert with check (sitter_id = auth.uid());
create policy "Admin reads all submissions" on public.certification_submissions
  for select using (public.is_admin());
create policy "Admin writes submissions" on public.certification_submissions
  for update using (public.is_admin())
  with check (public.is_admin());

-- disputes: the reporter sees their own; the OTHER party in the disputed job
-- also gets read access (so a sitter sees the dispute a family filed against
-- them and vice versa). Admin sees and manages everything.
alter table public.disputes enable row level security;
create policy "Reporter sees own disputes" on public.disputes
  for select using (reported_by_user_id = auth.uid());
create policy "Job parties see disputes on their jobs" on public.disputes
  for select using (
    exists (
      select 1 from public.jobs j
       left join public.hires h on h.job_id = j.id
      where j.id = disputes.job_id
        and (j.family_id = auth.uid() or h.sitter_id = auth.uid())
    )
  );
create policy "Admin sees all disputes" on public.disputes
  for select using (public.is_admin());
create policy "Reporter inserts own dispute" on public.disputes
  for insert with check (reported_by_user_id = auth.uid());
create policy "Admin writes disputes" on public.disputes
  for update using (public.is_admin())
  with check (public.is_admin());

-- uploaded_documents: the user who uploaded sees their own (user_id is
-- the actual PK reference). Admin sees all.
alter table public.uploaded_documents enable row level security;
create policy "Uploader sees own docs" on public.uploaded_documents
  for select using (user_id = auth.uid());
create policy "Uploader inserts own docs" on public.uploaded_documents
  for insert with check (user_id = auth.uid());
create policy "Admin sees all docs" on public.uploaded_documents
  for select using (public.is_admin());

-- job_timeline_events: job participants + admin. Note the family is the
-- job owner (jobs.family_id = user_id), and the sitter is found via
-- hires.sitter_id (jobs has no direct sitter column).
alter table public.job_timeline_events enable row level security;
create policy "Job participants read timeline" on public.job_timeline_events
  for select using (
    exists (
      select 1 from public.jobs j
       left join public.hires h on h.job_id = j.id
      where j.id = job_timeline_events.job_id
        and (j.family_id = auth.uid() or h.sitter_id = auth.uid())
    )
  );
create policy "Admin reads all timelines" on public.job_timeline_events
  for select using (public.is_admin());
-- Inserts/updates only via the fn_jobs_timeline_trigger or admin RPCs,
-- both of which run as SECURITY DEFINER and bypass RLS.
```

---

### 31.8 Admin-Specific API Routes (Next.js `/app/api/`)

The admin panel needs several routes beyond direct Supabase calls:

```
src/app/api/
├── admin/
│   ├── reports/
│   │   └── export/route.ts      ← CSV/PDF export endpoint
│   ├── notifications/
│   │   └── broadcast/route.ts   ← Send FCM to all users or filtered group
│   └── users/
│       └── suspend/route.ts     ← Suspend user + FCM push notify
```

All routes must verify admin session via Supabase server client before executing.

Example for broadcast notification:
```typescript
// src/app/api/admin/notifications/broadcast/route.ts
import { createServerSupabaseClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  const supabase = await createServerSupabaseClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { data: admin } = await supabase
    .from('admin_users').select('id').eq('id', user.id).single()
  if (!admin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

  const { title, body, role_filter } = await request.json()
  // Call send_push Edge Function or directly call FCM HTTP v1 API
  // ...
  return NextResponse.json({ success: true })
}
```

---

### 31.9 Critical Security Issues in Current Codebase

The current admin app has 10 critical / high security gaps. Each row below shows
where the corresponding fix is detailed in this document — implementing them
(in this order) is the Day-6 task list.

| # | Issue | Severity | Fix is in |
|---|---|---|---|
| 1 | **Login always succeeds** — fake `setTimeout`, no credential check | CRITICAL | §31.5 (`signInWithPassword` + `admin_users` check) |
| 2 | **No middleware route protection** — any URL is accessible without auth | CRITICAL | §31.5 (`src/middleware.ts`) |
| 3 | **No admin role check** — any logged-in Supabase user reaches the dashboard | CRITICAL | §31.5 (middleware queries `admin_users`) |
| 4 | **No CSRF protection** on API routes | HIGH | §31.8 (Next.js 16 SameSite cookie defaults; verify `secure` + `lax`) |
| 5 | **Hardcoded mock data** — production data invisible to admin | HIGH | §31.4 (all pages wired to Supabase) |
| 6 | **No session expiry** — 30-min UI timer in Settings is cosmetic | HIGH | §31.5 — Supabase Auth refresh-token TTL + idle timer |
| 7 | **`package.json` name is `onlygigz-admin`** — identity confusion | MEDIUM | §31.12 Day 6 step 0 (`npm pkg set name=starsitters-admin`) |
| 8 | **Scraper modals exist** — vestigial, wrong domain | MEDIUM | §31.3 lists the 5 files to delete |
| 9 | **No Content Security Policy header** | MEDIUM | §31.14 (CSP without `unsafe-eval`) |
| 10 | **No environment variables** — no `.env.local` in repo | HIGH | §31.10 (`.env.local` + Vercel project env) |

The middleware + auth wiring in §31.5 closes issues 1–3 in one Day-6 morning.

---

### 31.10 Environment Variables for Admin App

Create `StarSitters_Admin/starsitters-admin/.env.local` (never commit):
```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
NEXT_PUBLIC_APP_URL=https://star-sitters.vercel.app
```

On Vercel, these are set in Project Settings → Environment Variables. The `SERVICE_ROLE_KEY` must NEVER be exposed to the browser — it is only used in server-side API routes.

---

### 31.11 Dependencies to Install

The current `package.json` has no Supabase dependencies. Add:
```bash
cd StarSitters_Admin/starsitters-admin
npm install @supabase/ssr @supabase/supabase-js
```

No other dependencies are needed. Do NOT add `@supabase/auth-helpers-nextjs` — it is deprecated. Use `@supabase/ssr` only.

---

### 31.12 Admin App — Week-2 Wiring Sprint Plan (Days 6–10)

The admin web app sprint runs **after** the Friday Week-1 mobile demo, not in
parallel with it. Friday's demo uses Supabase Studio for any admin actions
(see §20 step 6). This insulates the mobile timeline from admin app risk and
gives a clean 5-day Week-2 to take the admin app from mock shell to production.

#### Day 6 — Step 0: Repository hygiene + Security First (~5 hours)
1. `cd StarSitters_Admin/starsitters-admin`
2. `npm pkg set name=starsitters-admin` (fixes stale `onlygigz-admin`)
3. Delete the 5 vestigial scraper modals (paths in §31.3)
4. Install dependencies: `npm install @supabase/ssr @supabase/supabase-js`
5. Create `src/lib/supabase/client.ts` + `src/lib/supabase/server.ts` (§31.5)
6. Create `src/middleware.ts` with admin route protection (§31.5)
7. Wire Login page to `supabase.auth.signInWithPassword` + `admin_users` check
8. Wire Forgot Password / Reset Password to Supabase Auth flows
9. Wire Header Logout to `supabase.auth.signOut()`
10. Run admin schema migration §31.6 + admin RPCs (§31.6.1) + RLS (§31.7) against Supabase
11. Manually provision the first admin user via Supabase SQL editor:
    `insert into public.admin_users (id, permissions) values ('<auth-uuid>', array['all']);`

**Day-6 demo checkpoint:** Login with real credentials succeeds for an admin user, fails for non-admins, fails for wrong passwords. Direct-URL access to `/dashboard` redirects to `/` when signed out.

#### Day 7 — Core User Management (~6 hours)
1. Wire Dashboard stats to `admin_dashboard_stats()` RPC (§31.6.1)
2. Wire Dashboard charts to a thin `admin_registration_trend()` RPC (write it: `select date_trunc('day', created_at) as d, role, count(*) from public.users group by 1, 2`)
3. Wire Families page to `select * from public.family_profiles` (filtered, paginated)
4. Wire Approve / Reject buttons to `admin_approve_family` / `admin_reject_family` RPCs
5. Wire Babysitters page to `sitter_profiles` joined with `users` for full_name/email
6. Wire Jobs page to `jobs` with `job_timeline_events` join

**Day-7 demo checkpoint:** Dashboard shows real numbers from a seeded test database. Approve/reject persists.

#### Day 8 — Courses + Certifications (~5 hours)
1. Wire Courses page to `courses` table (full CRUD)
2. Wire Create / Edit / Delete course modals
3. Wire Certification Approvals tab to `certification_submissions`
4. Wire Approve / Reject buttons to `admin_approve_certification` (existing in §7) and a new `admin_reject_certification` (mirror it)

#### Day 9 — Wages + Disputes + Notifications (~5 hours)
1. Wire Wages page: load `age_wage_tiers`, save via `admin_update_wage_tiers` (§31.6.1, effective_from = tomorrow)
2. Wire system_config widgets (rounding rule, overtime rule) — use `cfg_*` reader RPCs from §5 Migration 12
3. Wire Disputes page to real `disputes` table
4. Wire Resolve dispute → `admin_resolve_dispute`
5. Wire Notifications Logs page to `notifications` table with `delivery_status` column

#### Day 10 — Reports + Settings + Polish + Deploy (~5 hours)
1. Wire Reports page charts to read-only aggregate RPCs (use SQL views for complex queries)
2. Wire export buttons to `/api/admin/reports/export` (CSV stream from Supabase queries)
3. Wire Settings → Platform tab to `system_config` reads/writes (admins only — gated by `admin_only()` in a wrapper RPC)
4. Wire Settings → Audit Log tab to real `audit_logs` table
5. Add CSP headers in `next.config.ts` (§31.14)
6. Add `NEXT_PUBLIC_*` and `SUPABASE_SERVICE_ROLE_KEY` to Vercel env vars
7. Deploy to Vercel production
8. Smoke-test the deployed app end-to-end

**End-of-Week-2 demo checkpoint:** All admin pages show real data. Every admin action persists, fires a notification (where appropriate), and writes to `audit_logs`. CSP, env vars, and Vercel deploy are in place.

---

### 31.13 Admin App — Supabase Realtime Integration

The admin dashboard should have live updates for these high-priority events. Add after the core wiring is complete:

```typescript
// src/app/(dashboard)/dashboard/page.tsx — live counters
const supabase = createClient();

const channel = supabase
  .channel('admin-live')

  // bg_check_status = 'pending' rows arriving means a new family is in queue.
  // Use the base column from §5 Migration 4. UPDATE events fire when admins
  // approve/reject — we listen to both INSERT and UPDATE to keep counts fresh.
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'family_profiles',
    filter: 'bg_check_status=eq.pending',
  }, (payload) => {
    // Refetch admin_dashboard_stats() and update card
  })

  // New disputes are always interesting
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'disputes',
  }, (payload) => {
    // Show high-priority toast; refresh open-disputes counter
  })

  // Pending certifications (uses the verification_status enum from §5)
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'certification_submissions',
    filter: 'status=eq.pending',
  }, (payload) => {
    // Increment cert approval queue count
  })

  .subscribe();

// Always clean up on unmount:
// return () => supabase.removeChannel(channel);
```

This gives the admin live visibility without page refreshes — critical for the demo.

---

### 31.14 Content Security Policy

Production CSP for the admin app. The script-src does **not** include
`'unsafe-eval'` — Next.js production builds do not require it (it was needed
in dev for some HMR paths but is unsafe in production). Use a per-request
nonce for inline scripts that Next.js may emit, generated in middleware.

```typescript
// next.config.ts
import type { NextConfig } from "next";

// In production, Next.js emits inline scripts only with a nonce when one is
// available — pass the nonce via middleware. Tailwind v4 emits inline styles,
// so style-src keeps 'unsafe-inline' (a common, accepted trade-off).
const csp = (nonce: string) => [
  "default-src 'self'",
  // 'strict-dynamic' lets the nonced loader script load further scripts; this
  // is the modern hardened pattern recommended by Google's CSP guide.
  `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
  "font-src 'self' https://fonts.gstatic.com",
  // Supabase HTTP + WebSocket; FCM is not called from the browser any more
  // (admin push goes through the /api/admin/notifications/broadcast route),
  // so we don't whitelist fcm.googleapis.com here.
  "connect-src 'self' https://*.supabase.co wss://*.supabase.co",
  "img-src 'self' blob: data: https://*.supabase.co",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "frame-ancestors 'none'",
].join("; ");

// Static fallback CSP (used by next.config.ts headers() — without nonce).
// In a fully nonce-aware setup, headers are written by middleware.ts.
const staticCsp = csp("");

const securityHeaders = [
  { key: "X-DNS-Prefetch-Control", value: "on" },
  { key: "X-Frame-Options", value: "SAMEORIGIN" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Strict-Transport-Security",
    value: "max-age=63072000; includeSubDomains; preload" },
  { key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=(self)" },
  // CSP with nonce is set per-request in middleware. This is a fallback
  // for routes that bypass middleware (rare in App Router).
  { key: "Content-Security-Policy", value: staticCsp },
];

const nextConfig: NextConfig = {
  async headers() {
    return [{ source: "/(.*)", headers: securityHeaders }];
  },
};
export default nextConfig;
```

Then in `src/middleware.ts`, add the nonce + per-request CSP after the auth
checks complete:

```typescript
// Inside middleware(), before `return response`:
const nonce = btoa(crypto.randomUUID());
response.headers.set("x-nonce", nonce);
response.headers.set("Content-Security-Policy", [
  "default-src 'self'",
  `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
  "font-src 'self' https://fonts.gstatic.com",
  "connect-src 'self' https://*.supabase.co wss://*.supabase.co",
  "img-src 'self' blob: data: https://*.supabase.co",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "frame-ancestors 'none'",
].join("; "));
```

**Why this is a security improvement vs the previous draft:**
- `'unsafe-eval'` allowed `eval()` and `new Function(...)` — a major XSS
  amplifier. Removed.
- `'unsafe-inline'` is gone from `script-src`; replaced by `nonce-{value} +
  'strict-dynamic'`, which is the OWASP-recommended modern pattern.
- `object-src 'none'`, `base-uri 'self'`, `form-action 'self'` close the
  remaining common XSS sinks.
- `'unsafe-inline'` stays on `style-src` because Tailwind v4 emits inline
  styles via the `style` attribute (not via `<style>` tags), and there is no
  practical workaround for that without dropping Tailwind's runtime.

---

### 31.15 Admin App — Vercel Deployment Configuration

The app already has 2 production deployments at `star-sitters.vercel.app`. To maintain clean CI/CD:

`vercel.json` (create in `starsitters-admin/`):
```json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "regions": ["iad1"],
  "env": {
    "NEXT_PUBLIC_SUPABASE_URL": "@supabase_url",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY": "@supabase_anon_key"
  }
}
```

Branch strategy:
- `main` → auto-deploys to `star-sitters.vercel.app` (production)
- Pull requests → preview deployments (use `.env.preview` with a separate Supabase project or the same project with restricted permissions)

---

### 31.16 What the Admin App Manages vs. What the Backend Owns

To be absolutely clear on the division of responsibilities:

| Action | Who does it | How |
|---|---|---|
| Approve/reject family | Admin via web app | `admin_approve_family` / `admin_reject_family` RPC → flips `family_profiles.bg_check_status` |
| Approve/reject cert | Admin via web app | `admin_approve_certification` RPC → flips `certifications.status` and (if guardian consent is in place) `sitter_profiles.is_active` |
| Update wage tiers | Admin via web app | `admin_update_wage_tiers` RPC → inserts new rows in `age_wage_tiers` |
| Wage calculation at clock-out | Backend RPC | `clock_out` RPC reads `age_wage_tiers` and computes exact-minute pay — admin cannot override retroactively |
| Dispute resolution | Admin via web app | `admin_resolve_dispute` RPC → updates `disputes.status` + writes resolution notes |
| Manual withdrawal payout | Admin via web app | `admin_pay_withdrawal` RPC → marks `withdrawal_requests` as paid |
| Push notification | Backend (Edge Function) | `send_push` Edge Function — admin can trigger manual broadcasts via `/api/admin/notifications/broadcast` |
| Create/edit courses | Admin via web app | Direct INSERT/UPDATE to `courses` table |
| Guardian consent | Backend (Email Edge Function) | `send_guardian_consent_email` — triggered automatically, not by admin |
| Wage tier snapshot | Backend (RPC) | `clock_out` snapshots the tier at the moment of clock-out — immutable |
| Ledger entries | Backend (RPC) | Created by `clock_out` and `request_withdrawal` — admin cannot edit |

The admin app is the **control plane**. The backend RPCs are the **enforcement plane**. The admin never executes financial logic directly — it calls RPCs that enforce all rules atomically.

---

## 32. Critical Review Reconciliation Log

This section maps every defect found in the end-to-end review against the
location of its fix. Use it as a self-audit checklist before deploying.

### A. Schema bugs

| # | Defect | Fix location |
|---|---|---|
| 1 | `chk_sitter_age` used `extract(year from age())` — incorrect on year-boundary edge dates | §5 Migration 5 — replaced with raw date math (`<= current_date - 11y AND > current_date - 18y`); same fix in Appendix A |
| 2 | No trigger created the `wallets` row on sitter signup → first `clock_out` failed | §5 Migration 5 — `fn_create_wallet_for_sitter()` trigger; mirrored in Appendix A |
| 3 | `admin_dashboard_stats` referenced non-existent columns (`verification_status`, `certification_status`, `account_status`, `completed_at`) and used `'in_progress'` | §31.6.1 — rewritten with §5 base columns and `jobs.status='active'`; §31.4 only documents the UI-label mapping |
| 4 | `admin_approve_family` targeted `family_profiles(family_id)` (a column that doesn't exist) and wrote non-existent `verification_status` / `background_check` | §31.6.1 — uses the real PK `family_profiles(user_id)` and the real column `bg_check_status` |
| 5 | New admin tables had FK references to fictional `family_profiles(family_id)` / `sitter_profiles(sitter_id)` PKs | §31.6 — all FKs now reference `users(id)`, `family_profiles(user_id)`, or `sitter_profiles(user_id)` |
| 6 | `fn_update_sitter_totals` used non-existent `time_entries.total_minutes` / `gross_pay` and fired on INSERT (when those values are NULL) | §5 Migration 14 — rewritten using `computed_minutes` / `computed_wage`, fires AFTER UPDATE only when `clock_out_at` flips from NULL |
| 7 | `admin_update_wage_tiers` used `effective_from = now()` causing unique constraint violations on same-day saves | §31.6.1 — `effective_from = current_date + interval '1 day'`; old rows preserved as audit history |
| 8 | `disputes.reported_by_role` used `'babysitter'` while user_role enum uses `'sitter'` | §31.6 — enum aligned to canonical `('family','sitter')`; §31.16 table updated |

### B. Contract mismatches

| # | Defect | Fix location |
|---|---|---|
| 1 | `users: update own` RLS allowed role escalation | §5 Migration 13 — `trg_users_role_immutable` blocks role changes; §6 RLS comment updated |
| 2 | `sitter_profiles: update own` RLS allowed self-activation (`is_active`, `guardian_consent_status`) | §5 Migration 13 — `trg_sitter_lock_admin_fields` blocks; admin RPCs bypass via the `app.bypass_immutability` GUC |
| 3 | `clock_in` had a TOCTOU race in the "no open entry" check | §5 Migration 7 — `uq_one_open_time_entry` partial unique index + `pg_advisory_xact_lock` in §7 `clock_in` RPC |
| 4 | `send_push` used the deprecated FCM legacy server-key auth that Google removed in mid-2024 | §8.1 — full FCM HTTP v1 OAuth 2.0 access-token flow with service-account JWT signing and 1h cached token; §22 secret list updated |
| 5 | `send_guardian_consent_email` only `console.log`'d the link; no email was ever sent | §8.2 — real Resend HTTP API call with retries + idempotency; `'mock'` mode for demos |
| 6 | Flutter mark-as-read used `.is_('read_at', null)` (does not exist in `supabase_flutter` v2) | §13 — replaced with `.isFilter('read_at', null)` |

### C. Architectural / process issues

| # | Defect | Fix location |
|---|---|---|
| 1 | Repo named `pixoraft-backend`; user owns "Star Sitters" | All 3 stale references replaced with `starsitters-backend` (lines 3482, 3526, 5027 of the prior version) |
| 2 | 5-day mobile sprint + 5-day admin sprint exceeded the original 5-6 day window | §1 timeline table, §31.12 — admin sprint now Days 6-10 (Week 2). Friday Week-1 demo runs admin actions through Supabase Studio (§20 step 6) |
| 3 | CSP allowed `'unsafe-eval'` and `'unsafe-inline'` for scripts | §31.14 — removed `'unsafe-eval'`; switched to `nonce + 'strict-dynamic'`; locked down `object-src`, `base-uri`, `form-action` |

### D. Other issues addressed

| Defect | Fix location |
|---|---|
| `system_config` JSONB seeds inconsistent (quoted vs unquoted) | §5 system_config seed block + Appendix A + §27.10 — all values now JSON-encoded |
| Reads of `system_config.value` cast text→boolean directly (brittle) | §5 Migration 12 — `cfg_bool` / `cfg_text` / `cfg_int` helper functions; §13 documents Flutter usage; `clock_in` RPC updated |
| No documented Google OAuth redirect URI setup | §5 "Auth Configuration" checklist appended after Migration 14 |
| Tuesday demo wage math claimed $0.10 for 30s @ $12/h; RPC produces $0.20 | §19 — recomputed and explained out loud (`ceil(30/60)=1 minute → $0.20`) |
| Supabase Auth email confirmation requirement undocumented | §5 "Auth Configuration" checklist — "Confirm email" must be ON |
| FCM rate-limit characterisation was off | §22 / §8.1 commentary corrected; per-IP/per-route throttling noted |
| `admin_only()` and `is_admin()` were duplicated/inconsistent | §5 Migration 12 owns the canonical definition; §6 keeps `is_admin()` as a documented alias of `admin_only_bool()` |
| `write_audit_log()` was referenced but never defined | §5 Migration 12 — full definition; all admin RPCs in §7 and §31.6.1 use it |
| `uploaded_documents` RLS subquery was self-referential | §31.7 — direct `user_id = auth.uid()` predicate |
| `job_timeline_events.event_type` mixed snake_case/camelCase | §31.6 — `snake_case` in DB; UI mapping in `src/lib/eventLabels.ts` (§31.4 jobs page) |
| Admin `package.json` named `onlygigz-admin` | §31.12 Day 6 step 0 — `npm pkg set name=starsitters-admin`; §31.9 row 7 |
| 5 vestigial scraper modals | §31.3 — explicit `rm` paths and a `grep` to find stale imports |

### E. How to verify the document is internally consistent

If anyone re-runs the review, here's how to spot regressions automatically:

```bash
# from /home/dns/Desktop/PIXORAFT1
# 1. No stale repo names
grep -ni 'pixoraft' BACKEND.md && echo 'FAIL: stale pixoraft refs'

# 2. No fictional admin-side column names in SQL fences
grep -nP "verification_status\s*=|account_status\s*=|certification_status\s*=" BACKEND.md \
  | grep -v 'verification_status enum\|verification_status,\|verification_status not null\|verification_status::' \
  && echo 'FAIL: fictional column references remain'

# 3. No legacy FCM server key auth
grep -n 'FCM_SERVER_KEY' BACKEND.md && echo 'FAIL: legacy FCM secret'

# 4. No is_('read_at', null) Dart anti-pattern
grep -n "is_('read_at'" BACKEND.md && echo 'FAIL: stale supabase-flutter API'

# 5. No 'in_progress' job status (canonical is 'active')
grep -nE "jobs.+status.*=.*'in_progress'" BACKEND.md && echo 'FAIL: bad job status'
```

If all five greps print nothing, the document matches the reconciliation log.

### F. Implementation repository (May 2026)

| Item | Location |
|---|---|
| Supabase migrations + seed | `PIXORAFT1/starsitters-backend/supabase/` |
| Edge Functions | `starsitters-backend/supabase/functions/send_{push,guardian_consent_email}/` |
| Tuesday non-technical demo script | `starsitters-backend/docs/TUESDAY_DEMO.md` |
| CI: hosted `db push` | `starsitters-backend/.github/workflows/supabase-db.yml` |

---

*End of BACKEND.md — Star Sitters Platform v0.1*
*This document is the engineering source of truth for the starsitters-backend repository.*
*All changes to architecture, schema, or deployment must be reflected here before implementation.*
