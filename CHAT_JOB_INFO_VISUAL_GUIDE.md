# Chat Job Information - Visual Guide

## Sitter App - Messages Tab

### Before
```
┌─────────────────────────────────────┐
│ [Avatar] Sarah Johnson              │
│          Tap to view conversation   │
│                          2:30 PM    │
└─────────────────────────────────────┘
```

### After
```
┌─────────────────────────────────────┐
│ [Avatar] Sarah Johnson              │
│          Babysitting • 2024-05-27   │
│          2:00 PM • 2 kids           │
│                          2:30 PM    │
└─────────────────────────────────────┘
```

## Sitter App - Chat Header

### Before
```
┌─────────────────────────────────────┐
│ < Back                              │
│ [Avatar] Sarah Johnson              │
│          Secure Chat                │
└─────────────────────────────────────┘
```

### After
```
┌─────────────────────────────────────┐
│ < Back                              │
│ [Avatar] Sarah Johnson              │
│          Babysitting • 2024-05-27   │
│          2:00 PM • 2 kids           │
└─────────────────────────────────────┘
```

## Family App - Messages Screen

### Before
```
┌─────────────────────────────────────┐
│ [Avatar] Emma (Sitter)              │
│          Tap to open chat           │
│                          3:15 PM    │
└─────────────────────────────────────┘
```

### After
```
┌─────────────────────────────────────┐
│ [Avatar] Emma (Sitter)              │
│          Babysitting • 2024-05-27   │
│          2:00 PM • 2 kids           │
│                          3:15 PM    │
└─────────────────────────────────────┘
```

## Family App - Chat Header

### Before
```
┌─────────────────────────────────────┐
│ < Back                              │
│ [Avatar] Emma (Sitter)              │
│          Secure chat                │
└─────────────────────────────────────┘
```

### After
```
┌─────────────────────────────────────┐
│ < Back                              │
│ [Avatar] Emma (Sitter)              │
│          Babysitting • 2024-05-27   │
│          2:00 PM • 2 kids           │
└─────────────────────────────────────┘
```

## Job Information Format

The job information is displayed as a formatted string with bullet separators:

```
"Job Title • Date • Start Time • Number of Children"
```

### Examples

1. **Full Information**
   ```
   Babysitting • 2024-05-27 • 2:00 PM • 2 kids
   ```

2. **Without Time**
   ```
   Babysitting • 2024-05-27 • 3 kids
   ```

3. **Minimal Information**
   ```
   Babysitting • 2024-05-27
   ```

4. **Fallback (if job data unavailable)**
   ```
   Tap to view conversation  (Sitter app)
   Secure chat               (Family app)
   ```

## Data Sources

### Job Information Retrieved From
- **jobs.title** - Job title/description
- **jobs.date** - Scheduled date
- **jobs.start_time** - Start time
- **jobs.number_of_children** - Number of children

### Relationship
```
conversations.job_id → jobs.id
```

## Implementation Flow

```
User opens Messages
    ↓
Load conversations
    ↓
For each conversation:
  - Fetch partner profile (name, avatar)
  - Fetch job details (title, date, time, kids)
  - Format job info string
    ↓
Display in message list item
    ↓
User taps conversation
    ↓
Open chat screen with job info
    ↓
Display job info in chat header
```

## Benefits Summary

| Benefit | Description |
|---------|-------------|
| **Context** | Know which job you're discussing at a glance |
| **Quick Reference** | See date/time without leaving chat |
| **Organization** | Distinguish between multiple conversations |
| **Efficiency** | Reduce context switching |
| **Clarity** | Clear job details for both parties |

## Status
✅ Implemented in both Sitter and Family apps
✅ Displays in message list and chat header
✅ Graceful fallback if job data unavailable
