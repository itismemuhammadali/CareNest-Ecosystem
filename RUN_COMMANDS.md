# Star Sitters - Run Commands

## Environment Setup
```bash
# Supabase credentials (production) — see .env.example
SUPABASE_URL=<your-supabase-url>
SUPABASE_ANON_KEY=<your-anon-key>

# Admin Bootstrap Code
BOOTSTRAP_CODE=<your-admin-bootstrap-code>
```

---

## Backend (Supabase)

### Start Backend (Local Supabase)
```bash
cd /Users/muhammadali3000/development/Star_Sitter/backend
supabase start
```

### Stop Backend
```bash
cd /Users/muhammadali3000/development/Star_Sitter/backend
supabase stop
```

### Push Migrations to Production
```bash
cd /Users/muhammadali3000/development/Star_Sitter/backend
supabase db push --linked
```

---

## Baby Sitter App (Flutter)

### Run on Emulator
```bash
cd apps/mobile/sitter
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

### Run on Connected Device (Wireless)
```bash
cd apps/mobile/sitter
flutter run \
  -d <your-device-id> \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

### Hot Reload (while running)
Press `r` in the terminal

### Hot Restart (while running)
Press `R` in the terminal

---

## Family App (Flutter)

### Run on Emulator
```bash
cd apps/mobile/family
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

### Run on Connected Device (Wireless)
```bash
cd apps/mobile/family
flutter run \
  -d <your-device-id> \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

---

## Admin Portal (Next.js)

### Run Admin Portal
```bash
cd /Users/muhammadali3000/development/Star_Sitter/apps/web/admin
npm run dev
```

Admin portal runs on: `http://localhost:3000`

### Signup Code
Use bootstrap code from your `.env` file (`BOOTSTRAP_CODE` variable)

---

## Check Connected Devices
```bash
adb devices
```

---

## Quick Reference

| App | Emulator | Device |
|-----|----------|--------|
| Baby Sitter | `flutter run` | `flutter run -d adb-RS5DJZL7DMV4FMD6-5EVCzz._adb-tls-connect._tcp` |
| Family | `flutter run` | `flutter run -d adb-RS5DJZL7DMV4FMD6-5EVCzz._adb-tls-connect._tcp` |
| Admin Portal | `npm run dev` | N/A (web only) |
| Backend | `supabase start` | N/A (cloud) |
