import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../profile/presentation/widgets/user_profile_bottom_sheet.dart';

class HomeContentWidget extends StatelessWidget {
  const HomeContentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(UIConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(state),
              const SizedBox(height: UIConstants.spacingL),

              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: UIConstants.spacingL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(AuthState state) {
    String userName = 'User';
    if (state is AuthAuthenticated) {
      userName = state.user.name;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UIConstants.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $userName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: UIConstants.spacingS),
          const Text(
            'Welcome back to your Flutter app',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: UIConstants.spacingM),
          Row(
            children: [
              Icon(Icons.flutter_dash, color: Colors.white, size: 32),
              const SizedBox(width: UIConstants.spacingM),
              const Text(
                'Powered by Flutter',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: UIConstants.spacingM),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // _buildQuickActionItem(
              //   icon: Icons.article,
              //   label: 'Newsfeed',
              //   color: Colors.blue,
              //   onTap: () {
              //     // Navigate to newsfeed tab
              //   },
              // ),
              // _buildQuickActionItem(
              //   icon: Icons.video_call,
              //   label: 'Go Live',
              //   color: Colors.red,
              //   onTap: () {
              //     // Navigate to live tab
              //   },
              // ),
              // _buildQuickActionItem(
              //   icon: Icons.message,
              //   label: 'Chat',
              //   color: Colors.green,
              //   onTap: () {
              //     // Navigate to chat tab
              //   },
              // ),
              _buildQuickActionItem(
                icon: Icons.person,
                label: 'Profile of a User',
                color: Colors.purple,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const UserProfileBottomSheet(
                      userId:
                          '686e80ad126649815fab59f6', // Updated test user ID
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacingM),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingM),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: UIConstants.spacingS),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
