# Chat Job Information Display - COMPLETE

## Overview
Added job information display in chat screens for both sitter and family apps. Users can now see job details (title, date, time, number of children) directly in the chat header and message list.

## What Information is Displayed

### Job Details Shown
- **Job Title**: The name/description of the job
- **Date**: The date the job is scheduled
- **Start Time**: When the job starts
- **Number of Children**: How many children are involved

### Format
Information is displayed as: `"Job Title • Date • Time • X kids"`

Example: `"Babysitting • 2024-05-27 • 2:00 PM • 2 kids"`

## Implementation Details

### 1. Backend Changes
**File**: `packages/core/lib/src/data/conversations_repository.dart`

Added new method:
```dart
/// Fetches job details (title, date, start_time, end_time, number_of_children) for a conversation.
Future<Map<String, dynamic>?> fetchJobDetails(String conversationId) async {
  final conv = await _client
      .from('conversations')
      .select('job_id')
      .eq('id', conversationId)
      .maybeSingle();
  
  if (conv == null) return null;
  final jobId = (conv as Map)['job_id']?.toString();
  if (jobId == null || jobId.isEmpty) return null;

  final res = await _client
      .from('jobs')
      .select('title, date, start_time, end_time, number_of_children')
      .eq('id', jobId)
      .maybeSingle();

  return res == null ? null : Map<String, dynamic>.from(res as Map);
}
```

### 2. Sitter App Changes

#### File: `apps/mobile/sitter/lib/screens/messages_tab.dart`
- Updated `_SitterConversationItemState` to fetch job details
- Added `_jobInfo` field to store formatted job information
- Modified `_loadData()` to call `fetchJobDetails()`
- Updated `MessageListItem` to display job info in preview
- Pass `jobInfo` to `ChatScreen`

#### File: `apps/mobile/sitter/lib/screens/chat_screen.dart`
- Added `jobInfo` parameter to `ChatScreen` widget
- Updated chat header to display job info instead of generic "Secure Chat" subtitle
- Job info shows with ellipsis if too long

### 3. Family App Changes

#### File: `apps/mobile/family/lib/screens/messages_screen.dart`
- Updated `_ConversationTileState` to fetch job details
- Added `_jobInfo` field to store formatted job information
- Modified `_loadData()` to call `fetchJobDetails()`
- Updated conversation tile to display job info in preview
- Pass `jobInfo` to `SitterChatScreen`

#### File: `apps/mobile/family/lib/screens/sitter_chat_screen.dart`
- Added `jobInfo` parameter to `SitterChatScreen` widget
- Updated chat header to display job info
- Job info shows with ellipsis if too long
- Color changes based on whether job info is available

## User Experience

### Sitter App
1. User opens Messages tab
2. Each conversation shows:
   - Family name
   - Job details (title, date, time, kids count)
   - Last message time
   - Unread indicator
3. When opening a chat, header shows:
   - Family avatar
   - Family name
   - Job details (instead of "Secure Chat")

### Family App
1. User opens Messages screen
2. Each conversation shows:
   - Sitter name
   - Job details (title, date, time, kids count)
   - Last message time
3. When opening a chat, header shows:
   - Sitter avatar
   - Sitter name
   - Job details (instead of "Secure chat")

## Data Flow

```
Conversation (has job_id)
    ↓
fetchJobDetails()
    ↓
Query jobs table for: title, date, start_time, end_time, number_of_children
    ↓
Format as: "Title • Date • Time • X kids"
    ↓
Display in message list and chat header
```

## Files Modified

### Backend
- `packages/core/lib/src/data/conversations_repository.dart` - Added `fetchJobDetails()` method

### Sitter App
- `apps/mobile/sitter/lib/screens/messages_tab.dart` - Fetch and display job info
- `apps/mobile/sitter/lib/screens/chat_screen.dart` - Accept and display job info in header

### Family App
- `apps/mobile/family/lib/screens/messages_screen.dart` - Fetch and display job info
- `apps/mobile/family/lib/screens/sitter_chat_screen.dart` - Accept and display job info in header

## Benefits

1. **Context**: Users immediately see what job they're discussing
2. **Quick Reference**: No need to navigate to job details to remember the date/time
3. **Consistency**: Both apps show the same information
4. **Clarity**: Job details help distinguish between multiple conversations
5. **Efficiency**: Reduces confusion when managing multiple jobs/conversations

## Error Handling

- If job details fail to load, displays generic "Tap to view conversation" or "Secure chat"
- If job_id is missing from conversation, gracefully handles with empty job info
- Loading state shows spinner while fetching data

## Status
✅ **COMPLETE** - Job information now displays in chat screens for both apps
