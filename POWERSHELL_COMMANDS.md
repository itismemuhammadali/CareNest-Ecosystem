# PowerShell Commands - Correct Format

## Baby Sitter App - Web

### Single Line (Copy & Paste)
```powershell
cd apps/mobile/sitter; flutter run -d chrome --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

### Multi-Line (with backtick `)
```powershell
cd apps/mobile/sitter
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

---

## Family App - Web

### Single Line (Copy & Paste)
```powershell
cd apps/mobile/family; flutter run -d chrome --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

### Multi-Line (with backtick `)
```powershell
cd apps/mobile/family
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

---

## RECOMMENDED: Two Separate Commands

This is the easiest and most reliable method:

### Baby Sitter App
```powershell
cd apps/mobile/sitter
```

Then paste this:
```powershell
flutter run -d chrome --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

### Family App
```powershell
cd apps/mobile/family
```

Then paste this:
```powershell
flutter run -d chrome --dart-define=SUPABASE_URL=https://kfavdpqaaxzauovzrcas.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYXZkcHFhYXh6YXVvdnpyY2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNzM5NzYsImV4cCI6MjA5Mzk0OTk3Nn0.rRe4Fc6_SBxGVQgZ9qez4umnb0x10LwV9_YY4E4NjnA
```

---

## PowerShell Line Continuation

| Symbol | Usage | Example |
|--------|-------|---------|
| `` ` `` (backtick) | Line continuation in PowerShell | `command `<br/>`  --param value` |
| `\` (backslash) | Line continuation in Bash/Linux | `command \`<br/>`  --param value` |
| `;` (semicolon) | Command separator in PowerShell | `command1; command2` |
| `&&` (double ampersand) | Command separator in Bash/Linux | `command1 && command2` |

---

## What to Do

### Option 1: Single Line (Easiest)
Copy the entire command on one line and paste it into PowerShell.

### Option 2: Two Commands (Recommended)
1. First command: `cd apps/mobile/family`
2. Second command: `flutter run -d chrome --dart-define=...`

### Option 3: Multi-Line with Backtick
Use backtick (`` ` ``) at the end of each line to continue on the next line.

---

## Keyboard Shortcuts (while running)

- **`r`** - Hot reload
- **`R`** - Hot restart
- **`q`** - Quit

---

## Status
✅ PowerShell commands corrected
✅ Backtick line continuation explained
✅ Two-command method recommended
