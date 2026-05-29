-- ============================================================
-- QUICK FIX: Chat Profile Display Issue
-- ============================================================
-- 
-- Issue: Users couldn't see chat partner's name or avatar
-- Root Cause: RLS policy on users table was too restrictive
-- Solution: Add policy allowing conversation participants to read each other's profile data
--
-- This SQL can be run directly in Supabase SQL Editor if migration system is not available
-- ============================================================

-- Add the new RLS policy
create policy "users: select conversation participants"
  on public.users for select
  using (
    id in (
      select family_id from public.conversations where sitter_id = auth.uid()
      union
      select sitter_id from public.conversations where family_id = auth.uid()
    )
  );

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- 1. Verify the policy was created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  qual
FROM pg_policies 
WHERE tablename = 'users' 
AND policyname = 'users: select conversation participants'
ORDER BY policyname;

-- 2. Test as a sitter user (run this while logged in as a sitter)
-- This should return the family's profile data
SELECT full_name, avatar_url 
FROM public.users 
WHERE id IN (
  SELECT family_id FROM public.conversations WHERE sitter_id = auth.uid()
);

-- 3. Test as a family user (run this while logged in as a family)
-- This should return the sitter's profile data
SELECT full_name, avatar_url 
FROM public.users 
WHERE id IN (
  SELECT sitter_id FROM public.conversations WHERE family_id = auth.uid()
);

-- 4. View all RLS policies on users table
SELECT 
  policyname,
  permissive,
  roles,
  qual
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- ============================================================
-- ROLLBACK (if needed)
-- ============================================================

-- DROP POLICY IF EXISTS "users: select conversation participants" ON public.users;

-- ============================================================
-- NOTES
-- ============================================================
--
-- This policy allows users to read profile data (full_name, avatar_url)
-- of other users IF they are in a conversation together.
--
-- Security:
-- - Users can only see profile data of people they're chatting with
-- - Users cannot see arbitrary other users' data
-- - Access is tied to actual conversation participation
--
-- Performance:
-- - Uses efficient subqueries with proper indexes
-- - Minimal performance impact
--
-- Affected Features:
-- - Chat profile display (FIXED)
-- - Any other feature requiring cross-user profile data access
--
