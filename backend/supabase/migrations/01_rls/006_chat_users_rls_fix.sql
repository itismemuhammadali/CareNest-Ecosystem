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
