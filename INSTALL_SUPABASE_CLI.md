# How to Install Supabase CLI on Windows

## Option 1: Using Scoop (Recommended for Windows)

### Step 1: Install Scoop (if not already installed)
```powershell
# Open PowerShell as Administrator and run:
iwr -useb get.scoop.sh | iex
```

### Step 2: Install Supabase CLI
```powershell
scoop install supabase
```

### Step 3: Verify Installation
```powershell
supabase --version
```

---

## Option 2: Using Docker

If you have Docker installed:

```powershell
docker run -it -v ${PWD}:/workspace supabase/cli:latest migration up
```

---

## Option 3: Direct Download (Manual)

1. Go to: https://github.com/supabase/cli/releases
2. Download the Windows binary (supabase-v1.x.x-windows-amd64.zip)
3. Extract to a folder
4. Add the folder to your PATH environment variable
5. Restart PowerShell
6. Run: `supabase --version`

---

## Option 4: Using Supabase Dashboard (No CLI Needed)

If you can't install the CLI, you can apply the migration directly:

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Create a new query
4. Copy the contents of `QUICK_FIX.sql`
5. Run the query

This is the fastest way if you just want to apply the fix without installing CLI.

---

## After Installation

Once you have the CLI installed, run:

```powershell
cd backend/supabase
supabase migration up
```

---

## Troubleshooting

### "supabase: The term is not recognized"
- Restart PowerShell after installation
- Verify installation: `supabase --version`
- Check PATH environment variable

### Permission Denied
- Run PowerShell as Administrator
- Try a different installation method

### Still Having Issues?
Use **Option 4** (Supabase Dashboard) to apply the migration directly without CLI.
