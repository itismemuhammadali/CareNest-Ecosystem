<div align="center">

<p align="center">
  <img src="assets/branding/client_trademark_logo.png" alt="Star Sitter Production Logo" width="140" style="border-radius: 20px; box-shadow: 0 8px 24px rgba(16, 185, 129, 0.25); margin: 0 12px;" />
  <img src="assets/branding/carenest_platform_logo.jpg" alt="CareNest Platform Architectural Emblem" width="140" style="border-radius: 20px; box-shadow: 0 8px 24px rgba(16, 185, 129, 0.25); margin: 0 12px;" />
</p>
<p align="center">
  <em>Left: Production Client Mark (Star Sitter) &bull; Right: Architectural Platform Identity (CareNest)</em>
</p>

# CareNest Ecosystem

### Verified Childcare Marketplace, Babysitter Booking & Family Safety Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Next.js](https://img.shields.io/badge/Next.js-14_App_Router-black?style=for-the-badge&logo=next.js&logoColor=white)](https://nextjs.org)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%20%7C%20Auth%20%7C%20Realtime-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://typescriptlang.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Row--Level%20Security-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

<p align="center">
  <b>CareNest</b> is a full-stack, enterprise-grade childcare and babysitter discovery ecosystem. Built with a monorepo architecture featuring two dedicated Flutter mobile apps (Family & Sitter), an administrative Next.js web portal, and a hardened Supabase/PostgreSQL backend with fine-grained Row-Level Security (RLS).
</p>

</div>

---

## 🌟 Ecosystem Architecture

CareNest bridges families seeking trusted childcare with certified, background-checked babysitters through verified credentials, geofenced shift clocking, and secure digital escrow wallets.

```mermaid
graph TD
    subgraph CareNest Monorepo Ecosystem
        direction TB
        F[Family Mobile App / Flutter]
        S[Sitter Mobile App / Flutter]
        W[Admin Web Portal / Next.js]
        B[(Supabase / PostgreSQL Cloud Engine)]
    end

    subgraph Family Experience
        F --> F1[Post Babysitting Jobs & Special Care Notes]
        F --> F2[Browse Certified Sitters & Badges]
        F --> F3[Direct Real-Time Chat & Video Calls]
        F --> F4[Geofenced Shift Monitoring & Timeline]
        F --> F5[Wallet Milestone Payments & Tipping]
    end

    subgraph Babysitter Experience
        S --> S1[Availability & Hourly Rate Schedule]
        S --> S2[Job Applications & Offer Negotiation]
        S --> S3[Geofence-Enforced Clock-In & Out]
        S --> S4[Guardian Consent Flow for Minor Sitters]
        S --> S5[Earnings Ledger & Instant Withdrawal]
    end

    subgraph Platform Trust & Governance
        W --> W1[Sitter Certification & ID Vetting]
        W --> W2[Parent Background Checks]
        W --> W3[Dispute Arbitration & Audit Logs]
        W --> W4[Platform Revenue & Wage Rules]
    end

    F <-->|Realtime Sync & RLS| B
    S <-->|Realtime Sync & RLS| B
    W <-->|Management RPCs| B
```

---

## ⏱️ Geofenced Booking & Safety Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Family as Parent / Family
    participant App as CareNest Platform
    actor Sitter as Babysitter
    participant Backend as Supabase PostgreSQL Engine
    actor Admin as Trust & Safety Admin

    Family->>App: Create Childcare Request (Ages, Routine, Hourly Wage)
    App->>Sitter: Match Notification based on Geolocation & Qualifications
    Sitter->>App: Apply with Background Verification Badges
    Family->>App: Review Profile, Interview via In-App Chat & Confirm Hire
    Note over Sitter,Family: Babysitting Shift Begins
    Sitter->>App: Clock-In (Verified via Geofence GPS Proximity)
    App-->>Family: Real-Time Notification: "Sitter Checked In at Home"
    Note over Sitter,Family: Shift Completes
    Sitter->>App: Clock-Out (GPS Verified + Activity Summary Report)
    Family->>App: Approve Shift Duration & Release Digital Wallet Payment
    Family->>App: Submit Rating & Written Sitter Endorsement
    opt Safety Audit
        Admin->>Backend: Audit Geofence Coordinates & Time Log Immutability
    end
