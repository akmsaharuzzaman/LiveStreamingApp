import 'package:dlstarlive/features/chat/presentation/pages/chat_page.dart';
import 'package:dlstarlive/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:dlstarlive/features/chat/presentation/pages/chat_settings.dart';
import 'package:dlstarlive/features/live/presentation/pages/golive_screen.dart';
import 'package:dlstarlive/features/live/presentation/pages/live_page.dart';
import 'package:dlstarlive/features/live/presentation/pages/live_summary_screen.dart';
import 'package:dlstarlive/features/profile/presentation/pages/view_user_profile.dart';
import 'package:dlstarlive/features/profile/presentation/pages/friends_list_page.dart';
import 'package:dlstarlive/features/reels/presentation/pages/reels.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/presentation/pages/main_navigation_page.dart';
import '../features/newsfeed/presentation/pages/newsfeed.dart';
import '../features/profile/presentation/pages/store_page.dart';
import '../features/reels/presentation/pages/video_editor_screen.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/auth/presentation/pages/splash_screen.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/profile/presentation/pages/profile_completion_page.dart';
import '../features/profile/presentation/pages/profile_update_page.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String settings = '/settings';
  static const String editVideo = '/edit-video';
  static const String profileCompletion = '/profile-completion';
  static const String profileUpdate = '/profile-update';
  static const String viewProfile = '/view-profile';
  static const String reels = '/reels';
  static const String live = '/live';
  static const String onGoingLive = '/on-going-live';
  static const String liveSummary = '/live-summary';
  static const String chatDetail = '/chat-details';
  static const String chats = '/chats';
  static const String friendsList = '/friends-list';
  static const String chatSettings = '/chat-settings';
  static const String newsfeed = '/newsfeed';
  static const String store = '/store';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const MainNavigationPage(),
    ),
    GoRoute(
      path: AppRoutes.newsfeed,
      name: 'newsfeed',
      builder: (context, state) => const NewsfeedPage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.editVideo,
      name: 'editVideo',
      builder: (context, state) => const VideoEditorScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileCompletion,
      name: 'profileCompletion',
      builder: (context, state) => const ProfileCompletionPage(),
    ),
    GoRoute(
      path: AppRoutes.profileUpdate,
      name: 'profileUpdate',
      builder: (context, state) => const ProfileUpdatePage(),
    ),
    GoRoute(
      path: AppRoutes.chatSettings,
      name: 'chatSettings',
      builder: (context, state) => const InboxSettings(),
    ),
    GoRoute(
      path: AppRoutes.viewProfile,
      name: 'viewProfile',
      builder: (context, state) {
        final userId = state.uri.queryParameters['userId'] ?? '';
        return ViewUserProfile(userId: userId);
      },
    ),
    GoRoute(
      path: AppRoutes.reels,
      name: 'reels',
      builder: (context, state) => const ReelsScreen(),
    ),
    GoRoute(
      path: AppRoutes.live,
      name: 'live',
      builder: (context, state) => const LivePage(),
    ),
    GoRoute(
      path: AppRoutes.chats,
      name: 'chats',
      builder: (context, state) => const ChatPage(),
    ),
    GoRoute(
      path: AppRoutes.onGoingLive,
      name: 'onGoingLive',
      builder: (context, state) {
        final roomId = state.uri.queryParameters['roomId'] ?? '';
        final hostName = state.uri.queryParameters['hostName'] ?? '';
        final hostUserId = state.uri.queryParameters['hostUserId'] ?? '';
        final hostAvatar = state.uri.queryParameters['hostAvatar'] ?? '';
        final existingViewers =
            (state.extra as Map<String, dynamic>?)?['existingViewers']
                as List<HostDetails>? ??
            [];
        final hostCoins = (state.extra as Map<String, dynamic>?)?['hostCoins'] as int? ?? 0;
        return GoliveScreen(
          roomId: roomId,
          hostName: hostName,
          hostUserId: hostUserId,
          hostAvatar: hostAvatar,
          existingViewers: existingViewers,
          hostCoins: hostCoins,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.liveSummary,
      name: 'liveSummary',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return LiveSummaryScreen(
          userName: extra?['userName'] ?? "User",
          userId: extra?['userId'] ?? "123456",
          earnedPoints: extra?['earnedPoints'] ?? 0,
          newFollowers: extra?['newFollowers'] ?? 0,
          totalDuration: extra?['totalDuration'] ?? "0:0:0",
          userAvatar: extra?['userAvatar'],
        );
      },
    ),
    GoRoute(
      path: '${AppRoutes.chatDetail}/:userId',
      name: 'chatDetail',
      builder: (context, state) {
        final userId = state.pathParameters['userId'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        return ChatDetailPage(userId: userId, userInfo: extra);
      },
    ),
    GoRoute(
      path: '${AppRoutes.friendsList}/:userId',
      name: 'friendsList',
      builder: (context, state) {
        final String? userId = state.pathParameters['userId'];
        final title = state.uri.queryParameters['title'] ?? 'Friends';
        return FriendsListPage(userId: userId, title: title);
      },
    ),
    GoRoute(
      path: AppRoutes.store,
      name: 'store',
      builder: (context, state) => const StorePage(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The page you\'re looking for doesn\'t exist.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
