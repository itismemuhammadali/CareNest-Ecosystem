# How to Apply the Chat Profile Fix

## Quick Start

### Local Development (Supabase CLI)

```bash
# Navigate to the backend directory
cd backend/supabase

# Apply all pending migrations (including the new RLS fix)
supabase migration up

# Or, if you want to see what migrations will be applied:
supabase migration list
```

### Production (Supabase Dashboard or CLI)

#### Option 1: Using Supabase CLI
```bash
# Link to your production project (if not already linked)
supabase link --project-ref your-project-ref

# Push the migration
supabase db push --project-ref your-project-ref

# Verify it was applied
supabase migration list --project-ref your-project-ref
```

#### Option 2: Using Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Create a new query
4. Copy the contents of `backend/supabase/migrations/01_rls/006_chat_users_rls_fix.sql`
5. Run the query

## Verification

### Check if the Policy Was Created

Run this query in your Supabase SQL Editor:

```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'users' 
ORDER BY policyname;
```

You should see a policy named `"users: select conversation participants"` in the results.

### Test the Fix

1. **As a Sitter User:**
   ```sql
   -- This should return the family's full_name and avatar_url
   SELECT full_name, avatar_url 
   FROM public.users 
   WHERE id IN (
     SELECT family_id FROM public.conversations WHERE sitter_id = auth.uid()
   );
   ```

2. **As a Family User:**
   ```sql
   -- This should return the sitter's full_name and avatar_url
   SELECT full_name, avatar_url 
   FROM public.users 
   WHERE id IN (
     SELECT sitter_id FROM public.conversations WHERE family_id = auth.uid()
   );
   ```

## After Migration

### Restart Applications

1. **Flutter Apps**: Restart both the family and sitter apps
2. **Backend Services**: Restart any backend services that cache user data

### Verify in App

1. Open the Messages screen in either app
2. Check that conversation partner names and avatars now display correctly
3. Open a chat and verify the header shows the correct name and avatar

## Rollback (If Needed)

If you need to rollback this change:

```sql
DROP POLICY IF EXISTS "users: select conversation participants" ON public.users;
```

However, this will revert to the broken state where users can't see each other's profile data.

## Migration File Location

The migration file is located at:
```
backend/supabase/migrations/01_rls/006_chat_users_rls_fix.sql
```

## What This Migration Does

- **Adds**: A new RLS policy on the `users` table
- **Allows**: Users to read profile data (full_name, avatar_url) of their conversation partners
- **Restricts**: Access only to users they're actually chatting with
- **Maintains**: Security by preventing access to unrelated users' data

## Troubleshooting

### Policy Not Appearing
- Ensure the migration ran successfully
- Check Supabase logs for any SQL errors
- Verify you're querying the correct schema (should be `public`)

### Still Seeing Generic Names/Avatars
- Clear app cache and restart the app
- Verify the policy is active (run the verification query above)
- Check that users have actual conversations in the database
- Verify `full_name` and `avatar_url` are populated in the users table

### Performance Issues
- The policy uses a subquery which is efficient for small conversation counts
- If you have thousands of conversations, consider indexing strategies
- Monitor query performance in Supabase dashboard

## Questions?

Refer to `CHAT_PROFILE_FIX.md` for detailed technical information about the issue and solution.
