# Running Star Sitters Apps on Web

## Quick Commands

### Baby Sitter App (Web)
```bash
cd apps/mobile/sitter
flutter run -d chrome \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

### Family App (Web)
```bash
cd apps/mobile/family
flutter run -d chrome \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

---

## Prerequisites

1. **Flutter SDK** installed and in PATH
2. **Chrome browser** installed
3. **Environment variables** set:
   - `SUPABASE_URL` - Your Supabase project URL
   - `SUPABASE_ANON_KEY` - Your Supabase anonymous key

---

## Setting Environment Variables

### On Windows (PowerShell)
```powershell
$env:SUPABASE_URL = "https://your-project.supabase.co"
$env:SUPABASE_ANON_KEY = "your-anon-key"
```

### On Windows (CMD)
```cmd
set SUPABASE_URL=https://your-project.supabase.co
set SUPABASE_ANON_KEY=your-anon-key
```

### On macOS/Linux
```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
```

---

## Running the Apps

### Step 1: Set Environment Variables
See section above for your OS

### Step 2: Run Baby Sitter App
```bash
cd apps/mobile/sitter
flutter run -d chrome \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

### Step 3: Run Family App (in another terminal)
```bash
cd apps/mobile/family
flutter run -d chrome \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

---

## Default URLs

When running on web, the apps will open in Chrome at:

- **Baby Sitter App**: `http://localhost:5000` (or similar)
- **Family App**: `http://localhost:5001` (or similar)

The exact port will be shown in the terminal output.

---

## Hot Reload on Web

While the app is running, you can:

- **Hot Reload**: Press `r` in the terminal
  - Reloads code changes without losing app state
  - Fastest way to see changes

- **Hot Restart**: Press `R` in the terminal
  - Restarts the entire app
  - Use if hot reload doesn't work

- **Quit**: Press `q` in the terminal
  - Stops the app and closes Chrome

---

## Troubleshooting

### Chrome Not Found
```bash
# Specify Chrome path explicitly
flutter run -d chrome --chrome-binary="/path/to/chrome"
```

### Port Already in Use
The app will automatically try the next available port. Check terminal output for the actual URL.

### Environment Variables Not Set
Make sure to set them in the same terminal before running the command.

### CORS Issues
If you see CORS errors, ensure your Supabase project allows requests from `localhost:5000` and `localhost:5001`.

---

## Running Both Apps Simultaneously

### Terminal 1 - Baby Sitter App
```bash
cd apps/mobile/sitter
flutter run -d chrome \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

### Terminal 2 - Family App
```bash
cd apps/mobile/family
flutter run -d chrome \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

Both apps will run in separate Chrome windows/tabs.

---

## Building for Web (Production)

### Build Baby Sitter App
```bash
cd apps/mobile/sitter
flutter build web \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

Output: `apps/mobile/sitter/build/web/`

### Build Family App
```bash
cd apps/mobile/family
flutter build web \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

Output: `apps/mobile/family/build/web/`

---

## Tips

1. **Keep terminal open** - The app runs in the terminal process
2. **Use hot reload** - Much faster than rebuilding
3. **Check console** - Open Chrome DevTools (F12) to see logs
4. **Test both apps** - Run them simultaneously to test chat/messaging
5. **Clear cache** - If you see stale data, clear browser cache

---

## Status
✅ Web support enabled for both apps
✅ Hot reload working
✅ Environment variables configurable
