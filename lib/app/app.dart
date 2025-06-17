import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:streaming_djlive/features/auth/data/repositories/log_in_repository.dart';
import 'package:streaming_djlive/features/auth/presentation/bloc/log_in_bloc/log_in_bloc.dart';
import 'package:streaming_djlive/features/profile/presentation/bloc/profile_bloc.dart';

// Import the new router
import '../core/routing/app_router_new.dart';
import '../features/core/services/login_provider.dart';
import '../features/core/services/navbar_provider.dart';
import '../features/chat/data/models/user_model.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LoginInfo _loginInfo = LoginInfo();
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(_loginInfo);
    // Initialize the navigation helper
    AppNavigation.initialize(_appRouter.router);
  }

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
                    LogInBloc(logInRepository: LogInRepository()),
              ),
              BlocProvider(create: (context) => ProfileBloc()),
            ],
            child: MaterialApp.router(
              title: 'DLStar',
              routerConfig: _appRouter.router,
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

  // Sample users for chat functionality
  List<User> allUsers = [
    User(id: 0, name: 'You', avatar: 'assets/images/new_images/person.png'),
    User(
      id: 1,
      name: 'Addison',
      avatar: 'assets/images/new_images/profile.png',
    ),
    User(id: 2, name: 'Angel', avatar: 'assets/images/new_images/person.png'),
    User(id: 3, name: 'Deanna', avatar: 'assets/images/new_images/profile.png'),
    User(id: 4, name: 'Json', avatar: 'assets/images/new_images/profile.png'),
    User(id: 5, name: 'Judd', avatar: 'assets/images/new_images/person.png'),
    User(id: 6, name: 'Leslie', avatar: 'assets/images/new_images/person.png'),
    User(id: 7, name: 'Nathan', avatar: 'assets/images/new_images/profile.png'),
    User(
      id: 8,
      name: 'Stanley',
      avatar: 'assets/images/new_images/profile.png',
    ),
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
}
