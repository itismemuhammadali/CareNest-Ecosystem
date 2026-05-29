# Star Sitters - Run Commands

## Environment Setup
```bash
# Supabase credentials (production)
SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA

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
  --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

### Run on Connected Device (Wireless)
```bash
cd apps/mobile/sitter
flutter run \
  -d <your-device-id> \
  --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

### Run on Web
```bash
cd apps/mobile/sitter
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
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
  --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

### Run on Connected Device (Wireless)
```bash
cd apps/mobile/family
flutter run \
  -d <your-device-id> \
  --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

### Run on Web
```bash
cd apps/mobile/family
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
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

| App | Emulator | Device | Web |
|-----|----------|--------|-----|
| Baby Sitter | `flutter run` | `flutter run -d adb-RS5DJZL7DMV4FMD6-5EVCzz._adb-tls-connect._tcp` | `flutter run -d chrome` |
| Family | `flutter run` | `flutter run -d adb-RS5DJZL7DMV4FMD6-5EVCzz._adb-tls-connect._tcp` | `flutter run -d chrome` |
| Admin Portal | `npm run dev` | N/A (web only) | `npm run dev` |
| Backend | `supabase start` | N/A (cloud) | N/A |
