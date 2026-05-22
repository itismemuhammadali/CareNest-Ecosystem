# Proposed Project Reorganization

## Current Structure (Flat)

```
Star_Sitter/
├── star_sitters_core/
├── Star_Sitter_Baby_Sitter/
├── Star_Sitter_Family/
├── starsitters-backend/
└── StarSitters/starsitters-admin/
```

**Problems:**
- Hard to find things at the root level
- No clear separation between mobile, web, backend
- Difficult to onboard new developers
- No shared utilities between backend and frontend
- No monorepo tooling (no workspace management)

---

## Proposed Structure (Organized)

```
star-sitters/                          ← Monorepo root
├── .github/
│   └── workflows/                     ← CI/CD pipelines
│       ├── flutter-test.yml
│       ├── backend-test.yml
│       └── admin-deploy.yml
│
├── docs/                              ← Project documentation
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── SETUP.md
│   └── CONTRIBUTING.md
│
├── packages/                          ← Shared packages
│   ├── core/                          ← star_sitters_core (renamed)
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── data/              ← Repositories
│   │   │   │   ├── models/            ← Dart models (NEW)
│   │   │   │   ├── exceptions/        ← Custom exceptions (NEW)
│   │   │   │   └── validation/
│   │   │   └── star_sitters_core.dart
│   │   ├── pubspec.yaml
│   │   └── README.md
│   │
│   └── ui/                            ← Shared Flutter widgets (NEW)
│       ├── lib/
│       │   ├── src/
│       │   │   ├── buttons/
│       │   │   ├── cards/
│       │   │   ├── dialogs/
│       │   │   ├── theme/
│       │   │   └── utils/
│       │   └── star_sitters_ui.dart
│       ├── pubspec.yaml
│       └── README.md
│
├── apps/                              ← Applications
│   ├── mobile/
│   │   ├── sitter/                    ← Star_Sitter_Baby_Sitter (renamed)
│   │   │   ├── lib/
│   │   │   │   ├── main.dart
│   │   │   │   ├── config/            ← App config (NEW)
│   │   │   │   ├── features/          ← Feature-based structure (NEW)
│   │   │   │   │   ├── auth/
│   │   │   │   │   │   ├── screens/
│   │   │   │   │   │   ├── widgets/
│   │   │   │   │   │   └── bloc/      ← State management (NEW)
│   │   │   │   │   ├── jobs/
│   │   │   │   │   ├── chat/
│   │   │   │   │   ├── wallet/
│   │   │   │   │   └── profile/
│   │   │   │   ├── shared/            ← Shared across features
│   │   │   │   │   ├── widgets/
│   │   │   │   │   ├── utils/
│   │   │   │   │   └── constants/
│   │   │   │   └── routes/            ← Navigation (NEW)
│   │   │   ├── pubspec.yaml
│   │   │   ├── README.md
│   │   │   └── test/
│   │   │
│   │   └── family/                    ← Star_Sitter_Family (renamed)
│   │       ├── lib/
│   │       │   ├── features/
│   │       │   │   ├── auth/
│   │       │   │   ├── jobs/
│   │       │   │   ├── applications/
│   │       │   │   ├── chat/
│   │       │   │   └── profile/
│   │       │   ├── shared/
│   │       │   └── routes/
│   │       ├── pubspec.yaml
│   │       └── test/
│   │
│   └── web/
│       └── admin/                     ← starsitters-admin (renamed)
│           ├── src/
│           │   ├── app/
│           │   ├── components/
│           │   ├── features/          ← Feature-based (NEW)
│           │   │   ├── auth/
│           │   │   ├── users/
│           │   │   ├── jobs/
│           │   │   ├── background-checks/
│           │   │   └── certifications/
│           │   ├── lib/
│           │   ├── hooks/
│           │   └── types/
│           ├── package.json
│           ├── tsconfig.json
│           ├── next.config.ts
│           └── README.md
│
├── backend/                           ← starsitters-backend (renamed)
│   ├── supabase/
│   │   ├── migrations/
│   │   │   ├── 00_schema/             ← Organized by domain (NEW)
│   │   │   │   ├── 001_users.sql
│   │   │   │   ├── 002_profiles.sql
│   │   │   │   ├── 003_jobs.sql
│   │   │   │   └── 004_applications.sql
│   │   │   ├── 01_rls/
│   │   │   │   ├── 001_users_rls.sql
│   │   │   │   ├── 002_profiles_rls.sql
│   │   │   │   └── ...
│   │   │   ├── 02_functions/          ← RPCs organized (NEW)
│   │   │   │   ├── 001_auth_functions.sql
│   │   │   │   ├── 002_job_functions.sql
│   │   │   │   └── ...
│   │   │   ├── 03_triggers/           ← Triggers organized (NEW)
│   │   │   │   ├── 001_audit_triggers.sql
│   │   │   │   └── ...
│   │   │   └── 04_seed/               ← Test data (NEW)
│   │   │       └── 001_test_data.sql
│   │   ├── config.toml
│   │   └── .env.example
│   ├── docs/                          ← Backend docs (NEW)
│   │   ├── SCHEMA.md
│   │   ├── RLS.md
│   │   └── RPCS.md
│   └── README.md
│
├── scripts/                           ← Utility scripts (NEW)
│   ├── setup.sh                       ← One-command setup
│   ├── dev.sh                         ← Start all services
│   ├── test.sh                        ← Run all tests
│   └── deploy.sh                      ← Deploy to production
│
├── docker-compose.yml                 ← Local dev environment (NEW)
├── .env.example                       ← Template for env vars (NEW)
├── .gitignore
├── README.md                          ← Root README
├── CONTRIBUTING.md                    ← Contribution guide
└── package.json                       ← Monorepo root (NEW)
```

