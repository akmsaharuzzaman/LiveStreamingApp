import 'package:dlstarlive/features/home/presentation/pages/home_page.dart';
import 'package:dlstarlive/features/newsfeed/presentation/pages/newsfeed.dart';
import 'package:dlstarlive/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/services/in_app_update_service.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart' show ChatBloc, StartAutoRefreshEvent, StopAutoRefreshEvent;
import '../../../profile/presentation/pages/profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  // Initialize pages once to preserve state across tab switches
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Initialize pages ONCE - this preserves socket connections and state
    _pages = [
      const HomePage(), // No unique key - widget persists across tab switches
      const NewsfeedPage(),
      const SizedBox(),
      const ChatPage(),
      ProfilePage(
        key: ValueKey('profile_${DateTime.now().millisecondsSinceEpoch}'),
      ),
    ];

    // Check for optional app updates when main navigation loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForOptionalUpdates();
    });
  }

  /// Check for optional updates (non-forced) when user is actively using the app
  Future<void> _checkForOptionalUpdates() async {
    try {
      await InAppUpdateService.checkForOptionalUpdate(context);
    } catch (e) {
      debugPrint('Error checking for optional updates: $e');
      // Silently fail for optional updates
    }
  }

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
                // Check if user is host before allowing live stream access
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  final userRole = authState.user.userRole;
                  if (userRole == 'host') {
                    // User is host, allow access to live stream
                    context.push(AppRoutes.live);
                  } else {
                    // User is not host, show restriction message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You must be a host to go live'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } else {
                  // User not authenticated
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to access live streaming'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
                return;
              }

              // Stop polling when leaving chat tab
              if (_currentIndex == 3 && index != 3) {
                context.read<ChatBloc>().add(const StopAutoRefreshEvent());
              }

              // Start polling when entering chat tab
              if (_currentIndex != 3 && index == 3) {
                context.read<ChatBloc>().add(const StartAutoRefreshEvent());
              }

              // If home tab is selected, force rebuild to refresh data
              if (index == 0) {
                _currentIndex = index;
                // Force rebuild to refresh home data
                return;
              }

              // If profile tab is selected, force rebuild to refresh profile data
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
