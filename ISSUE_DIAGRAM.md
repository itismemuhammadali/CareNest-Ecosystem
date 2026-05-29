# Chat Profile Display Issue - Visual Diagrams

## Problem Visualization

### Current (Broken) Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    SITTER APP - Messages Screen                 │
│                                                                   │
│  Conversation List:                                              │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ [?] Family                                               │   │
│  │     Tap to view conversation                             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  Expected: [👤 John Doe] John Doe                               │
│  Actual:   [?] Family                                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    User taps conversation
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    SITTER APP - Chat Screen                      │
│                                                                   │
│  Header:                                                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ [?] Family                                               │   │
│  │     Secure chat                                          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  Expected: [👤 John Doe] John Doe                               │
│  Actual:   [?] Family                                            │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow - Where It Breaks

```
┌──────────────────────────────────────────────────────────────────────┐
│                         SITTER USER                                   │
│                    auth.uid = sitter-uuid-123                        │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
                    Opens Messages Screen
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│  Query: SELECT * FROM conversations WHERE sitter_id = auth.uid()    │
│  RLS Policy: "conversations: participants select"                    │
│  Result: ✅ ALLOWED (user is participant)                            │
│  Returns: [{ id: conv-1, family_id: family-uuid-456, ... }]         │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
                    For each conversation, fetch partner profile
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│  Query: SELECT full_name, avatar_url FROM users                      │
│          WHERE id = family-uuid-456                                  │
│                                                                       │
│  RLS Policy: "users: select own"                                     │
│  Condition: id = auth.uid()                                          │
│  Check: family-uuid-456 = sitter-uuid-123?                           │
│  Result: ❌ BLOCKED (user is NOT the target user)                    │
│  Returns: NULL                                                        │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
                    Application receives NULL
                              ↓
                    UI displays default values
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│  Screen shows:                                                        │
│  - Name: "Family" (default)                                          │
│  - Avatar: [?] (default icon)                                        │
└──────────────────────────────────────────────────────────────────────┘
```

## Solution Visualization

### Fixed Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│  Query: SELECT full_name, avatar_url FROM users                      │
│          WHERE id = family-uuid-456                                  │
│                                                                       │
│  RLS Policy: "users: select conversation participants"               │
│  Condition: id IN (                                                  │
│    SELECT family_id FROM conversations WHERE sitter_id = auth.uid()  │
│    UNION                                                              │
│    SELECT sitter_id FROM conversations WHERE family_id = auth.uid()  │
│  )                                                                    │
│                                                                       │
│  Check: Is family-uuid-456 in the list of:                           │
│    - Families where sitter-uuid-123 is a sitter? YES ✅              │
│                                                                       │
│  Result: ✅ ALLOWED (user is conversation participant)               │
│  Returns: { full_name: "John Doe", avatar_url: "https://..." }      │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
                    Application receives data
                              ↓
                    UI displays actual values
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│  Screen shows:                                                        │
│  - Name: "John Doe" ✅                                               │
│  - Avatar: [👤] (actual image) ✅                                    │
└──────────────────────────────────────────────────────────────────────┘
```

## RLS Policy Comparison

### Before (Broken)
```
┌─────────────────────────────────────────────────────────────────┐
│  Policy: "users: select own"                                    │
│                                                                  │
│  Allows: User can read their OWN user record                    │
│                                                                  │
│  Condition: id = auth.uid()                                     │
│                                                                  │
│  Example:                                                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Sitter (auth.uid = sitter-123) can read:                │   │
│  │ ✅ User record where id = sitter-123                    │   │
│  │ ❌ User record where id = family-456                    │   │
│  │ ❌ User record where id = other-sitter-789              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Result: ❌ Cannot see chat partner's profile                   │
└─────────────────────────────────────────────────────────────────┘
```

### After (Fixed)
```
┌─────────────────────────────────────────────────────────────────┐
│  Policy: "users: select conversation participants"              │
│                                                                  │
│  Allows: User can read profile of conversation participants     │
│                                                                  │
│  Condition: id IN (                                             │
│    SELECT family_id FROM conversations WHERE sitter_id = uid    │
│    UNION                                                         │
│    SELECT sitter_id FROM conversations WHERE family_id = uid    │
│  )                                                               │
│                                                                  │
│  Example:                                                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Sitter (auth.uid = sitter-123) can read:                │   │
│  │ ✅ User record where id = sitter-123 (own)              │   │
│  │ ✅ User record where id = family-456 (in conversation)  │   │
│  │ ❌ User record where id = other-sitter-789 (not in conv)│   │
│  │ ❌ User record where id = random-family-999 (not in conv)│   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Result: ✅ Can see chat partner's profile                      │
│  Security: ✅ Cannot see unrelated users' profiles              │
└─────────────────────────────────────────────────────────────────┘
```

## Database Relationship Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                         USERS TABLE                               │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ id (PK)      │ full_name    │ avatar_url  │ ...            │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │ sitter-123   │ "Jane Smith" │ "url/..."   │                │  │
│  │ family-456   │ "John Doe"   │ "url/..."   │                │  │
│  │ other-789    │ "Bob Jones"  │ "url/..."   │                │  │
│  └────────────────────────────────────────────────────────────┘  │
│         ↑                                                          │
│         │ (foreign key)                                           │
│         │                                                          │
│  ┌──────┴──────────────────────────────────────────────────────┐  │
│  │              CONVERSATIONS TABLE                            │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │ id      │ family_id  │ sitter_id  │ job_id │ created_at │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │ conv-1  │ family-456 │ sitter-123 │ job-1  │ ...        │  │
│  │ conv-2  │ family-456 │ sitter-789 │ job-2  │ ...        │  │
│  └──────────────────────────────────────────────────────────┘  │
│         ↑                                                          │
│         │ (foreign key)                                           │
│         │                                                          │
│  ┌──────┴──────────────────────────────────────────────────────┐  │
│  │              MESSAGES TABLE                                │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │ id  │ conversation_id │ sender_id  │ body │ created_at   │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │ m-1 │ conv-1          │ sitter-123 │ "hi" │ ...          │  │
│  │ m-2 │ conv-1          │ family-456 │ "hi" │ ...          │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘

RLS Policy Logic:
─────────────────

When sitter-123 queries users table:
  ✅ Can read: sitter-123 (own record)
  ✅ Can read: family-456 (in conversation conv-1)
  ❌ Cannot read: other-789 (not in any conversation)

When family-456 queries users table:
  ✅ Can read: family-456 (own record)
  ✅ Can read: sitter-123 (in conversation conv-1)
  ✅ Can read: sitter-789 (in conversation conv-2)
  ❌ Cannot read: other-789 (not in any conversation)
```