---

## Key Improvements

### 1. **Monorepo Structure**

**Before:** 5 separate directories at root level
**After:** Organized into `packages/`, `apps/`, and `backend/`

**Benefits:**
- Easier to navigate
- Clear separation of concerns
- Shared dependencies managed in one place
- Easier to run all tests at once

### 2. **Feature-Based Organization (Mobile Apps)**

**Before:**
```
lib/
├── screens/
│   ├── sign_in_screen.dart
│   ├── create_account_screen.dart
│   ├── job_board_screen.dart
│   └── ...
├── widgets/
└── utils/
```

**After:**
```
lib/
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── bloc/
│   │   └── models/
│   ├── jobs/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── bloc/
│   │   └── models/
│   └── ...
├── shared/
│   ├── widgets/
│   ├── utils/
│   └── constants/
└── routes/
```

**Benefits:**
- Easy to find related code (auth logic all in one place)
- Easy to add/remove features
- Easier to test features in isolation
- Scales better as app grows

### 3. **Shared UI Package**

**New:** `packages/ui/` for reusable Flutter widgets

**Benefits:**
- Both mobile apps use the same buttons, cards, dialogs
- Consistent design across apps
- Easy to update theme in one place
- Can be published to pub.dev later if needed

### 4. **Backend Organization by Domain**

**Before:**
```
migrations/
├── 20260209100005_sitter.sql
├── 20260209100015_rls_policies.sql
├── 20260209100016_rpcs.sql
└── ...
```

**After:**
```
migrations/
├── 00_schema/
│   ├── 001_users.sql
│   ├── 002_profiles.sql
│   └── ...
├── 01_rls/
│   ├── 001_users_rls.sql
│   └── ...
├── 02_functions/
│   ├── 001_auth_functions.sql
│   └── ...
└── 03_triggers/
    └── 001_audit_triggers.sql
```

**Benefits:**
- Clear migration order
- Easy to find RLS policies
- Easy to find RPCs
- Easier to understand schema evolution

### 5. **Shared Scripts**

**New:** `scripts/` directory with setup, dev, test, deploy scripts

**Benefits:**
- One-command setup for new developers
- Consistent way to run everything
- Easy CI/CD integration

### 6. **Documentation**

**New:** `docs/` and `backend/docs/` directories

**Benefits:**
- Centralized documentation
- Easy to find API docs, architecture, setup guide
- Easier onboarding

---

## Migration Path

### Phase 1: Reorganize Directories (No Code Changes)

```bash
# Create new structure
mkdir -p packages/core packages/ui apps/mobile/sitter apps/mobile/family apps/web/admin backend scripts docs

# Move files (git mv to preserve history)
git mv star_sitters_core packages/core
git mv Star_Sitter_Baby_Sitter apps/mobile/sitter
git mv Star_Sitter_Family apps/mobile/family
git mv StarSitters/starsitters-admin apps/web/admin
git mv starsitters-backend backend

# Update pubspec.yaml paths in each app
# Update import statements
```

