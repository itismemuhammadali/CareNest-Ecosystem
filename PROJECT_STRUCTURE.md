# Star Sitters Project Structure & Organization

## Overview

The Star Sitters project is organized into **4 independent applications** that share a **single shared Dart package** for data access:

```
Star_Sitter/
├── star_sitters_core/          ← Shared package (data layer)
├── Star_Sitter_Baby_Sitter/    ← Flutter app (sitter side)
├── Star_Sitter_Family/         ← Flutter app (family side)
├── starsitters-backend/        ← Supabase backend (migrations, RLS, RPCs)
└── StarSitters/
    └── starsitters-admin/      ← Next.js admin portal
```

---

## 1. star_sitters_core — The Shared Data Layer

### What It Is

`star_sitters_core` is a **pure Dart package** (never published to pub.dev) that centralizes all Supabase I/O logic. Both Flutter apps depend on it via a local path dependency.

### Why It Exists

**Problem:** Without it, both Flutter apps would duplicate database queries, RPC calls, and storage uploads.

**Solution:** One package owns all Supabase communication. Both apps import it and call repository methods instead of calling Supabase directly.

### What It Contains

| Component | Purpose | Files |
|-----------|---------|-------|
| **Bootstrap** | Initialize Supabase with credentials | `app_bootstrap.dart` |
| **Repositories** (13 total) | Typed data access for each domain | `src/data/*.dart` |
| **Validation** | Pure Dart validation logic | `src/validation/*.dart` |
| **Constants** | Country list, system config | `src/data/countries.dart`, `system_config_service.dart` |

### Repository Breakdown

Each repository wraps a set of related database tables and provides strongly-typed methods:

| Repository | Tables | Purpose |
|---|---|---|
| `ProfileRepository` | `users`, `family_profiles`, `sitter_profiles`, `children`, `guardian_consents` | User identity, profile data, avatar uploads |
| `JobsRepository` | `jobs`, `hires`, `age_wage_tiers` | Job posting, hiring, wage lookups |
| `ApplicationsRepository` | `applications` | Sitter applications to jobs |
| `ConversationsRepository` | `conversations` | Chat threads between family & sitter |
| `MessagesRepository` | `messages` | Individual chat messages |
| `WalletRepository` | `wallets`, `ledger_entries` | Sitter earnings, balance, transactions |
| `WorkRepository` | `time_entries`, `hires` | Clock in/out, work hours tracking |
| `NotificationsRepository` | `notifications` | Push notifications, in-app alerts |
| `DevicesRepository` | `devices` | FCM tokens, device registration |
| `SittersRepository` | `sitter_profiles` (joined with `users`) | Sitter discovery, search, filtering |
| `CertificationsRepository` | `certifications` | CPR, first aid, other certs |
| `CoursesRepository` | `courses`, `certification_submissions` | Training courses, quiz submissions |
| `SystemConfigService` | `system_config` | Runtime feature flags, settings |

### How Apps Use It

```dart
// In any Flutter app screen
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final profileRepo = ProfileRepository(client);
    
    // Call repository methods instead of Supabase directly
    final profile = await profileRepo.sitterProfile();
    
    return Text(profile?['bio'] ?? 'No bio');
  }
}
```

### Key Design Principles

1. **No Flutter UI** — The package contains zero widgets. It's pure Dart.
2. **No Navigation** — Apps handle routing themselves.
3. **No Firebase** — Only device token registration (FCM tokens stored in `devices` table).
4. **Strongly Typed** — Methods return `Future<Map>` or `Stream<List<Map>>`, not raw JSON.
5. **RLS-Aware** — All queries respect Postgres row-level security policies.
6. **Auth-Aware** — Methods check `currentUser?.id` and return `null` or empty streams when not signed in.

---

## 2. Star_Sitter_Baby_Sitter — Sitter App (Flutter)

### What It Is

A Flutter app for babysitters to:
- Create account & complete onboarding (6 steps)
- Browse available jobs
- Apply for jobs
- Chat with families
- Clock in/out for work
- View earnings & withdraw money
- Upload certifications

### Architecture

