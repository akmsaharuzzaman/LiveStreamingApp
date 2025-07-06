# 🔄 Navigation Migration Guide

## Quick Reference: Old vs New Navigation

### 🚫 OLD WAY (What to Replace)

```dart
// ❌ Direct GoRouter usage
context.go('/home');
context.push('/chat-details/123');
GoRouter.of(context).pop();

// ❌ Manual navigation
Navigator.push(context, MaterialPageRoute(...));
Navigator.pop(context);

// ❌ String-based routing
context.pushNamed('profile-details');
```

### ✅ NEW WAY (What to Use Instead)

```dart
// ✅ Clean helper methods
AppNavigation.goToHome();
AppNavigation.pushChatDetails("123");
AppNavigation.goBack();

// ✅ Type-safe navigation
AppNavigation.goToProfile();
AppNavigation.pushLeaderboard();
```

## 🔧 Step-by-Step Migration

### 1. Replace Direct GoRouter Calls

Find and replace these patterns in your codebase:

```dart
// OLD: context.go('/home')
// NEW: AppNavigation.goToHome()

// OLD: context.go('/newsfeed')  
// NEW: AppNavigation.goToNewsfeed()

// OLD: context.go('/live-chat')
// NEW: AppNavigation.goToChat()

// OLD: context.go('/profile')
// NEW: AppNavigation.goToProfile()
```

### 2. Update Full-Screen Navigation

```dart
// OLD: context.push('/go-live')
// NEW: AppNavigation.goLive()

// OLD: context.push('/reels')
// NEW: AppNavigation.goToReels()

// OLD: context.push('/edit-video')
// NEW: AppNavigation.editVideo()
```

### 3. Fix Detail Page Navigation

```dart
// OLD: context.push('/chat-details/$userId')
// NEW: AppNavigation.pushChatDetails(userId)

// OLD: context.push('/leaderboard')
// NEW: AppNavigation.pushLeaderboard()

// OLD: context.push('/profile-details')
// NEW: AppNavigation.pushProfileDetails()

// OLD: context.push('/edit-profile')
// NEW: AppNavigation.pushEditProfile()
```

### 4. Update Back Navigation

```dart
// OLD: Navigator.pop(context)
// NEW: AppNavigation.goBack()

// OLD: GoRouter.of(context).pop()
// NEW: AppNavigation.goBack()

// OLD: if (Navigator.canPop(context))
// NEW: if (AppNavigation.canGoBack())
```

## 🎯 Common Patterns to Update

### Bottom Navigation Bar

```dart
// OLD:
BottomNavigationBar(
  onTap: (index) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/newsfeed'); break;
      // ...
    }
  },
)

// NEW:
BottomNavigationBar(
  onTap: (index) {
    switch (index) {
      case 0: AppNavigation.goToHome(); break;
      case 1: AppNavigation.goToNewsfeed(); break;
      case 2: AppNavigation.goLive(); break;
      case 3: AppNavigation.goToChat(); break;
      case 4: AppNavigation.goToProfile(); break;
    }
  },
)
```

### List Item Navigation

```dart
// OLD:
ListTile(
  onTap: () => context.push('/chat-details/$userId'),
)

// NEW:
ListTile(
  onTap: () => AppNavigation.pushChatDetails(userId),
)
```

### Button Navigation

```dart
// OLD:
ElevatedButton(
  onPressed: () => context.go('/profile-details'),
  child: Text('View Profile'),
)

// NEW:
ElevatedButton(
  onPressed: () => AppNavigation.pushProfileDetails(),
  child: Text('View Profile'),
)
```

### Conditional Navigation

```dart
// OLD:
if (user.isComplete) {
  context.go('/profile');
} else {
  context.push('/edit-profile');
}

// NEW:
if (user.isComplete) {
  AppNavigation.goToProfile();
} else {
  AppNavigation.pushEditProfile();
}
```

## 🔍 Find and Replace Patterns

Use these regex patterns in your IDE to quickly find and replace:

### Search Patterns:
```regex
context\.go\(['"]/([^'"]+)['"]\)
context\.push\(['"]/([^'"]+)['"]\)
Navigator\.pop\(context\)
GoRouter\.of\(context\)\.pop\(\)
```

### Replace With:
```dart
AppNavigation.goTo... // (choose appropriate method)
AppNavigation.push... // (choose appropriate method)  
AppNavigation.goBack()
AppNavigation.goBack()
```

## ⚠️ Important Notes

### 1. Don't Mix Navigation Methods
```dart
// ❌ DON'T mix old and new
context.go('/home');
AppNavigation.pushChatDetails("123");

// ✅ DO use consistently
AppNavigation.goToHome();
AppNavigation.pushChatDetails("123");
```

### 2. Use Correct Method for Page Type
```dart
// ✅ Main app pages (stay in nav shell)
AppNavigation.goToHome();
AppNavigation.goToNewsfeed();

// ✅ Full-screen pages (exit nav shell)
AppNavigation.goLive();
AppNavigation.goToReels();

// ✅ Detail pages (can be dismissed)
AppNavigation.pushChatDetails("123");
AppNavigation.pushLeaderboard();
```

### 3. Safe Back Navigation
```dart
// ✅ Always check if back navigation is possible
if (AppNavigation.canGoBack()) {
  AppNavigation.goBack();
} else {
  AppNavigation.goToHome(); // Fallback
}
```

## 🧪 Testing Your Migration

### 1. Navigation Flow Test
- [ ] Main app navigation works (bottom nav)
- [ ] Full-screen pages don't show navigation bar
- [ ] Detail pages show back button
- [ ] Back navigation works properly
- [ ] Auth flow works without navigation bar

### 2. Build Test
```bash
flutter analyze
flutter build apk --debug
```

### 3. Runtime Test
- [ ] No navigation errors in debug console
- [ ] Smooth transitions between pages
- [ ] Correct UI for each page type
- [ ] No unexpected navigation bar appearances

## 🎉 Migration Complete!

Once you've updated all navigation calls to use the new `AppNavigation` helper methods, your app will have:

- ✅ Consistent navigation patterns
- ✅ Proper navigation bar behavior
- ✅ Type-safe navigation
- ✅ Better user experience
- ✅ Easier maintenance

## 🆘 Troubleshooting

### Common Issues:

1. **"AppNavigation not initialized"**
   - Ensure `AppNavigation.initialize()` is called in `main.dart` or `app.dart`

2. **Navigation bar shows on full-screen pages**
   - Check that the page uses `AppNavigation.goLive()` or similar full-screen method

3. **Can't go back from detail pages**
   - Use `AppNavigation.push*()` methods instead of `AppNavigation.go*()`

4. **Auth redirect not working**
   - Verify that the new router is properly integrated in your app

Need help? Check the `ROUTING_README.md` for comprehensive documentation!
