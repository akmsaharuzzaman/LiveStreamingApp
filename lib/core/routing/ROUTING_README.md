# 🎯 Modern Flutter Navigation Architecture

This document explains the new, organized navigation structure for the live streaming app using GoRouter.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Page Categories](#page-categories)
4. [Navigation Patterns](#navigation-patterns)
5. [Implementation Guide](#implementation-guide)
6. [Best Practices](#best-practices)
7. [Common Scenarios](#common-scenarios)
8. [Migration Guide](#migration-guide)

## 🎯 Overview

The new navigation structure solves the critical issue where ALL pages were wrapped with a navigation bar. Now we have:

- **Main App Pages**: WITH navigation bar (Home, Newsfeed, Chat, Profile)
- **Full-Screen Pages**: WITHOUT navigation bar (Go Live, Reels, Video Editor)
- **Auth Pages**: WITHOUT navigation bar (Login, Signup, Splash)
- **Detail/Modal Pages**: WITHOUT navigation bar, WITH back button (Chat Details, Profile Details)

## 🏗️ Architecture

```
📂 lib/core/routing/
├── 📄 app_router_new.dart          # Main router configuration
├── 📄 navigation_examples.dart     # Usage examples
└── 📄 ROUTING_README.md           # This documentation

📂 Features integrated:
├── 🏠 Main App Shell (ShellRoute)
│   ├── Home
│   ├── Newsfeed  
│   ├── Live Chat
│   └── Profile
├── 🎥 Full-Screen Pages
│   ├── Go Live
│   ├── Reels
│   └── Video Editor
├── 🔐 Auth Flow Pages
│   ├── Splash
│   ├── Welcome
│   ├── Login
│   └── Policy
└── 📄 Detail/Modal Pages
    ├── Chat Details
    ├── Leaderboard
    ├── Profile Details
    └── Edit Profile
```

## 📱 Page Categories

### 🏠 Main App Pages (WITH Navigation Bar)

These pages are wrapped in `ShellRoute` and maintain the bottom navigation bar:

```dart
// ✅ Navigation persists across these pages
- /home
- /newsfeed  
- /live-chat
- /profile
```

**Usage:**
```dart
AppNavigation.goToHome();       // Replaces current page
AppNavigation.goToNewsfeed();   // Replaces current page
AppNavigation.goToChat();       // Replaces current page
AppNavigation.goToProfile();    // Replaces current page
```

### 🎥 Full-Screen Pages (NO Navigation Bar)

These pages provide immersive, full-screen experience:

```dart
// ✅ No navigation bar, full screen
- /go-live
- /reels
- /edit-video
```

**Usage:**
```dart
AppNavigation.goLive();         // Full-screen live streaming
AppNavigation.goToReels();      // Full-screen reels view
AppNavigation.editVideo();      // Full-screen video editor
```

### 🔐 Auth Flow Pages (NO Navigation Bar)

Authentication and onboarding pages:

```dart
// ✅ No navigation bar, handled by router redirect
- /splash
- /welcome-screen
- /login
- /policy
- /profileComplete
```

**Navigation:** Handled automatically by router based on auth state.

### 📄 Detail/Modal Pages (WITH Back Button)

Pages that are pushed on top of the navigation stack:

```dart
// ✅ Can be pushed/popped, have back button
- /chat-details/:userId
- /leaderboard
- /profile-details
- /edit-profile
```

**Usage:**
```dart
// Push (adds to stack)
AppNavigation.pushChatDetails("user123");
AppNavigation.pushLeaderboard();
AppNavigation.pushProfileDetails();
AppNavigation.pushEditProfile();

// Pop (go back)
AppNavigation.goBack();
```

## 🧭 Navigation Patterns

### 1. Replace Navigation (go*)

Use for main app navigation and full-screen pages:

```dart
// ✅ CORRECT: Replace current page
AppNavigation.goToHome();
AppNavigation.goToNewsfeed();
AppNavigation.goLive();
```

### 2. Stack Navigation (push*)

Use for detail pages and modals:

```dart
// ✅ CORRECT: Add to navigation stack
AppNavigation.pushChatDetails("userId");
AppNavigation.pushLeaderboard();

// ✅ CORRECT: Return from stack
AppNavigation.goBack();
```

### 3. Conditional Navigation

```dart
// ✅ CORRECT: Navigate based on state
void onProfileTap() {
  if (user.isProfileComplete) {
    AppNavigation.goToProfile();
  } else {
    AppNavigation.pushEditProfile();
  }
}
```

## 🛠️ Implementation Guide

### 1. Setup

In your `main.dart` or `app.dart`:

```dart
class _MyAppState extends State<MyApp> {
  final LoginInfo _loginInfo = LoginInfo();
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(_loginInfo);
    // Initialize navigation helper
    AppNavigation.initialize(_appRouter.router);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _appRouter.router,
      // ... other configurations
    );
  }
}
```

### 2. Navigation Usage

```dart
// ✅ In your widgets
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => AppNavigation.pushLeaderboard(),
      child: Text('View Leaderboard'),
    );
  }
}
```

### 3. Bottom Navigation Integration

```dart
// ✅ In your ScaffoldWithNavBar
BottomNavigationBar(
  onTap: (index) {
    switch (index) {
      case 0: AppNavigation.goToHome(); break;
      case 1: AppNavigation.goToNewsfeed(); break;
      case 2: AppNavigation.goLive(); break;  // Full screen
      case 3: AppNavigation.goToChat(); break;
      case 4: AppNavigation.goToProfile(); break;
    }
  },
  // ... items
)
```

## ✅ Best Practices

### DO ✅

```dart
// ✅ Use appropriate navigation method
AppNavigation.goToHome();                    // Main app pages
AppNavigation.goLive();                      // Full screen pages
AppNavigation.pushChatDetails("userId");     // Detail pages

// ✅ Check back navigation
if (AppNavigation.canGoBack()) {
  AppNavigation.goBack();
} else {
  AppNavigation.goToHome(); // Fallback
}

// ✅ Use consistent naming
AppNavigation.goToNewsfeed();    // go* for main navigation
AppNavigation.pushLeaderboard(); // push* for stack navigation
```

### DON'T ❌

```dart
// ❌ Don't use context.go directly
context.go('/home');

// ❌ Don't mix navigation methods
Navigator.push(context, MaterialPageRoute(...));

// ❌ Don't navigate without checking state
AppNavigation.goBack(); // Might not work if no history
```

## 🎯 Common Scenarios

### 1. User Taps Bottom Navigation

```dart
// ✅ Main app navigation (stays in shell)
void onBottomNavTap(int index) {
  switch (index) {
    case 0: AppNavigation.goToHome(); break;
    case 1: AppNavigation.goToNewsfeed(); break;
    case 2: AppNavigation.goLive(); break;      // Exits shell
    case 3: AppNavigation.goToChat(); break;
    case 4: AppNavigation.goToProfile(); break;
  }
}
```

### 2. User Wants to View Details

```dart
// ✅ Push detail page (can go back)
void onChatItemTap(String userId) {
  AppNavigation.pushChatDetails(userId);
}

void onLeaderboardTap() {
  AppNavigation.pushLeaderboard();
}
```

### 3. Full-Screen Experience

```dart
// ✅ Full-screen pages (no navigation bar)
void onGoLiveTap() {
  AppNavigation.goLive();
}

void onReelsTap() {
  AppNavigation.goToReels();
}
```

### 4. Going Back

```dart
// ✅ Safe back navigation
void onBackPressed() {
  if (AppNavigation.canGoBack()) {
    AppNavigation.goBack();
  } else {
    // Handle root navigation
    AppNavigation.goToHome();
  }
}
```

## 🔄 Migration Guide

### From Old Navigation:

```dart
// ❌ OLD WAY
context.go('/home');
context.push('/chat-details');
Navigator.pop(context);
```

### To New Navigation:

```dart
// ✅ NEW WAY
AppNavigation.goToHome();
AppNavigation.pushChatDetails("userId");
AppNavigation.goBack();
```

### Update Bottom Navigation:

```dart
// ❌ OLD: Everything in shell
ShellRoute(
  routes: [
    GoRoute(path: '/home', ...),
    GoRoute(path: '/go-live', ...),  // Should be full-screen
    GoRoute(path: '/chat-details', ...),  // Should be pushable
  ],
)

// ✅ NEW: Separated by category
ShellRoute(
  routes: [
    GoRoute(path: '/home', ...),      // Main app pages only
    GoRoute(path: '/newsfeed', ...),
  ],
),
GoRoute(path: '/go-live', ...),      // Full-screen pages
GoRoute(path: '/chat-details', ...), // Detail pages
```

## 🚀 Advanced Features

### 1. Dynamic Navigation

```dart
// ✅ Navigate based on user state
void smartNavigate(User user) {
  if (!user.isLoggedIn) {
    // Handled by router redirect
    return;
  }
  
  if (!user.isProfileComplete) {
    // Handled by router redirect
    return;
  }
  
  AppNavigation.goToHome();
}
```

### 2. Deep Linking

```dart
// ✅ Handle deep links
void handleDeepLink(String path) {
  if (path.startsWith('/chat-details/')) {
    final userId = path.split('/').last;
    AppNavigation.pushChatDetails(userId);
  }
}
```

### 3. Navigation State

```dart
// ✅ Get current navigation state
String currentLocation = AppNavigation.currentLocation;
bool canGoBack = AppNavigation.canGoBack();
```

## 🎨 UI/UX Benefits

### Before (Problems):
- ❌ Login screen had navigation bar
- ❌ Live streaming had navigation bar
- ❌ Modal pages couldn't be dismissed
- ❌ No proper back navigation

### After (Solutions):
- ✅ Clean auth flow without navigation bar
- ✅ Immersive full-screen experiences
- ✅ Proper modal/detail navigation
- ✅ Consistent back button behavior

## 🔧 Troubleshooting

### Common Issues:

1. **Navigation bar shows on full-screen pages**
   - Check if page is in ShellRoute
   - Move to direct routes for full-screen

2. **Can't go back from detail pages**
   - Use `push*` methods instead of `go*`
   - Check if `canGoBack()` returns true

3. **Auth redirect not working**
   - Verify LoginInfo is properly connected
   - Check redirect logic in router

4. **Import errors**
   - Ensure `AppNavigation.initialize()` is called
   - Check import paths

## 📝 Summary

The new navigation structure provides:

- **Organized routing** by page category
- **Proper navigation bar behavior** (show/hide when appropriate)
- **Clean back navigation** for detail pages
- **Immersive full-screen experiences**
- **Consistent navigation patterns**
- **Easy-to-use helper methods**

This creates a much better user experience and maintainable code structure.
