import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:streaming_djlive/features/auth/data/repositories/log_in_repository.dart';
import 'package:streaming_djlive/features/auth/presentation/bloc/log_in_bloc/log_in_bloc.dart';
import 'package:streaming_djlive/features/auth/presentation/pages/user_login.dart';
import 'package:streaming_djlive/features/auth/presentation/pages/user_policy.dart';
import 'package:streaming_djlive/features/chat/presentation/pages/chatpage.dart';
import 'package:streaming_djlive/features/home/presentation/pages/homepage.dart';
import 'package:streaming_djlive/features/leaderboard/presentation/pages/leaderboard.dart';
import 'package:streaming_djlive/features/newsfeed/presentation/pages/newsfeed.dart';
import 'package:streaming_djlive/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:streaming_djlive/features/profile/presentation/pages/profile_main.dart';
import 'package:streaming_djlive/features/reels/presentation/pages/reels.dart';

import '../features/auth/presentation/pages/dispatch_screen.dart';
import '../features/auth/presentation/pages/profile_signup_complete.dart';
import '../features/auth/presentation/pages/splash_screen.dart';
import '../features/auth/presentation/pages/welcome_screen.dart';
import '../features/chat/data/models/user_model.dart';
import '../features/chat/presentation/pages/chatroom.dart';
import '../features/core/presentation/widgets/scaffold_with_appbar.dart';
import '../features/core/services/login_provider.dart';
import '../features/core/services/navbar_provider.dart';
import '../features/profile/presentation/pages/edit_profile.dart';
import '../features/profile/presentation/pages/profile_details.dart';
import '../features/reels/presentation/pages/video_editor_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LoginInfo _loginInfo = LoginInfo();

  @override
  void initState() {
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    _loginInfo.autoLogin();
    return ChangeNotifierProvider.value(
      value: _loginInfo,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) {
          return MultiBlocProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => NavBarProvider()),
              BlocProvider(
                  create: (context) =>
                      LogInBloc(logInRepository: LogInRepository())),
              BlocProvider(create: (context) => ProfileBloc()),
            ],
            child: MaterialApp.router(
              title: 'DLStar',
              routerConfig: _router,
              debugShowCheckedModeBanner: false,
              locale: const Locale('en'),
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color.fromARGB(255, 15, 15, 15),
                ),
                useMaterial3: true,
              ),
            ),
          );
        },
      ),
    );
  }

  List<User> allUsers = [
    User(id: 0, name: 'You', avatar: 'assets/images/new_images/person.png'),
    User(
        id: 1, name: 'Addison', avatar: 'assets/images/new_images/profile.png'),
    User(id: 2, name: 'Angel', avatar: 'assets/images/new_images/person.png'),
    User(id: 3, name: 'Deanna', avatar: 'assets/images/new_images/profile.png'),
    User(id: 4, name: 'Json', avatar: 'assets/images/new_images/profile.png'),
    User(id: 5, name: 'Judd', avatar: 'assets/images/new_images/person.png'),
    User(id: 6, name: 'Leslie', avatar: 'assets/images/new_images/person.png'),
    User(id: 7, name: 'Nathan', avatar: 'assets/images/new_images/profile.png'),
    User(
        id: 8, name: 'Stanley', avatar: 'assets/images/new_images/profile.png'),
    User(
      id: 9,
      name: 'Shahadat Vai Astha',
      avatar: 'assets/images/new_images/person.png',
    ),
  ];

  User getUserById(int userId) {
    try {
      return allUsers.firstWhere((user) => user.id == userId);
    } catch (e) {
      return User.empty();
    }
  }

  late final GoRouter _router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/welcome-screen',
    routes: <RouteBase>[
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
            name: "live",
            path: "/live",
            builder: (context, state) => const HomePageScreen(),
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
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome-screen',
        builder: (BuildContext context, GoRouterState state) =>
            const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/policy',
        builder: (BuildContext context, GoRouterState state) =>
            const UserPolicyScreen(),
      ),
      GoRoute(
        name: "reels",
        path: "/reels",
        builder: (context, state) => const ReelsScreen(),
      ),
      GoRoute(
        name: "profileComplete",
        path: "/profileComplete",
        builder: (context, state) {
          return ProfileSignupComplete();
        },
      ),
      GoRoute(
        path: DispatchScreen.route,
        builder: (BuildContext context, GoRouterState state) {
          return DispatchScreen();
        },
      ),
      GoRoute(
        name: "chat-details",
        path: "/chat-details/:userId",
        builder: (BuildContext context, GoRouterState state) => ChatRoom(
          userId: state.pathParameters["userId"] ?? "",
        ),
      ),
      GoRoute(
        name: "leaderboard",
        path: "/leaderboard",
        builder: (context, state) {
          return LeaderBoardScreen();
        },
      ),
      GoRoute(
        name: "profile-details",
        path: "/profile-details",
        builder: (context, state) {
          return ProfileDetailsScreen();
        },
      ),
      GoRoute(
        name: "edit-profile",
        path: "/edit-profile",
        builder: (context, state) {
          return EditProfileScreen();
        },
      ),
      GoRoute(
        name: "edit-video",
        path: "/edit-video",
        builder: (context, state) {
          return VideoEditorScreen();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) async {
      if (kDebugMode) {
        Logger().i("Matched Location: ${state.matchedLocation}");
      }
      final bool loggedIn = _loginInfo.loggedIn;
      final bool loggingIn = state.matchedLocation == '/welcome-screen' ||
          state.matchedLocation == "/home" ||
          state.matchedLocation == "/splash" ||
          state.matchedLocation == "/newsfeed" ||
          state.matchedLocation == "/live" ||
          state.matchedLocation == "/live-chat" ||
          state.matchedLocation == "/profile" ||
          state.matchedLocation == "/reels" ||
          state.matchedLocation == "/policy" ||
          state.matchedLocation == "/login" ||
          state.matchedLocation == "/profileComplete" ||
          state.matchedLocation == "/leaderboard" ||
          state.matchedLocation == "/chat-details" ||
          state.matchedLocation == "/profile-details" ||
          state.matchedLocation == "/edit-profile" ||
          state.matchedLocation == "/edit-video" ||
          state.matchedLocation == "/inbox" ||
          state.matchedLocation == "/settings" ||
          state.matchedLocation == "/one-to-one-chat" ||
          state.matchedLocation == "/review" ||
          state.matchedLocation == "/add-review" ||
          state.matchedLocation == "/accounts";

      if (!loggedIn) {
        if (kDebugMode) {
          Logger().i("Not Logged in");
          Logger().i(state.matchedLocation);
        }
        if (state.matchedLocation == "/splash") {
          return '/splash';
        }
        if (state.matchedLocation == "/login") {
          return '/login';
        }
        if (state.matchedLocation.contains("/welcome-screen")) {
          return state.matchedLocation;
        }

        return null;
      }

      if (loggedIn) {
        final user = context.read<LogInBloc>().state.userInfoProfile;
        final isComplete = await LogInRepository().isProfileComplete(user);

        if (kDebugMode) {
          Logger().i("Matched Location: ${state.matchedLocation}");
        }

        if (!isComplete) {
          return "/profileComplete";
        }

        if (state.matchedLocation == "/home") {
          return "/home";
        }
        if (state.matchedLocation == "/profileComplete") {
          return "/profileComplete";
        }
        if (state.matchedLocation == "/profile") {
          return '/profile';
        }
        // if (state.matchedLocation.contains("/newsfeed")) {
        //   return state.matchedLocation;
        // }
        if (state.matchedLocation == "/newsfeed") {
          return "/newsfeed";
        }
        if (state.matchedLocation == "/live-chat") {
          return "/live-chat";
        }
        if (state.matchedLocation.contains("/chat-details")) {
          return state.matchedLocation;
        }
        if (state.matchedLocation.contains("/reels")) {
          return '/reels';
        }
        if (state.matchedLocation.contains("/profile-details")) {
          return state.matchedLocation;
        }
        if (state.matchedLocation.contains("/edit-profile")) {
          return state.matchedLocation;
        }

        if (state.matchedLocation == "/leaderboard") {
          return "/leaderboard";
        }
        if (state.matchedLocation == "/edit-video") {
          return "/edit-video";
        }
        if (state.matchedLocation == "/accounts") {
          return "/accounts";
        }
        /* if (state.matchedLocation.contains("/one-to-one-chat")) {
          return state.matchedLocation;
        }*/
      }

      if (loggingIn) {
        if (kDebugMode) {
          Logger().i("logginIN: ${state.matchedLocation}");
        }
        return '/home';
      }
      return null;
    },
    refreshListenable: _loginInfo,
  );
}
