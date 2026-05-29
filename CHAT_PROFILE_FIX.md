# Chat Profile Display Fix - Complete Audit & Solution

## Problem Summary
Users in both the family app and babysitter app were unable to see:
1. The actual name of their chat partner (showing generic "Family" or "Sitter" instead)
2. The profile picture of their chat partner (showing default avatar icon)

## Root Cause Analysis

### Database Schema Issue
The `conversations` table stores:
- `family_id` → references `family_profiles.user_id` (which is a `users.id`)
- `sitter_id` → references `sitter_profiles.user_id` (which is a `users.id`)

### RLS Policy Blocking Data Access
The critical issue was in the RLS (Row Level Security) policy on the `users` table:

```sql
-- ORIGINAL POLICY (BLOCKING)
create policy "users: select own"
  on public.users for select
  using (id = auth.uid());
```

This policy only allowed users to read their OWN user record. When a sitter tried to fetch a family's profile data (name and avatar), the RLS policy blocked the query because:
- The sitter's `auth.uid()` ≠ the family's `id`
- Result: Query returned NULL, UI showed default values

### Code Flow That Was Failing
1. User opens Messages screen
2. `_ConversationTile` calls `ConversationsRepository.fetchPartnerProfile(conversationId)`
3. Repository queries: `SELECT full_name, avatar_url FROM users WHERE id = partnerId`
4. **RLS Policy blocks the query** because `partnerId ≠ auth.uid()`
5. Query returns NULL
6. UI displays default "Family" / "Sitter" text and default avatar icon

## Solution

### New RLS Policy
Created a new migration file: `backend/supabase/migrations/01_rls/006_chat_users_rls_fix.sql`

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

### How It Works
This policy allows a user to read another user's profile data IF:
- The current user is a sitter AND the target user is the family in one of their conversations, OR
- The current user is a family AND the target user is a sitter in one of their conversations

### Security Considerations
✅ **Secure**: Users can only see profile data of people they're actually chatting with
✅ **No data leakage**: Users cannot see arbitrary other users' data
✅ **Conversation-based**: Access is tied to actual conversation participation
✅ **Bidirectional**: Works for both family→sitter and sitter→family lookups

## Files Modified

### 1. New Migration File
- **File**: `backend/supabase/migrations/01_rls/006_chat_users_rls_fix.sql`
- **Change**: Added new RLS policy to allow conversation participants to read each other's profile data

### 2. UI Code Changes (Already Applied)
- **File**: `apps/mobile/family/lib/screens/messages_screen.dart`
- **Change**: Removed hardcoded navigation that was bypassing the proper data fetching

## Implementation Steps

### For Local Development
1. Run Supabase migrations:
   ```bash
   cd backend/supabase
   supabase migration up
   ```

2. Restart the Flutter apps to pick up the new RLS policy

### For Production
1. Deploy the migration to your Supabase project:
   ```bash
   supabase db push --project-ref <your-project-ref>
   ```

2. Verify the policy was created:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'users';
   ```

## Testing

### Test Case 1: Sitter Viewing Family Profile
1. Log in as a sitter
2. Open Messages screen
3. Verify: Family name and avatar display correctly in conversation list
4. Tap conversation to open chat
5. Verify: Family name and avatar display in chat header

### Test Case 2: Family Viewing Sitter Profile
1. Log in as a family
2. Open Messages screen
3. Verify: Sitter name and avatar display correctly in conversation list
4. Tap conversation to open chat
5. Verify: Sitter name and avatar display in chat header

### Test Case 3: Security - Cannot See Unrelated Users
1. Log in as a sitter
2. Attempt to query another user's data directly (not in a conversation)
3. Verify: RLS policy blocks the query (returns NULL)

## Database Query Verification

To verify the fix is working, run this query as a sitter user:

```sql
-- This should now return the family's profile data
SELECT full_name, avatar_url 
FROM public.users 
WHERE id IN (
  SELECT family_id FROM public.conversations WHERE sitter_id = auth.uid()
);
```

Before the fix: Returns empty (RLS blocked)
After the fix: Returns family profile data

## Related Code Files

### Data Layer
- `packages/core/lib/src/data/conversations_repository.dart` - Fetches partner profile
- `packages/core/lib/src/data/messages_repository.dart` - Handles message streaming

### UI Layer - Family App
- `apps/mobile/family/lib/screens/messages_screen.dart` - Messages list with conversation tiles
- `apps/mobile/family/lib/screens/sitter_chat_screen.dart` - Chat screen header

### UI Layer - Sitter App
- `apps/mobile/sitter/lib/screens/messages_screen.dart` - Messages list with conversation tiles
- `apps/mobile/sitter/lib/screens/chat_screen.dart` - Chat screen header

### Database Schema
- `backend/supabase/migrations/00_schema/003_users.sql` - Users table definition
- `backend/supabase/migrations/00_schema/008_chat.sql` - Conversations and messages tables
- `backend/supabase/migrations/01_rls/001_rls_policies.sql` - Original RLS policies

## Summary

The issue was a **database-level RLS policy** that prevented users from reading each other's profile data, not a code logic issue. The fix adds a targeted RLS policy that allows conversation participants to see each other's names and avatars while maintaining security by restricting access to only actual conversation participants.

This is a **database migration** that must be applied to both local development and production environments for the fix to take effect.