```
lib/
├── main.dart                    ← App entry point, bootstrap
├── screens/                     ← All UI screens
│   ├── sign_in_screen.dart
│   ├── create_account_*.dart    ← 6-step signup flow
│   ├── job_board_screen.dart
│   ├── job_detail_screen.dart
│   ├── chat_screen.dart
│   ├── wallet_screen.dart
│   └── ...
├── widgets/                     ← Reusable UI components
│   ├── auth_gate.dart           ← Checks auth state, shows login or app
│   ├── primary_button.dart
│   └── ...
├── utils/                       ← Helpers
│   ├── navigation_transitions.dart
│   └── ...
└── hooks/                       ← Custom Flutter hooks (if using riverpod)
```

### Key Screens

| Screen | Purpose | Uses Repository |
|--------|---------|-----------------|
| `SignInScreen` | Email/password login | `ProfileRepository` |
| `CreateAccountScreen` (steps 1-6) | Onboarding wizard | `ProfileRepository`, `JobsRepository` |
| `JobBoardScreen` | Browse open jobs | `JobsRepository` |
| `JobDetailScreen` | View job details, apply | `ApplicationsRepository` |
| `ChatScreen` | Message family | `MessagesRepository`, `ConversationsRepository` |
| `WalletScreen` | View balance, withdraw | `WalletRepository` |

### Current Issues Fixed

- ✅ Signup flow now passes `userId` through all 6 steps
- ✅ Step 2 (guardian consent) uses RPC to bypass RLS
- ✅ Step 4 (bio) uses RPC to bypass RLS
- ✅ Onboarding only shows once (flag stored in SharedPreferences)
- ✅ Profile under review screen auto-closes after 5 seconds

---

## 3. Star_Sitter_Family — Family App (Flutter)

### What It Is

A Flutter app for families to:
- Create account & complete onboarding
- Post babysitting jobs
- Browse sitter applications
- Hire sitters
- Chat with sitters
- Track work hours (sitter clocks in/out)
- Submit background checks

### Architecture

Same structure as Baby Sitter app, but different screens:

```
lib/
├── screens/
│   ├── sign_in_screen.dart
│   ├── create_account_*.dart    ← Different onboarding flow
│   ├── post_job_screen.dart
│   ├── job_applications_screen.dart
│   ├── sitter_search_screen.dart
│   ├── chat_screen.dart
│   └── ...
└── ...
```

---

## 4. starsitters-backend — Supabase Backend

### What It Is

PostgreSQL database + Supabase configuration:
- Database schema (tables, indexes, triggers)
- Row-level security (RLS) policies
- Remote procedure calls (RPCs)
- Storage buckets (avatars, documents, course materials)
- Migrations (version-controlled schema changes)

### Structure

```
supabase/
├── migrations/                  ← SQL migration files
│   ├── 20260209100005_sitter.sql
│   ├── 20260209100015_rls_policies.sql
│   ├── 20260209100016_rpcs.sql
│   ├── 20260514100000_db_webhooks.sql
│   └── ...
├── config.toml                  ← Supabase local config
└── .env                         ← Local secrets
```

### Key Concepts

**RLS (Row-Level Security):** Postgres policies that filter rows based on the authenticated user's ID. Example:

```sql
-- Sitter can only see their own profile
create policy "sitter_select_own"
  on sitter_profiles for select
  using (user_id = auth.uid());
```

**RPCs (Remote Procedure Calls):** Server-side functions that bypass RLS when needed. Example:

```sql
-- Allow unauthenticated users to create guardian consent during signup
create function sitter_create_guardian_consent(
  p_sitter_id uuid,
  p_guardian_name text,
  p_guardian_email text,
  p_guardian_phone text
) returns jsonb as $$
  -- Function body
$$ language plpgsql security definer;

grant execute on function sitter_create_guardian_consent(...) to anon;
```

### Recent Migrations

| Migration | Purpose |
|-----------|---------|
| `20260522000001_sitter_create_guardian_consent.sql` | RPC for step 2 signup |
| `20260522000002_sitter_update_bio.sql` | RPC for step 4 signup |

---

## 5. StarSitters/starsitters-admin — Admin Portal (Next.js)

### What It Is

A web dashboard for admins to:
- Manage users (sitters, families)
- Review background checks
- Approve certifications
- View system metrics
- Configure system settings

### Architecture

