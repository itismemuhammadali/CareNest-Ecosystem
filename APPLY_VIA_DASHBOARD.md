# Apply Chat Profile Fix via Supabase Dashboard (No CLI Needed)

## Fastest Way - 5 Minutes

### Step 1: Open Supabase Dashboard
1. Go to your Supabase project: https://app.supabase.com
2. Select your project
3. Click on **SQL Editor** in the left sidebar

### Step 2: Create New Query
1. Click **New Query** button
2. Give it a name: "Fix Chat Profile Display"

### Step 3: Copy and Paste the SQL
Copy this SQL and paste it into the query editor:

```sql
-- Fix: Allow users to read conversation participants' profile data
-- Issue: Sitters couldn't see family names/avatars and vice versa due to RLS policy
-- Solution: Add policy allowing users to read other users' data if they're in a conversation

-- Users can read other users' profile data if they're in a conversation together
-- This allows sitters to see family names/avatars and vice versa
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

### Step 4: Run the Query
1. Click the **Run** button (or press Ctrl+Enter)
2. Wait for the query to complete
3. You should see: "Query executed successfully"

### Step 5: Verify the Fix
Run this verification query to confirm the policy was created:

```sql
SELECT policyname FROM pg_policies 
WHERE tablename = 'users' 
AND policyname = 'users: select conversation participants';
```

You should see one row with the policy name.

### Step 6: Restart the Apps
1. Close both Flutter apps completely
2. Restart the Sitter app
3. Restart the Family app

### Step 7: Test
1. **In Sitter App**:
   - Open Messages screen
   - Verify family names and avatars display correctly
   - Open a chat and verify header shows correct name/avatar

2. **In Family App**:
   - Open Messages screen
   - Verify sitter names and avatars display correctly
   - Open a chat and verify header shows correct name/avatar

---

## If Something Goes Wrong

### Rollback (Remove the Policy)
If you need to undo the change, run this query:

```sql
DROP POLICY IF EXISTS "users: select conversation participants" ON public.users;
```

### Check for Errors
If the query fails, check:
1. Are you logged in to Supabase?
2. Is the policy name spelled correctly?
3. Are there any error messages in the output?

---

## Verification Queries

### Check if Policy Exists
```sql
SELECT policyname, permissive, roles, qual 
FROM pg_policies 
WHERE tablename = 'users' 
AND policyname = 'users: select conversation participants';
```

### Test as Sitter (should return family profile data)
```sql
SELECT full_name, avatar_url 
FROM public.users 
WHERE id IN (
  SELECT family_id FROM public.conversations WHERE sitter_id = auth.uid()
);
```

### Test as Family (should return sitter profile data)
```sql
SELECT full_name, avatar_url 
FROM public.users 
WHERE id IN (
  SELECT sitter_id FROM public.conversations WHERE family_id = auth.uid()
);
```

### View All RLS Policies on Users Table
```sql
SELECT policyname, permissive, roles 
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;
```

---

## Done!

The chat profile display issue should now be fixed. Users will see:
- ✅ Actual chat partner names
- ✅ Actual chat partner avatars
- ✅ Clear, personalized chat experience

---

## Need Help?

If you encounter any issues:
1. Check the verification queries above
2. Review the error message in Supabase
3. Refer to `CHAT_PROFILE_FIX.md` for technical details
4. Check `APPLY_MIGRATION.md` for troubleshooting

---

**Time to Apply**: ~5 minutes
**Difficulty**: Easy
**Risk**: Low
**Reversible**: Yes (use rollback query above)
