# Windows Web Commands - PowerShell Ready

## Baby Sitter App - Web

### Single Line (PowerShell)
```powershell
cd apps/mobile/sitter; flutter run -d chrome --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

### Two Steps (Easier)
```powershell
cd apps/mobile/sitter
flutter run -d chrome --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

---

## Family App - Web

### Single Line (PowerShell)
```powershell
cd apps/mobile/family; flutter run -d chrome --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

### Two Steps (Easier)
```powershell
cd apps/mobile/family
flutter run -d chrome --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

---

## Running Both Apps Simultaneously

### Terminal 1 - Baby Sitter App
```powershell
cd apps/mobile/sitter
flutter run -d chrome --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

### Terminal 2 - Family App
```powershell
cd apps/mobile/family
flutter run -d chrome --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

---

## Key Differences: PowerShell vs Bash

| Operation | Bash | PowerShell |
|-----------|------|-----------|
| Chain commands | `&&` | `;` |
| Change directory | `cd` | `cd` (same) |
| Environment variable | `$VAR` | `$env:VAR` |

---

## Keyboard Shortcuts (while running)

- **`r`** - Hot reload (reload code changes)
- **`R`** - Hot restart (restart entire app)
- **`q`** - Quit (stop app and close Chrome)

---

## Recommended Approach

**Use the two-step method** - it's clearer and easier to debug:

```powershell
# Step 1: Navigate to the app
cd apps/mobile/sitter

# Step 2: Run the app
flutter run -d chrome --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

---

## Troubleshooting

### Error: "The token '&&' is not a valid statement separator"
**Solution**: Use `;` instead of `&&` in PowerShell

### Chrome not opening
- Make sure Chrome is installed
- Check if port 5000/5001 is available
- Try: `flutter run -d chrome --verbose` for more details

### App not loading
- Check browser console (F12)
- Verify Supabase credentials are correct
- Try hot reload (press `r`)

---

## Status
✅ Windows PowerShell commands ready
✅ Copy-paste ready
✅ Two-step method recommended