## Query Execution Timeline

### Before Fix (Broken)

```
Timeline:
─────────

T1: Sitter opens Messages screen
    └─ auth.uid() = sitter-123

T2: Query conversations
    └─ SELECT * FROM conversations WHERE sitter_id = sitter-123
    └─ RLS: ✅ ALLOWED (user is participant)
    └─ Returns: [{ id: conv-1, family_id: family-456, ... }]

T3: For each conversation, fetch partner profile
    └─ partnerId = family-456

T4: Query users table
    └─ SELECT full_name, avatar_url FROM users WHERE id = family-456
    └─ RLS Check: Is family-456 = sitter-123? NO
    └─ RLS: ❌ BLOCKED
    └─ Returns: NULL

T5: UI receives NULL
    └─ Displays default "Family" and default avatar icon

Result: ❌ BROKEN - User sees generic names/avatars
```

### After Fix (Working)

```
Timeline:
─────────

T1: Sitter opens Messages screen
    └─ auth.uid() = sitter-123

T2: Query conversations
    └─ SELECT * FROM conversations WHERE sitter_id = sitter-123
    └─ RLS: ✅ ALLOWED (user is participant)
    └─ Returns: [{ id: conv-1, family_id: family-456, ... }]

T3: For each conversation, fetch partner profile
    └─ partnerId = family-456

T4: Query users table
    └─ SELECT full_name, avatar_url FROM users WHERE id = family-456
    └─ RLS Check: Is family-456 in (
    │    SELECT family_id FROM conversations WHERE sitter_id = sitter-123
    │  )?
    └─ Check: family-456 in [family-456]? YES
    └─ RLS: ✅ ALLOWED
    └─ Returns: { full_name: "John Doe", avatar_url: "https://..." }

T5: UI receives data
    └─ Displays "John Doe" and actual avatar image

Result: ✅ WORKING - User sees actual names/avatars
```

## Security Boundary Visualization

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY BOUNDARIES                          │
│                                                                  │
│  Sitter-123's Accessible Data:                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ ✅ Own profile (sitter-123)                              │  │
│  │ ✅ Family-456 profile (in conversation)                  │  │
│  │ ✅ Sitter-789 profile (in conversation)                  │  │
│  │ ❌ Random-User-999 profile (not in conversation)         │  │
│  │ ❌ Admin-001 profile (not in conversation)               │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Family-456's Accessible Data:                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ ✅ Own profile (family-456)                              │  │
│  │ ✅ Sitter-123 profile (in conversation)                  │  │
│  │ ✅ Sitter-789 profile (in conversation)                  │  │
│  │ ❌ Random-Sitter-999 profile (not in conversation)       │  │
│  │ ❌ Admin-001 profile (not in conversation)               │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Result: ✅ Secure - Users can only see conversation partners   │
└─────────────────────────────────────────────────────────────────┘
```

## Summary

The issue was that the RLS policy was too restrictive, preventing users from reading each other's profile data even though they were in active conversations. The fix adds a policy that allows users to read profile data of their conversation partners while maintaining security by preventing access to unrelated users' data.