### Phase 2: Add Feature-Based Structure (Mobile Apps)

```bash
# In apps/mobile/sitter/lib/
mkdir -p features/{auth,jobs,chat,wallet,profile}/screens
mkdir -p features/{auth,jobs,chat,wallet,profile}/widgets
mkdir -p features/{auth,jobs,chat,wallet,profile}/bloc
mkdir -p shared/{widgets,utils,constants}
mkdir -p routes config

# Move screens into features
mv screens/sign_in_screen.dart features/auth/screens/
mv screens/create_account_*.dart features/auth/screens/
# ... etc
```

### Phase 3: Add Shared UI Package

```bash
# Create shared UI package
cd packages/ui
flutter create --template=package .

# Move common widgets
# Create theme system
# Document component library
```

### Phase 4: Reorganize Backend Migrations

```bash
# Create migration folders
mkdir -p backend/supabase/migrations/{00_schema,01_rls,02_functions,03_triggers,04_seed}

# Move migrations
mv backend/supabase/migrations/20260209100005_sitter.sql backend/supabase/migrations/00_schema/001_sitter.sql
# ... etc
```

### Phase 5: Add Scripts & Documentation

```bash
# Create scripts
touch scripts/{setup.sh,dev.sh,test.sh,deploy.sh}

# Create documentation
touch docs/{ARCHITECTURE.md,API.md,SETUP.md,CONTRIBUTING.md}
touch backend/docs/{SCHEMA.md,RLS.md,RPCS.md}
```

---

## Benefits Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Navigation** | Hard to find files | Clear structure, easy to navigate |
| **Scalability** | Difficult to add features | Feature-based, easy to scale |
| **Code Reuse** | Duplicated UI code | Shared UI package |
| **Backend** | Migrations hard to understand | Organized by domain |
| **Onboarding** | No clear setup guide | `scripts/setup.sh` + docs |
| **Testing** | No test organization | Feature-based tests |
| **CI/CD** | Manual deployment | Automated scripts |
| **Documentation** | Scattered | Centralized in `docs/` |

---

## Implementation Timeline

- **Week 1:** Phase 1 (reorganize directories)
- **Week 2:** Phase 2 (feature-based structure)
- **Week 3:** Phase 3 (shared UI package)
- **Week 4:** Phase 4 (backend reorganization)
- **Week 5:** Phase 5 (scripts & docs)

**Total:** ~1 month to fully reorganize

---

## Tools to Add

### Monorepo Management
- **melos** — Dart monorepo tool (manages multiple Flutter packages)
- **npm workspaces** — For Next.js admin portal

### State Management (Mobile)
- **BLoC** — Already partially used, expand to all features
- **Riverpod** — Alternative (more modern)

### Testing
- **flutter_test** — Unit tests
- **integration_test** — E2E tests
- **jest** — Next.js tests

### CI/CD
- **GitHub Actions** — Already set up, expand with more workflows
- **Fastlane** — Automate Flutter builds

---

## Example: Feature-Based Auth Module

```
apps/mobile/sitter/lib/features/auth/
├── bloc/
│   ├── auth_bloc.dart
│   ├── auth_event.dart
│   └── auth_state.dart
├── models/
│   ├── user.dart
│   └── login_request.dart
├── repositories/
│   └── auth_repository.dart
├── screens/
│   ├── sign_in_screen.dart
│   ├── sign_up_screen.dart
│   └── forgot_password_screen.dart
├── widgets/
│   ├── email_input_field.dart
│   ├── password_input_field.dart
│   └── auth_button.dart
└── auth_feature.dart  ← Barrel export
```

**Usage:**
```dart
import 'package:sitter_app/features/auth/auth_feature.dart';

// All auth-related code is in one place
final authBloc = AuthBloc(authRepository);
```

---

## Conclusion

This reorganization makes the project:
- **Easier to navigate** — Clear structure
- **Easier to scale** — Feature-based organization
- **Easier to maintain** — Shared packages, organized backend
- **Easier to onboard** — Documentation + setup scripts
- **Easier to test** — Feature-based tests
- **Easier to deploy** — Automated scripts

The migration can be done incrementally without breaking anything.
