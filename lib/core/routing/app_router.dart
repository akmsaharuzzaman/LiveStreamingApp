import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import your pages
import '../../features/home/presentation/pages/homepage.dart';
import '../../features/live-streaming/presentation/pages/ready_for_live_screen.dart';
import '../../features/newsfeed/presentation/pages/newsfeed.dart';
import '../../features/live-streaming/presentation/pages/golive_screen.dart';
import '../../features/chat/presentation/pages/chatpage.dart';
import '../../features/profile/presentation/pages/profile_main.dart';
import '../../features/reels/presentation/pages/reels.dart';
import '../../features/leaderboard/presentation/pages/leaderboard.dart';

// Auth pages
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/welcome_screen.dart';
import '../../features/auth/presentation/pages/user_login.dart';
import '../../features/auth/presentation/pages/user_policy.dart';
import '../../features/auth/presentation/pages/profile_signup_complete.dart';
import '../../features/auth/presentation/pages/dispatch_screen.dart';

// Detail/Modal pages
import '../../features/chat/presentation/pages/chatroom.dart';
import '../../features/profile/presentation/pages/profile_details.dart';
import '../../features/profile/presentation/pages/edit_profile.dart';
import '../../features/reels/presentation/pages/video_editor_screen.dart';

// Auth
import '../../features/auth/presentation/bloc/log_in_bloc/log_in_bloc.dart';
import '../../features/auth/data/repositories/log_in_repository.dart';
import '../../features/core/services/login_provider.dart';

// Scaffold with nav bar
import '../../features/core/presentation/widgets/scaffold_with_appbar.dart';

/// 🎯 CLEAN ROUTER ORGANIZATION
///
/// This router separates pages into logical groups:
/// 1. Main App Pages (WITH navigation bar) - ShellRoute
/// 2. Full Screen Pages (WITHOUT navigation bar) - Direct routes
/// 3. Auth Flow Pages (WITHOUT navigation bar) - Direct routes
/// 4. Modal/Detail Pages (WITHOUT navigation bar, with back button) - Direct routes

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

class AppRouter {
  final LoginInfo _loginInfo;

  AppRouter(this._loginInfo);

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/welcome-screen',
    routes: <RouteBase>[
      // ==========================================
      // 🏠 MAIN APP SHELL (WITH NAVIGATION BAR)
      // ==========================================
      // These are the primary app pages that need persistent navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            name: "home",
            path: "/home",
            builder: (context, state) => HomePageScreen(),
          ),
          GoRoute(
            name: "newsfeed",
            path: "/newsfeed",
            builder: (context, state) => NewsFeedScreen(),
          ),
          GoRoute(
            name: "live-chat",
            path: "/live-chat",
            builder: (context, state) => ChatPageScreen(),
          ),
          GoRoute(
            name: "profile",
            path: "/profile",
            builder: (context, state) => MainProfileScreen(),
          ),
        ],
      ),

      // ==========================================
      // 🎥 FULL SCREEN PAGES (NO NAVIGATION BAR)
      // ==========================================
      // These pages need full screen experience
      GoRoute(
        name: "go-live",
        path: "/go-live",
        builder: (context, state) {
          final roomId = state.uri.queryParameters["roomId"];
          return GoliveScreen(roomId: roomId ?? "");
        },
      ),
      GoRoute(
        name: "reels",
        path: "/reels",
        builder: (context, state) => const ReelsScreen(),
      ),
      GoRoute(
        name: "edit-video",
        path: "/edit-video",
        builder: (context, state) => VideoEditorScreen(),
      ),

      // ==========================================
      // 🔐 AUTH FLOW PAGES (NO NAVIGATION BAR)
      // ==========================================
      // Authentication and onboarding flow
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome-screen',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/policy',
        builder: (context, state) => const UserPolicyScreen(),
      ),
      GoRoute(
        name: "profileComplete",
        path: "/profileComplete",
        builder: (context, state) => ProfileSignupComplete(),
      ),
      GoRoute(
        path: DispatchScreen.route,
        builder: (context, state) => DispatchScreen(),
      ),

      // ==========================================
      // 📄 DETAIL/MODAL PAGES (WITH BACK BUTTON)
      // ==========================================
      // These pages are pushed on top and need back navigation
      GoRoute(
        name: "chat-details",
        path: "/chat-details/:userId",
        builder: (context, state) =>
            ChatRoom(userId: state.pathParameters["userId"] ?? ""),
      ),
      GoRoute(
        name: "leaderboard",
        path: "/leaderboard",
        builder: (context, state) => LeaderBoardScreen(),
      ),
      GoRoute(
        name: "ready-to-go-live",
        path: "/ready-to-go-live",
        builder: (context, state) => ReadyForLiveScreen(),
      ),
      GoRoute(
        name: "profile-details",
        path: "/profile-details",
        builder: (context, state) => ProfileDetailsScreen(),
      ),
      GoRoute(
        name: "edit-profile",
        path: "/edit-profile",
        builder: (context, state) => EditProfileScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) async {
      if (kDebugMode) {
        debugPrint("Matched Location: ${state.matchedLocation}");
      }

      final bool loggedIn = _loginInfo.loggedIn;
      final String location = state.matchedLocation;

      // Public routes (no auth required)
      final publicRoutes = ['/splash', '/welcome-screen', '/login', '/policy'];

      // Check if current route is public
      final isPublicRoute = publicRoutes.contains(location);

      // If not logged in and trying to access protected route
      if (!loggedIn && !isPublicRoute) {
        if (kDebugMode) {
          debugPrint("Not logged in, redirecting to welcome");
        }
        return '/welcome-screen';
      }

      // If logged in, check profile completion
      if (loggedIn) {
        try {
          final user = context.read<LogInBloc>().state.userInfoProfile;
          final isComplete = await LogInRepository().isProfileComplete(user);

          if (!isComplete && location != "/profileComplete") {
            return "/profileComplete";
          }

          // If profile is complete and on auth pages, redirect to home
          if (isComplete && isPublicRoute && location != '/splash') {
            return '/home';
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint("Error checking profile completion: $e");
          }
        }
      }

      // No redirect needed
      return null;
    },
    refreshListenable: _loginInfo,
  );
}

