import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:streaming_djlive/features/auth/presentation/pages/user_login.dart';
import 'package:streaming_djlive/features/auth/presentation/pages/user_policy.dart';
import 'package:streaming_djlive/features/chat/presentation/pages/chatpage.dart';
import 'package:streaming_djlive/features/home/presentation/pages/homepage.dart';
import 'package:streaming_djlive/features/leaderboard/presentation/pages/leaderboard.dart';
import 'package:streaming_djlive/features/live-streaming/presentation/pages/golive_screen.dart';
import 'package:streaming_djlive/features/newsfeed/presentation/pages/newsfeed.dart';
import 'package:streaming_djlive/features/profile/presentation/pages/profile_main.dart';
import 'package:streaming_djlive/features/reels/presentation/pages/reels.dart';

import '../../features/auth/presentation/pages/dispatch_screen.dart';
import '../../features/auth/presentation/pages/profile_signup_complete.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/welcome_screen.dart';
import '../../features/chat/presentation/pages/chatroom.dart';
import '../../features/core/presentation/widgets/scaffold_with_appbar.dart';
import '../../features/core/services/login_provider.dart';
import '../../features/profile/presentation/pages/edit_profile.dart';
import '../../features/profile/presentation/pages/profile_details.dart';
import '../../features/reels/presentation/pages/video_editor_screen.dart';


/// 🎯 CLEAN ROUTER ORGANIZATION
/// 
/// This router separates pages into logical groups:
/// 1. Main App Pages (WITH navigation bar)
/// 2. Full Screen Pages (WITHOUT navigation bar) 
/// 3. Auth Flow Pages (WITHOUT navigation bar)
/// 4. Modal/Detail Pages (WITHOUT navigation bar, with back button)

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
        builder: (context, state) => const GoliveScreen(),
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
        builder: (context, state) => ChatRoom(
          userId: state.pathParameters["userId"] ?? "",
        ),
      ),
      GoRoute(
        name: "leaderboard", 
        path: "/leaderboard",
        builder: (context, state) => LeaderBoardScreen(),
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
      
      // ==========================================
      // 🎮 NESTED ROUTES FOR COMPLEX FLOWS
      // ==========================================
      // Example: Stream details with nested pages
      GoRoute(
        name: "stream-details",
        path: "/stream/:streamId",
        builder: (context, state) {
          final streamId = state.pathParameters["streamId"] ?? "";
          return StreamDetailsPage(streamId: streamId);
        },
        routes: [
          // Nested route for stream settings
          GoRoute(
            name: "stream-settings",
            path: "/settings",
            builder: (context, state) {
              final streamId = state.pathParameters["streamId"] ?? "";
              return StreamSettingsPage(streamId: streamId);
            },
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) async {
      if (kDebugMode) {
        Logger().i("Matched Location: ${state.matchedLocation}");
      }
      
      final bool loggedIn = _loginInfo.loggedIn;
      final String location = state.matchedLocation;
      
      // Public routes (no auth required)
      final publicRoutes = [
        '/splash',
        '/welcome-screen', 
        '/login',
        '/policy',
      ];
      
      // Check if current route is public
      final isPublicRoute = publicRoutes.contains(location);
      
      // If not logged in and trying to access protected route
      if (!loggedIn && !isPublicRoute) {
        return '/welcome-screen';
      }
      
      // If logged in and on auth pages, redirect to home
      if (loggedIn && isPublicRoute && location != '/splash') {
        return '/home';
      }
      
      // No redirect needed
      return null;
    },
  );
}

/// 🎯 Navigation Helper Methods
class AppNavigation {
  static final GoRouter _router = AppRouter(LoginInfo()).router;
  
  /// Navigate to main app pages (with navbar)
  static void goToHome() => _router.goNamed('home');
  static void goToNewsfeed() => _router.goNamed('newsfeed');
  static void goToChat() => _router.goNamed('live-chat');
  static void goToProfile() => _router.goNamed('profile');
  
  /// Navigate to full screen pages (no navbar)
  static void goLive() => _router.goNamed('go-live');
  static void goToReels() => _router.goNamed('reels');
  static void editVideo() => _router.goNamed('edit-video');
  
  /// Navigate to detail pages (with back button)
  static void goToChatDetails(String userId) {
    _router.goNamed('chat-details', pathParameters: {'userId': userId});
  }
  
  static void goToLeaderboard() => _router.goNamed('leaderboard');
  static void goToProfileDetails() => _router.goNamed('profile-details');
  static void goToEditProfile() => _router.goNamed('edit-profile');
  
  /// Navigate to stream details
  static void goToStreamDetails(String streamId) {
    _router.goNamed('stream-details', pathParameters: {'streamId': streamId});
  }
  
  /// Navigate back
  static void goBack() => _router.pop();
  
  /// Check if can go back
  static bool canGoBack() => _router.canPop();
}

/// Example placeholder pages for demonstration
class StreamDetailsPage extends StatelessWidget {
  final String streamId;
  
  const StreamDetailsPage({Key? key, required this.streamId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stream Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => AppNavigation.goBack(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Stream ID: $streamId'),
            ElevatedButton(
              onPressed: () => AppNavigation.goToHome(),
              child: Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class StreamSettingsPage extends StatelessWidget {
  final String streamId;
  
  const StreamSettingsPage({Key? key, required this.streamId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stream Settings'),
      ),
      body: Center(
        child: Text('Settings for Stream: $streamId'),
      ),
    );
  }
}
