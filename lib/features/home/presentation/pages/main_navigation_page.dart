import 'package:dlstarlive/features/home/presentation/pages/home_page.dart';
import 'package:dlstarlive/features/newsfeed/presentation/pages/newsfeed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  final List<Widget> _pages = [
    const HomePage(),
    const NewsfeedPage(),
    const LivePage(),
    const ChatPage(),
    const ProfilePage(),
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
              _currentIndex = index;
            });
          },
          unselectedLabelStyle: const TextStyle(
            color: Color(0xffFE82A7),
            fontWeight: FontWeight.w600,
          ),
          selectedLabelStyle: const TextStyle(
            color: Color(0xffFE82A7),
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xffFE82A7),
          unselectedItemColor: const Color(0xffFE82A7),

          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                UIConstants.homeIcon,
                width: 24,
                height: 24,
              ),
              activeIcon: SvgPicture.asset(
                UIConstants.homeIcon,
                width: 24,
                height: 24,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                UIConstants.newsfeedIcon,
                width: 24,
                height: 24,
              ),
              activeIcon: SvgPicture.asset(
                UIConstants.newsfeedIcon,
                width: 24,
                height: 24,
              ),
              label: 'Newsfeed',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                UIConstants.liveStreamIcon,
                width: 64,
                height: 64,
              ),
              activeIcon: SvgPicture.asset(
                UIConstants.liveStreamIcon,
                width: 64,
                height: 64,
              ),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                UIConstants.chatIcon,
                width: 24,
                height: 24,
              ),
              activeIcon: SvgPicture.asset(
                UIConstants.chatIcon,
                width: 24,
                height: 24,
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                UIConstants.profileIcon,
                width: 24,
                height: 24,
              ),
              activeIcon: SvgPicture.asset(
                UIConstants.profileIcon,
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
