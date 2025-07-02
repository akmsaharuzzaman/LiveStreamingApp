import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/navbar_provider.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  /// Constructs an [ScaffoldWithNavBar].
  const ScaffoldWithNavBar({required this.child, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  /// The navigation shell and container for the branch Navigators.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: child,
      bottomNavigationBar: Consumer<NavBarProvider>(
        builder: (context, navBarState, _) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xff2c3968).withOpacity(0.9),
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
              showSelectedLabels: true,
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(
                0xffFE82A7,
              ), // This controls both icon and label color
              selectedLabelStyle: const TextStyle(
                color: Color(0xffFE82A7),
                fontWeight: FontWeight.w600,
              ),

              elevation: 0,
              currentIndex: navBarState.currentIndex,
              onTap: (int index) {
                navBarState.setCurrentIndex(index);
                List<String> routes = [
                  "home",
                  "newsfeed",
                  "ready-to-go-live",
                  "live-chat",
                  "profile",
                ];
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
                  icon: SvgPicture.asset(
                    "assets/svg/home_icon.svg",
                    height: 25,
                    width: 25,
                  ),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    "assets/icon/moment_icon.png",
                    height: 25,
                    width: 25,
                  ),
                  label: "Moments",
                ),
                BottomNavigationBarItem(
                  icon: Center(
                    child: SvgPicture.asset(
                      "assets/svg/live_icon.svg",
                      height: 65,
                      width: 65,
                    ),
                  ),
                  label: "",
                  backgroundColor: Colors.white,
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    "assets/svg/inbox_icon.svg",
                    height: 25,
                    width: 25,
                  ),
                  label: "Inbox",
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    "assets/svg/profile_icon.svg",
                    height: 25,
                    width: 25,
                  ),
                  backgroundColor: Colors.white,
                  label: "Me",
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
