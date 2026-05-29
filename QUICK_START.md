# Quick Start - Apply Chat Profile Fix in 5 Minutes

## The Problem
Chat shows generic names ("Family", "Sitter") and default avatars instead of actual names and pictures.

## The Solution
Apply one SQL query to fix the RLS policy.

## How to Apply (Choose One)

### ⚡ FASTEST: Via Supabase Dashboard (No Installation Needed)

1. **Open Supabase Dashboard**
   - Go to: https://app.supabase.com
   - Select your project

2. **Go to SQL Editor**
   - Click **SQL Editor** in left sidebar
   - Click **New Query**

3. **Copy & Paste This SQL**
   ```sql
   create policy "users: select conversation participants"
     on public.users for select
     using (
       id in (
         select family_id from public.conversations where sitter_id = auth.uid()
         union
         select sitter_id from public.conversations where family_id = auth.uid()
       )
     );
   ```

4. **Run It**
   - Click **Run** button
   - Wait for "Query executed successfully"

5. **Restart Apps**
   - Close both Flutter apps
   - Reopen them

6. **Test**
   - Open Messages screen
   - Verify names and avatars display correctly ✅

---

### 🔧 Alternative: Using CLI

If you prefer command line:

```powershell
# Install Supabase CLI (if not already installed)
scoop install supabase

# Navigate to project
cd backend/supabase

# Apply migration
supabase migration up

# Restart apps
```

---

### 📋 Verification

After applying, run this query to verify:

```sql
SELECT policyname FROM pg_policies 
WHERE tablename = 'users' 
AND policyname = 'users: select conversation participants';
```

You should see one row with the policy name.

---

## ✅ Success Indicators

After applying the fix, you should see:
- ✅ Actual sitter/family names in chat list
- ✅ Actual profile pictures in chat list
- ✅ Correct name and avatar in chat header
- ✅ No errors in app logs

---

## ❌ If It Doesn't Work

### Check 1: Verify Policy Was Created
```sql
SELECT policyname FROM pg_policies 
WHERE tablename = 'users' 
AND policyname = 'users: select conversation participants';
```

If no results, the query didn't run successfully.

### Check 2: Clear App Cache
- Close the app completely
- Clear app cache (Settings → Apps → Star Sitters → Storage → Clear Cache)
- Restart the app

### Check 3: Check for Errors
- Look at Supabase logs for any errors
- Check app console for error messages

### Check 4: Rollback (if needed)
```sql
DROP POLICY IF EXISTS "users: select conversation participants" ON public.users;
```

---

## 📚 More Information

- **APPLY_VIA_DASHBOARD.md** - Detailed dashboard instructions
- **CHAT_PROFILE_FIX.md** - Technical explanation
- **AUDIT_FINDINGS.md** - Why this happened
- **ISSUE_DIAGRAM.md** - Visual diagrams

---

## 🎯 Summary

| Step | Time | Action |
|------|------|--------|
| 1 | 1 min | Open Supabase Dashboard |
| 2 | 1 min | Go to SQL Editor |
| 3 | 1 min | Copy & paste SQL |
| 4 | 1 min | Run query |
| 5 | 1 min | Restart apps |
| **Total** | **~5 min** | **Done!** |

---

**Status**: Ready to apply
**Difficulty**: Easy
**Risk**: Low
**Time**: 5 minutes
