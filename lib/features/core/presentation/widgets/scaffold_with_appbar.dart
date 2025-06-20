import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../services/login_provider.dart';
import '../../services/navbar_provider.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  /// Constructs an [ScaffoldWithNavBar].
  ScaffoldWithNavBar({required this.child, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  /// The navigation shell and container for the branch Navigators.
  final Widget child;
  final LoginInfo _loginInfo = LoginInfo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: child,
      bottomNavigationBar: Consumer<NavBarProvider>(
        builder: (context, navBarState, _) {
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff2c3968).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: BottomNavigationBar(
                      showSelectedLabels: false,
                      type: BottomNavigationBarType.fixed,
                      showUnselectedLabels: false,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      currentIndex: navBarState.currentIndex,
                      onTap: (int index) {
                        navBarState.setCurrentIndex(index);
                        List<String> routes = [
                          "home",
                          "newsfeed",
                          "go-live",
                          "live-chat",
                          "profile",
                        ];

                        // if (index == 2) {
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) {
                        //         return HomePageScreen();
                        //       },
                        //     ),
                        //   );
                        // } else
                        if (index >= 0 && index < routes.length) {
                          // Use GoRouter for other indexes
                          if (index == 2) {
                            context.pushNamed(routes[index]);
                          } else {
                            context.goNamed(routes[index]);
                          }
                        }
                      },
                      items: [
                        BottomNavigationBarItem(
                          icon: Icon(
                            Iconsax.home_1,
                            color: navBarState.currentIndex == 0
                                ? Colors.redAccent
                                : Colors.black,
                          ),
                          label: "Home",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Iconsax.instagram,
                            color: navBarState.currentIndex == 1
                                ? Colors.redAccent
                                : Colors.black,
                          ),
                          label: "Newsfeed",
                        ),
                        BottomNavigationBarItem(
                          icon: Container(
                            height: 45,
                            width: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.redAccent,
                            ),
                            child: const Icon(
                              Iconsax.play,
                              color: Colors.white,
                            ),
                          ),
                          label: "Go Live",
                          backgroundColor: Colors.white,
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Iconsax.message,
                            color: navBarState.currentIndex == 3
                                ? Colors.redAccent
                                : Colors.black,
                          ),
                          label: "Chat",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Iconsax.profile_tick,
                            color: navBarState.currentIndex == 4
                                ? Colors.redAccent
                                : Colors.black,
                          ),
                          backgroundColor: Colors.white,
                          label: "Profile",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Navigate to the current location of the branch at the provided index when
  /// tapping an item in the BottomNavigationBar.
}


/*
class ScaffoldWithNavBar extends StatelessWidget {
  /// Constructs an [ScaffoldWithNavBar].
  ScaffoldWithNavBar({
    required this.child,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  /// The navigation shell and container for the branch Navigators.
  final Widget child;
  final LoginInfo _loginInfo = LoginInfo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar:
          Consumer<NavBarProvider>(builder: (context, navBarState, _) {
        return SizedBox(
          height: navBarState.isHidden ? 0 : null,
          child: BottomNavigationBar(
            elevation: 100,

            // fixedColor: Colors.black,
            selectedItemColor: Colors.redAccent,
            unselectedItemColor: Colors.black,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12,
            // Here, the items of BottomNavigationBar are hard coded. In a real
            // world scenario, the items would most likely be generated from the
            // branches of the shell route, which can be fetched using
            // `navigationShell.route.branches`.
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: navBarState.currentIndex == 0
                          ? Color(0xffEC1527)
                          : Colors.transparent,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                              height: 23,
                              width: 20,
                              child: Image(
                                image: AssetImage("assets/images/courses.png"),
                                color: navBarState.currentIndex == 0
                                    ? Colors.white
                                    : Color(0xff979797),
                              )),
                        ),
                      ],
                    )),
                label: navBarState.currentIndex == 0
                    ? ""
                    : AppLocalizations.of(context)!.navigationHome,
              ),
              BottomNavigationBarItem(
                icon: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: navBarState.currentIndex == 1
                          ? Color(0xffEC1527)
                          : Colors.transparent,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                          height: 23,
                          width: 20,
                          child: Image(
                            image:
                                AssetImage("assets/images/download_navbar.png"),
                            color: navBarState.currentIndex == 1
                                ? Colors.white
                                : Color(0xff979797),
                          )),
                    )),
                label: navBarState.currentIndex == 1
                    ? ""
                    : AppLocalizations.of(context)!.download,
              ),
              */
/* BottomNavigationBarItem(
                icon: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: navBarState.currentIndex == 2
                          ? Color(0xffEC1527)
                          : Colors.transparent,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                          height: 23,
                          width: 20,
                          child: Image(
                            image:
                            AssetImage("assets/images/gsm_chat_navbar.png"),
                            color: navBarState.currentIndex == 2
                                ? Colors.white
                                : Color(0xff979797),
                          )),
                    )),
                label: navBarState.currentIndex == 2
                    ? ""
                    : AppLocalizations.of(context)!.gsmChat,
              ),*/ /*

              BottomNavigationBarItem(
                icon: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: navBarState.currentIndex == 2
                          ? Color(0xffEC1527)
                          : Colors.transparent,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                          height: 23,
                          width: 20,
                          child: Image(
                            image:
                                AssetImage("assets/images/service_navbar.png"),
                            color: navBarState.currentIndex == 2
                                ? Colors.white
                                : Color(0xff979797),
                          )),
                    )),
                label: navBarState.currentIndex == 2
                    ? ""
                    : AppLocalizations.of(context)!.service,
              ),
              BottomNavigationBarItem(
                icon: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: navBarState.currentIndex == 3
                          ? Color(0xffEC1527)
                          : Colors.transparent,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                          height: 23,
                          width: 20,
                          child: Image(
                            image: AssetImage("assets/images/more_navbar.png"),
                            color: navBarState.currentIndex == 3
                                ? Colors.white
                                : Color(0xff979797),
                          )),
                    )),
                label: navBarState.currentIndex == 3
                    ? ""
                    : AppLocalizations.of(context)!.more,
              )
              */
/* BottomNavigationBarItem(
                icon: SizedBox(
                    height: 20,
                    width: 20,
                    child: Image(
                      image: AssetImage("assets/images/courses.png"),
                      color: navBarState.currentIndex == 1
                          ? Colors.red
                          : Colors.black,
                    )),
                label: AppLocalizations.of(context)!.navigationMyCourse,
              ),
              BottomNavigationBarItem(
                  icon: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image(
                        image: AssetImage("assets/images/group_link.png"),
                        color: navBarState.currentIndex == 2
                            ? Colors.red
                            : Colors.black,
                      )),
                  label: AppLocalizations.of(context)!.navigationGroupLink),
              BottomNavigationBarItem(
                icon: SizedBox(
                    height: 20,
                    width: 20,
                    child: Image(
                      image: AssetImage("assets/images/profile.png"),
                      color: navBarState.currentIndex == 3
                          ? Colors.red
                          : Colors.black,
                    )),
                label: AppLocalizations.of(context)!.navigationMyProfile,
              ),*/ /*

            ],
            currentIndex: navBarState.currentIndex,
            onTap: (int index) {
              navBarState.setCurrentIndex(index);
              switch (index) {
                case 0:
                  context.goNamed("homeBeforeLogIn");
                  break;
                case 1:
                  context.goNamed("download");
                  break;
                */
/* case 2:
                  context.goNamed("gsmChat");
                  break;*/ /*

                case 2:
                  context.goNamed("service");
                  break;
                case 3:
                  context.goNamed("more");
                  break;
              }
            },
          ),
        );
      }),
    );
  }

  /// Navigate to the current location of the branch at the provided index when
  /// tapping an item in the BottomNavigationBar.
}*/
