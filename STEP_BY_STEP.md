# Step-by-Step Guide to Fix Chat Profile Display

## Overview
This guide walks you through applying the fix in the easiest way possible.

---

## Step 1: Open Supabase Dashboard

### What to Do
1. Open your web browser
2. Go to: **https://app.supabase.com**
3. Log in with your credentials
4. Select your **Star Sitters** project

### What You Should See
- Project dashboard with various options in the left sidebar
- Your project name at the top

---

## Step 2: Navigate to SQL Editor

### What to Do
1. In the left sidebar, find **SQL Editor**
2. Click on it

### What You Should See
- SQL Editor interface
- A list of saved queries (if any)
- A **New Query** button

---

## Step 3: Create a New Query

### What to Do
1. Click the **New Query** button
2. A new query editor will open
3. Give it a name (optional): "Fix Chat Profile Display"

### What You Should See
- Empty SQL editor
- Cursor ready for input

---

## Step 4: Copy the SQL Code

### The SQL Code to Copy
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

### What to Do
1. Select all the SQL code above
2. Copy it (Ctrl+C)
3. Paste it into the Supabase SQL editor (Ctrl+V)

### What You Should See
- The SQL code in the editor
- Syntax highlighting (keywords in different colors)

---

## Step 5: Run the Query

### What to Do
1. Look for the **Run** button (usually at the bottom right or top right)
2. Click it
3. Wait for the query to complete

### What You Should See
- A message saying "Query executed successfully"
- Or if there's an error, an error message

### If You See an Error
- Check that you copied the SQL correctly
- Make sure there are no typos
- Try again

---

## Step 6: Verify the Fix Was Applied

### The Verification Query
```sql
SELECT policyname FROM pg_policies 
WHERE tablename = 'users' 
AND policyname = 'users: select conversation participants';
```

### What to Do
1. Create a new query in SQL Editor
2. Copy and paste the verification query above
3. Click **Run**

### What You Should See
- One row in the results
- The row should show: `users: select conversation participants`

### If You Don't See It
- The policy wasn't created
- Go back to Step 4 and try again
- Make sure the first query ran successfully

---

## Step 7: Restart the Flutter Apps

### For Sitter App
1. Close the Sitter app completely (swipe it away or force close)
2. Wait 5 seconds
3. Reopen the Sitter app

### For Family App
1. Close the Family app completely (swipe it away or force close)
2. Wait 5 seconds
3. Reopen the Family app

### What You Should See
- Apps restart normally
- No error messages

---

## Step 8: Test the Fix

### Test in Sitter App
1. Open the Sitter app
2. Go to **Messages** screen
3. Look at the conversation list
4. **Verify**: You should see the family's actual name (not "Family")
5. **Verify**: You should see the family's actual avatar (not default icon)
6. Tap on a conversation to open the chat
7. **Verify**: The header shows the family's actual name and avatar

### Test in Family App
1. Open the Family app
2. Go to **Messages** screen
3. Look at the conversation list
4. **Verify**: You should see the sitter's actual name (not "Sitter")
5. **Verify**: You should see the sitter's actual avatar (not default icon)
6. Tap on a conversation to open the chat
7. **Verify**: The header shows the sitter's actual name and avatar

### What Success Looks Like
- ✅ Names are displayed correctly
- ✅ Avatars are displayed correctly
- ✅ No error messages
- ✅ Chat works normally

---

## Step 9: Done! 🎉

The fix has been successfully applied!

### What Changed
- Users can now see their chat partner's actual name
- Users can now see their chat partner's actual avatar
- Chat feature is now fully functional

### What to Do Next
- Enjoy the fixed chat feature
- Report any issues if they occur
- Share the good news with your team

---

## Troubleshooting

### Problem: "Query executed successfully" but names still show as "Family"/"Sitter"

**Solution**:
1. Make sure you restarted the apps (Step 7)
2. Clear the app cache:
   - Go to Settings → Apps → Star Sitters
   - Tap Storage → Clear Cache
   - Restart the app
3. Try again

### Problem: Error message when running the query

**Solution**:
1. Check that you copied the SQL correctly
2. Make sure there are no extra spaces or characters
3. Try copying and pasting again
4. If it still doesn't work, contact support

### Problem: Verification query shows no results

**Solution**:
1. The policy wasn't created
2. Go back to Step 4
3. Make sure the first query ran successfully
4. Try running it again

### Problem: Apps won't restart

**Solution**:
1. Force close the app (Settings → Apps → Star Sitters → Force Stop)
2. Wait 10 seconds
3. Reopen the app

---

## Quick Reference

| Step | Action | Time |
|------|--------|------|
| 1 | Open Supabase Dashboard | 1 min |
| 2 | Go to SQL Editor | 1 min |
| 3 | Create new query | 1 min |
| 4 | Copy & paste SQL | 1 min |
| 5 | Run query | 1 min |
| 6 | Verify fix | 1 min |
| 7 | Restart apps | 2 min |
| 8 | Test fix | 2 min |
| **Total** | **Done!** | **~10 min** |

---

## Need Help?

If you get stuck:
1. Check the **Troubleshooting** section above
2. Review the **APPLY_VIA_DASHBOARD.md** file
3. Check the **CHAT_PROFILE_FIX.md** for technical details
4. Contact your development team

---

**Difficulty**: Easy ⭐
**Time Required**: ~10 minutes
**Risk Level**: Low
**Reversible**: Yes

Good luck! 🚀
