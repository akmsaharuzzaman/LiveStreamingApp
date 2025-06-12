//
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:logger/logger.dart';
//
// import '../../authentication/presentation/pages/email_page.dart';
// import '../../courses/presentation/pages/course_details_page.dart';
// import '../../courses/presentation/pages/my_courses_page.dart';
// import '../../group_link/presentation/pages/group_link_page.dart';
// import '../../home/presentation/pages/my_home_page.dart';
// import '../../onboarding/presentation/pages/onboarding_page.dart';
// import '../../profile/presentation/pages/profile_page.dart';
// import '../presentation/custom_widgets/scaffold_with_appbar.dart';
// import '../services/login_provider.dart';
//
// final GlobalKey<NavigatorState> _rootNavigatorKey =
// GlobalKey<NavigatorState>(debugLabel: 'root');
// final GlobalKey<NavigatorState> _sectionANavigatorKey =
// GlobalKey<NavigatorState>(debugLabel: 'sectionANav');
// final LoginInfo _loginInfo = LoginInfo();
// late final GoRouter router = GoRouter(
//   navigatorKey: _rootNavigatorKey,
//   initialLocation: '/onboarding',
//   routes: <RouteBase>[
//     GoRoute(
//       path: '/onboarding',
//       name: "onboarding",
//       builder: (BuildContext context, GoRouterState state) {
//         return const OnBoardingView();
//       },
//     ),
//     GoRoute(
//       path: '/login',
//       name: "login",
//       builder: (BuildContext context, GoRouterState state) {
//         return const LoginPage();
//       },
//     ),
//     StatefulShellRoute.indexedStack(
//       builder: (BuildContext context, GoRouterState state,
//           StatefulNavigationShell navigationShell) {
//         // Return the widget that implements the custom shell (in this case
//         // using a BottomNavigationBar). The StatefulNavigationShell is passed
//         // to be able access the state of the shell and to navigate to other
//         // branches in a stateful way.
//         return ScaffoldWithNavBar(navigationShell: navigationShell);
//       },
//       branches: <StatefulShellBranch>[
//         // The route branch for the first tab of the bottom navigation bar.
//         StatefulShellBranch(
//           navigatorKey: _sectionANavigatorKey,
//           routes: <RouteBase>[
//             GoRoute(
//               // The screen to display as the root in the first tab of the
//               // bottom navigation bar.
//               path: '/',
//               name: 'home',
//               builder: (BuildContext context, GoRouterState state) =>
//               const MyHomePage(),
//               // routes: <RouteBase>[
//               //   // The details screen to display stacked on navigator of the
//               //   // first tab. This will cover screen A but not the application
//               //   // shell (bottom navigation bar).
//               //   GoRoute(
//               //     path: 'details',
//               //     builder: (BuildContext context, GoRouterState state) =>
//               //         const DetailsScreen(label: 'A'),
//               //   ),
//               // ],
//             ),
//           ],
//         ),
//
//         // The route branch for the second tab of the bottom navigation bar.
//         StatefulShellBranch(
//           // It's not necessary to provide a navigatorKey if it isn't also
//           // needed elsewhere. If not provided, a default key will be used.
//           routes: <RouteBase>[
//             GoRoute(
//               // The screen to display as the root in the second tab of the
//               // bottom navigation bar.
//               path: '/courses',
//               name: 'courses',
//               builder: (BuildContext context, GoRouterState state) =>
//               const MyCoursesPage(),
//
//               routes: <RouteBase>[
//                 // GoRoute(
//                 //   path: 'details',
//                 //   builder: (BuildContext context, GoRouterState state) =>
//                 //       const DetailsScreen(
//                 //     label: 'B',
//                 //   ),
//                 // ),
//                 GoRoute(
//                   // The screen to display as the root in the first tab of the
//                   // bottom navigation bar.
//                   path: 'course-details/:id',
//                   name: 'course_details',
//                   builder: (BuildContext context, GoRouterState state) =>
//                       CourseDetailPage(
//                         courseId:
//                         int.parse(state.pathParameters["id"].toString()),
//                       ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//
//         // The route branch for the third tab of the bottom navigation bar.
//         StatefulShellBranch(
//           routes: <RouteBase>[
//             GoRoute(
//               // The screen to display as the root in the third tab of the
//               // bottom navigation bar.
//               path: '/group-link',
//               name: 'group_link',
//               builder: (BuildContext context, GoRouterState state) =>
//               const GroupLinkView(),
//               // routes: <RouteBase>[
//               //   GoRoute(
//               //     path: 'details',
//               //     builder: (BuildContext context, GoRouterState state) =>
//               //         DetailsScreen(
//               //       label: 'C',
//               //       extra: state.extra,
//               //     ),
//               //   ),
//               // ],
//             ),
//           ],
//         ),
//         StatefulShellBranch(
//           routes: <RouteBase>[
//             GoRoute(
//               // The screen to display as the root in the third tab of the
//               // bottom navigation bar.
//               path: '/profile',
//               name: 'profile',
//               builder: (BuildContext context, GoRouterState state) =>
//               const ProfileView(),
//               // routes: <RouteBase>[
//               //   // GoRoute(
//               //   //   path: 'details',
//               //   //   builder: (BuildContext context, GoRouterState state) =>
//               //   //       DetailsScreen(
//               //   //     label: 'D',
//               //   //     extra: state.extra,
//               //   //   ),
//               //   // ),
//               // ],
//             ),
//           ],
//         ),
//       ],
//     ),
//   ],
//   redirect: (context, state) async {
//     // Using `of` method creates a dependency of StreamAuthScope. It will
//     // cause go_router to reparse current route if StreamAuth has new sign-in
//     // information.
//
//     final bool loggedIn = _loginInfo.loggedIn;
//     final bool loggingIn = state.matchedLocation == '/login' ||
//         state.matchedLocation == "/onboarding";
//     if (!loggedIn) {
//       // await StreamAuthScope.of(context).autoSignIn();
//       Logger().i("Not Logged in");
//       Logger().i(state.matchedLocation);
//       if (state.matchedLocation == "/login") {
//         return '/login';
//       }
//       if (state.matchedLocation == "/onboarding") {
//         return '/onboarding';
//       }
//
//       return "/login";
//     }
//
//     // if the user is logged in but still on the login page, send them to
//     // the home page
//     if (loggingIn) {
//       Logger().i(state.matchedLocation);
//       return '/';
//     }
//
//     // no need to redirect at all
//     return null;
//   },
//   refreshListenable: _loginInfo,
// );
