# Loading Animation and Avatar Image Fix

## Issues to Fix

### Issue 1: Loading Animation on Home Screen
**Problem**: Loading spinner appears on home screen after sign-in, making the app feel slow
**Solution**: Move loading to sign-in button, pre-load data before showing home screen

### Issue 2: Avatar Placeholder Flash
**Problem**: Default avatar icon shows first, then actual image loads (flickering effect)
**Solution**: Only show actual image when loaded, don't show placeholder

---

## Implementation Plan

### Part 1: Move Loading to Sign-In Button

**Files to Modify**:
1. `apps/mobile/sitter/lib/screens/sign_in_screen.dart`
2. `apps/mobile/family/lib/screens/sign_in_screen.dart`

**Changes**:
- Add loading indicator to sign-in button
- Show spinner inside button while signing in
- Disable button during sign-in

**Current Code**:
```dart
PrimaryButton(
  label: _busy ? 'Signing in…' : 'Sign In',
  onPressed: _busy ? () {} : _signIn,
),
```

**New Code**:
```dart
PrimaryButton(
  label: 'Sign In',
  onPressed: _busy ? () {} : _signIn,
  isLoading: _busy,  // Add loading indicator inside button
),
```

### Part 2: Pre-load Data Before Showing Home

**Files to Modify**:
1. `apps/mobile/sitter/lib/widgets/auth_gate.dart`
2. `apps/mobile/family/lib/widgets/auth_gate.dart`

**Changes**:
- Pre-fetch user profile data before navigating to home
- Show loading only on sign-in button, not full screen
- Ensure home screen loads with data already available

### Part 3: Fix Avatar Image Loading

**Files to Modify**:
1. `apps/mobile/sitter/lib/widgets/home/home_header.dart`
2. `apps/mobile/family/lib/widgets/home_header.dart`
3. All CircleAvatar implementations showing user avatars

**Current Code**:
```dart
CircleAvatar(
  radius: 24,
  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
      ? NetworkImage(_avatarUrl!) as ImageProvider
      : null,
  backgroundColor: Colors.white12,
  child: _avatarUrl == null || _avatarUrl!.isEmpty
      ? SvgPicture.asset('assets/profile-icon.svg', ...)
      : null,
),
```

**Problem**: 
- Shows default SVG icon first
- Then loads actual image
- Creates flickering effect

**Solution**:
- Use `Image.network()` with `fit: BoxFit.cover`
- Use `errorBuilder` to show placeholder only on error
- Don't show placeholder while loading

**New Code**:
```dart
CircleAvatar(
  radius: 24,
  backgroundColor: Colors.white12,
  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
      ? NetworkImage(_avatarUrl!) as ImageProvider
      : null,
  child: _avatarUrl == null || _avatarUrl!.isEmpty
      ? SvgPicture.asset('assets/profile-icon.svg', ...)
      : null,
),
```

Or better approach using `Image.network`:

```dart
Container(
  width: 48,
  height: 48,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white12,
  ),
  child: _avatarUrl != null && _avatarUrl!.isNotEmpty
      ? ClipOval(
          child: Image.network(
            _avatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return SvgPicture.asset('assets/profile-icon.svg', ...);
            },
          ),
        )
      : SvgPicture.asset('assets/profile-icon.svg', ...),
),
```

---

## Step-by-Step Implementation

### Step 1: Update PrimaryButton Widget
Add `isLoading` parameter to show spinner inside button

### Step 2: Update Sign-In Screens
- Pass `isLoading: _busy` to PrimaryButton
- Keep loading on button, not full screen

### Step 3: Update AuthGate
- Pre-fetch profile data before navigation
- Ensure data is available when home screen loads

### Step 4: Update Avatar Loading
- Use `Image.network` with proper error handling
- Don't show placeholder while loading
- Only show placeholder on error

---

## Expected Results

### Before
- ❌ Loading spinner on home screen after sign-in
- ❌ Default avatar shows, then actual image loads
- ❌ Flickering effect when avatars load

### After
- ✅ Loading spinner only on sign-in button
- ✅ Actual avatar image loads directly
- ✅ No flickering or placeholder flash
- ✅ Smooth user experience

---

## Files to Modify

1. `apps/mobile/sitter/lib/widgets/primary_button.dart` - Add isLoading parameter
2. `apps/mobile/sitter/lib/screens/sign_in_screen.dart` - Use isLoading
3. `apps/mobile/sitter/lib/widgets/auth_gate.dart` - Pre-load data
4. `apps/mobile/sitter/lib/widgets/home/home_header.dart` - Fix avatar loading
5. `apps/mobile/family/lib/widgets/primary_button.dart` - Add isLoading parameter
6. `apps/mobile/family/lib/screens/sign_in_screen.dart` - Use isLoading
7. `apps/mobile/family/lib/widgets/auth_gate.dart` - Pre-load data
8. `apps/mobile/family/lib/widgets/home_header.dart` - Fix avatar loading
9. All other CircleAvatar implementations showing user avatars

---

## Testing Checklist

- [ ] Sign in with email/password
- [ ] Loading spinner shows only on button
- [ ] No full-screen loading after sign-in
- [ ] Home screen loads quickly
- [ ] Avatar image loads directly without placeholder
- [ ] No flickering when avatar loads
- [ ] Default icon shows only if no avatar URL
- [ ] Sign in with Google/Apple/Facebook
- [ ] All avatar displays work correctly

---

## Priority

**High** - Improves user experience significantly
- Faster perceived load time
- Smoother avatar loading
- Better visual feedback

---

## Complexity

**Medium** - Requires changes to multiple files but straightforward implementation

---

## Risk

**Low** - Changes are isolated to UI/UX, no backend changes