/// 🎯 Navigation Helper Methods
class AppNavigation {
  static GoRouter? _router;

  static void initialize(GoRouter router) {
    _router = router;
  }

  static GoRouter get router {
    if (_router == null) {
      throw Exception(
        'AppNavigation not initialized. Call AppNavigation.initialize() first.',
      );
    }
    return _router!;
  }

  /// Navigate to main app pages (with navbar)
  static void goToHome() => router.goNamed('home');
  static void goToNewsfeed() => router.goNamed('newsfeed');
  static void goToChat() => router.goNamed('live-chat');
  static void goToProfile() => router.goNamed('profile');

  /// Navigate to full screen pages (no navbar)
  static void goLive() => router.goNamed('go-live');
  static void goToReels() => router.goNamed('reels');
  static void editVideo() => router.goNamed('edit-video');

  /// Navigate to detail pages (with back button)
  static void goToChatDetails(String userId) {
    router.goNamed('chat-details', pathParameters: {'userId': userId});
  }

  static void goToLeaderboard() => router.goNamed('leaderboard');
  static void goToProfileDetails() => router.goNamed('profile-details');
  static void goToEditProfile() => router.goNamed('edit-profile');

  /// Push navigation (adds to stack instead of replacing)
  static void pushChatDetails(String userId) {
    router.pushNamed('chat-details', pathParameters: {'userId': userId});
  }

  static void pushLeaderboard() => router.pushNamed('leaderboard');
  static void pushProfileDetails() => router.pushNamed('profile-details');
  static void pushEditProfile() => router.pushNamed('edit-profile');

  /// Navigate back
  static void goBack() => router.pop();

  /// Check if can go back
  static bool canGoBack() => router.canPop();

  /// Get current location
  static String get currentLocation =>
      router.routerDelegate.currentConfiguration.fullPath;
}

/// 📱 Sample usage patterns for different navigation scenarios:

/*
// ✅ CORRECT: Navigate to main app page (stays in nav bar shell)
AppNavigation.goToHome();
AppNavigation.goToNewsfeed();

// ✅ CORRECT: Navigate to full screen (exits nav bar shell)
AppNavigation.goLive();
AppNavigation.goToReels();

// ✅ CORRECT: Push detail page (shows back button, no nav bar)
AppNavigation.pushChatDetails("user123");
AppNavigation.pushLeaderboard();

// ✅ CORRECT: Navigate back
AppNavigation.goBack();

// ✅ CORRECT: Check if back navigation is possible
if (AppNavigation.canGoBack()) {
  AppNavigation.goBack();
} else {
  AppNavigation.goToHome(); // Fallback
}

// ✅ CORRECT: Navigation from within widgets
ElevatedButton(
  onPressed: () => AppNavigation.pushLeaderboard(),
  child: Text('View Leaderboard'),
)

// ✅ CORRECT: Conditional navigation
void onProfileTap() {
  if (user.isProfileComplete) {
    AppNavigation.goToProfile();
  } else {
    AppNavigation.pushEditProfile();
  }
}
*/