```

---

## 📁 Repository Structure

```
CareNest-Ecosystem/
├── assets/
│   └── branding/
│       └── logo.png               # Official brand identity
├── apps/
│   ├── mobile/
│   │   ├── family/                # Flutter iOS & Android app for Parents
│   │   │   ├── lib/               # Job posting, sitter discovery, chat, wallet
│   │   │   └── assets/            # Theme vectors, family UI icons
│   │   └── sitter/                # Flutter iOS & Android app for Babysitters
│   │       ├── lib/               # Shift clocking, applications, guardian consent
│   │       └── assets/            # Performer & sitter assets
│   └── web/
│       └── admin/                 # Next.js 14 App Router Administrator Portal
│           ├── src/app/           # Certification vetting, disputes, system wages
│           └── src/components/    # Shared Tailwind and shadcn UI components
├── packages/
│   └── core/                      # Shared Dart business logic & models
│       ├── lib/src/data/          # Supabase repositories (Jobs, Sitters, Wallet, Chat)
│       └── lib/src/validation/    # Age parsing, geofence, and withdrawal validators
├── backend/
│   └── supabase/                  # Supabase Enterprise Configuration
│       ├── migrations/            # 28+ PostgreSQL migrations (Schemas, RLS, RPCs, Triggers)
│       │   ├── 00_schema/         # Core tables (users, families, sitters, wallet)
│       │   ├── 01_rls/            # Hardened Row-Level Security policies
│       │   ├── 02_functions/      # Database stored procedures (RPCs)
│       │   └── 03_triggers/       # Real-time publications & webhooks
│       └── functions/             # Supabase Edge Functions (Deno / TypeScript)
└── README.md
```

---

## ✨ Enterprise Features

### 🛡️ 1. Trust, Safety & Row-Level Security
- **Hardened PostgreSQL RLS:** Families can only access sitters who have applied or are publicly available; private home addresses are strictly shielded until a booking contract is finalized.
- **Guardian Consent Workflows:** Edge functions and database triggers that enforce legal parental consent for teenage babysitters.
- **Geofence Clocking Immutability:** GPS coordinates are mathematically validated on clock-in and clock-out to ensure authentic presence on-site.

### 📱 2. Family Experience (`apps/mobile/family`)
- **Child Profile Cards:** Special care notes, dietary restrictions, emergency contact numbers, and bedtime routines.
- **Instant Booking Radar:** Locate nearby vetted caregivers for immediate date-night or emergency childcare.
- **Integrated Milestone Wallet:** Pre-authorize payments into escrow with automatic hourly calculation.

### 🧸 3. Babysitter Experience (`apps/mobile/sitter`)
- **Certification Showcase:** First Aid, CPR, Infant Care, and Early Childhood Education credential attachments.
- **Shift & Wage Ledger:** Transparent breakdown of gross earnings, platform commission, and instant bank transfers.
- **Direct Family Messaging:** In-app encrypted chat with read receipts and real-time push notifications.

---

## 🚀 Getting Started

### 1. Mobile Apps
```bash
# To run Family App
cd apps/mobile/family
flutter pub get
flutter run

# To run Sitter App
cd apps/mobile/sitter
flutter pub get
flutter run
```

### 2. Admin Web Portal
```bash
cd apps/web/admin
npm install
npm run dev
# Dashboard opens on http://localhost:3000
```

### 3. Backend (Supabase Local Development)
```bash
cd backend/supabase
# Ensure Docker is running
supabase start
supabase db reset  # Applies all migrations & seed data
```

---

## 🔒 Confidentiality & White-Label Notice
This repository is an open-source demonstration and portfolio showcase. All proprietary client data, commercial vendor contracts, live API tokens, and private Apple signing certificates have been sanitized and decoupled.

---

## 👨‍💻 Author
**Muhammad Ali**
- GitHub: [@itismemuhammadali](https://github.com/itismemuhammadali)
- Portfolio & Engineering Showcase
