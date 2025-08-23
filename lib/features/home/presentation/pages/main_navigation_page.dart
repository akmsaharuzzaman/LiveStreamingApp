import 'package:dlstarlive/features/home/presentation/pages/home_page.dart';
import 'package:dlstarlive/features/newsfeed/presentation/pages/newsfeed.dart';
import 'package:dlstarlive/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../live/presentation/pages/live_page.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    const HomePage(),
    const NewsfeedPage(),
    const SizedBox(),
    const ChatPage(),
    // Use a unique key to force ProfilePage to rebuild each time
    ProfilePage(
      key: ValueKey('profile_${DateTime.now().millisecondsSinceEpoch}'),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              if (index == 2) {
                // Skip the middle item (Live Stream)
                context.push(AppRoutes.live);
                return;
              }

              // If profile tab is selected, force rebuild by updating state
              if (index == 4) {
                _currentIndex = index;
                // Force rebuild to refresh profile data
                return;
              }

              _currentIndex = index;
            });
          },
          unselectedLabelStyle: const TextStyle(
            color: Color(0xff825CB3),
            fontWeight: FontWeight.w600,
          ),
          selectedLabelStyle: const TextStyle(
            color: Color(0xff825CB3),
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xff825CB3),
          unselectedItemColor: const Color(0xff825CB3),

          items: [
            BottomNavigationBarItem(
              icon: Image.asset(UIConstants.homeIcon, width: 24, height: 24),
              activeIcon: Image.asset(
                UIConstants.homeIconFill,
                width: 24,
                height: 24,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                UIConstants.newsfeedIcon,
                width: 24,
                height: 24,
              ),
              activeIcon: Image.asset(
                UIConstants.newsfeedIconFill,
                width: 24,
                height: 24,
              ),
              label: 'Newsfeed',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                UIConstants.liveStreamIcon,
                width: 64,
                height: 64,
              ),
              activeIcon: Image.asset(
                UIConstants.liveStreamIcon,
                width: 64,
                height: 64,
              ),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Image.asset(UIConstants.chatIcon, width: 24, height: 24),
              activeIcon: Image.asset(
                UIConstants.chatIconFill,
                width: 24,
                height: 24,
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(UIConstants.profileIcon, width: 24, height: 24),
              activeIcon: Image.asset(
                UIConstants.profileIconFill,
                width: 24,
                height: 24,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
