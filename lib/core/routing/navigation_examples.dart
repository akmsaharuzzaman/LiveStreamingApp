import 'package:flutter/material.dart';
import 'app_router_new.dart';

/// 🚀 NAVIGATION EXAMPLES
///
/// This file demonstrates how to use the new navigation structure
/// with different types of pages and navigation patterns.

class NavigationExamples extends StatelessWidget {
  const NavigationExamples({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Examples'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🏠 Main App Pages (WITH Navigation Bar)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'These pages stay within the navigation shell and maintain the bottom navigation bar:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => AppNavigation.goToHome(),
                    child: const Text('Home'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => AppNavigation.goToNewsfeed(),
                    child: const Text('Newsfeed'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => AppNavigation.goToChat(),
                    child: const Text('Live Chat'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => AppNavigation.goToProfile(),
                    child: const Text('Profile'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              '🎥 Full Screen Pages (NO Navigation Bar)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'These pages provide full-screen experience without navigation bar:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => AppNavigation.goLive(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Go Live'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => AppNavigation.goToReels(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text('Reels'),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => AppNavigation.editVideo(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Edit Video'),
            ),

            const SizedBox(height: 30),

            const Text(
              '📄 Detail/Modal Pages (WITH Back Button)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'These pages are pushed on top with back navigation:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => AppNavigation.pushChatDetails("user123"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Chat Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => AppNavigation.pushLeaderboard(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    child: const Text('Leaderboard'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => AppNavigation.pushProfileDetails(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: const Text('Profile Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => AppNavigation.pushEditProfile(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              '🔙 Navigation Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (AppNavigation.canGoBack()) {
                        AppNavigation.goBack();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cannot go back')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('Go Back'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final location = AppNavigation.currentLocation;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Current: $location')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Current Location'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                '💡 Tips:\n'
                '• Main app pages maintain navigation bar\n'
                '• Full-screen pages hide navigation bar\n'
                '• Detail pages can be pushed/popped\n'
                '• Use go* methods to replace current page\n'
                '• Use push* methods to add to navigation stack',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎯 WIDGET INTEGRATION EXAMPLES
///
/// Examples of how to integrate navigation into various widgets

class NavigationWidgetExamples {
  /// ✅ CORRECT: Bottom navigation bar integration
  static Widget buildBottomNavBar(int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            AppNavigation.goToHome();
            break;
          case 1:
            AppNavigation.goToNewsfeed();
            break;
          case 2:
            AppNavigation.goLive(); // Full screen
            break;
          case 3:
            AppNavigation.goToChat();
            break;
          case 4:
            AppNavigation.goToProfile();
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
        BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  /// ✅ CORRECT: List item with navigation
  static Widget buildChatListItem(String userId, String userName) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(userName),
      subtitle: const Text('Tap to open chat'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => AppNavigation.pushChatDetails(userId),
    );
  }

  /// ✅ CORRECT: Floating action button
  static Widget buildLiveStreamFAB() {
    return FloatingActionButton(
      onPressed: () => AppNavigation.goLive(),
      backgroundColor: Colors.red,
      child: const Icon(Icons.live_tv),
    );
  }

  /// ✅ CORRECT: Custom back button
  static Widget buildCustomBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (AppNavigation.canGoBack()) {
          AppNavigation.goBack();
        } else {
          AppNavigation.goToHome(); // Fallback
        }
      },
    );
  }

  /// ✅ CORRECT: Conditional navigation
  static void navigateBasedOnUserState(bool isProfileComplete) {
    if (isProfileComplete) {
      AppNavigation.goToProfile();
    } else {
      AppNavigation.pushEditProfile();
    }
  }
}

/// 🔄 NAVIGATION FLOW EXAMPLES
///
/// Common navigation patterns and flows

class NavigationFlowExamples {
  /// User authentication flow
  static void handleAuthFlow(bool isLoggedIn, bool isProfileComplete) {
    if (!isLoggedIn) {
      // Handled by router redirect
      return;
    }

    if (!isProfileComplete) {
      // Handled by router redirect to /profileComplete
      return;
    }

    AppNavigation.goToHome();
  }

  /// Social media posting flow
  static void handlePostCreation() {
    // 1. Go to reels (full screen)
    AppNavigation.goToReels();

    // 2. After recording, go to video editor (full screen)
    // AppNavigation.editVideo(); // Called from reels page

    // 3. After editing, return to home with nav bar
    // AppNavigation.goToHome(); // Called from editor
  }

  /// Chat flow
  static void handleChatFlow(String userId) {
    // 1. Go to main chat page (with nav bar)
    AppNavigation.goToChat();

    // 2. Open specific chat (modal/detail)
    AppNavigation.pushChatDetails(userId);
  }

  /// Profile management flow
  static void handleProfileFlow() {
    // 1. Go to profile (with nav bar)
    AppNavigation.goToProfile();

    // 2. View details (modal)
    AppNavigation.pushProfileDetails();

    // 3. Edit profile (modal)
    AppNavigation.pushEditProfile();
  }
}