```
starsitters-admin/
├── src/
│   ├── app/                     ← Next.js app router
│   │   ├── (auth)/              ← Auth pages (login, signup)
│   │   ├── (dashboard)/         ← Protected pages
│   │   └── ...
│   ├── components/              ← React components
│   ├── lib/                     ← Utilities
│   └── middleware.ts            ← Auth middleware
├── .env.local                   ← Supabase credentials
└── package.json
```

### Bootstrap Code

To sign up as admin, use: **`STARSITTERS_ADMIN_2026`**

---

## Project Dependencies

```mermaid
graph TD
    BabySitter["Star_Sitter_Baby_Sitter<br/>(Flutter)"]
    Family["Star_Sitter_Family<br/>(Flutter)"]
    Admin["starsitters-admin<br/>(Next.js)"]
    Core["star_sitters_core<br/>(Dart package)"]
    Backend["starsitters-backend<br/>(Supabase)"]
    Supabase["Supabase Cloud<br/>(PostgreSQL + Auth)"]

    BabySitter -->|path dep| Core
    Family -->|path dep| Core
    Core -->|supabase_flutter| Supabase
    Admin -->|@supabase/supabase-js| Supabase
    Backend -->|migrations| Supabase
    
    style Core fill:#4CAF50,color:#fff
    style Backend fill:#2196F3,color:#fff
    style Supabase fill:#FF6B6B,color:#fff
```

---

## How Data Flows

### Example: Sitter Applies for a Job

1. **Flutter App** calls `ApplicationsRepository.createApplication(jobId, message)`
2. **Repository** calls `Supabase.instance.client.from('applications').insert(...)`
3. **Supabase** receives the request with JWT token
4. **RLS Policy** checks: `sitter_id = auth.uid()` ✅ (user owns this row)
5. **PostgreSQL** inserts the row
6. **Webhook** triggers (if configured) to send notification
7. **Response** returns to Flutter app
8. **UI** updates to show "Application sent"

### Example: Admin Reviews Background Check

1. **Next.js Admin** calls Supabase client with service role key
2. **Supabase** receives request (service role bypasses RLS)
3. **PostgreSQL** returns all background checks (no filtering)
4. **Admin UI** displays list
5. **Admin** clicks "Approve"
6. **Next.js** calls RPC `approve_background_check(family_id)`
7. **RPC** updates `family_profiles.bg_check_status = 'approved'`
8. **Webhook** sends email to family

---

## Best Practices

### For Flutter Developers

1. **Always use repositories** — Never call `Supabase.instance.client` directly for data operations
2. **Handle null gracefully** — Repositories return `null` when not signed in
3. **Cancel streams** — Always unsubscribe from streams in `dispose()`
4. **Check auth state** — Use `AuthGate` widget to show login or app based on session

### For Backend Developers

1. **Write migrations** — All schema changes go in `supabase/migrations/`
2. **Test RLS policies** — Verify that users can only see their own data
3. **Use RPCs for complex logic** — Don't put business logic in the app
4. **Document changes** — Update this file when adding new tables or repositories

### For Admin Portal Developers

1. **Use service role key** — Admin operations bypass RLS
2. **Validate input** — Never trust client-side validation
3. **Log actions** — Track who approved/rejected what and when

---

## Running Everything

See `RUN_COMMANDS.md` for all commands to start each component.

**Quick start:**

```bash
# Terminal 1: Backend
cd starsitters-backend
supabase start

# Terminal 2: Baby Sitter App
cd Star_Sitter_Baby_Sitter
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# Terminal 3: Family App
cd Star_Sitter_Family
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# Terminal 4: Admin Portal
cd StarSitters/starsitters-admin
npm run dev
```

---

## File Organization Summary

| Path | Purpose | Language |
|------|---------|----------|
| `star_sitters_core/` | Shared data layer | Dart |
| `Star_Sitter_Baby_Sitter/` | Sitter mobile app | Dart/Flutter |
| `Star_Sitter_Family/` | Family mobile app | Dart/Flutter |
| `starsitters-backend/` | Database & migrations | SQL |
| `StarSitters/starsitters-admin/` | Admin web dashboard | TypeScript/React |

This structure keeps concerns separated while allowing code reuse through the shared package.
