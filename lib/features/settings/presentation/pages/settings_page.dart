import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/auth/auth_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Show success message when logout is completed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully signed out'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App Settings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: UIConstants.spacingL),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('Theme'),
                      subtitle: const Text('Light/Dark mode'),
                      trailing: Switch(
                        value: Theme.of(context).brightness == Brightness.dark,
                        onChanged: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Theme switching coming soon!'),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notifications'),
                      subtitle: const Text('Push notifications'),
                      trailing: Switch(
                        value: true,
                        onChanged: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Notification settings coming soon!',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('About'),
                      subtitle: const Text('App version and info'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: AppConstants.appName,
                          applicationVersion: AppConstants.appVersion,
                          applicationIcon: const Icon(
                            Icons.music_note,
                            size: 48,
                          ),
                          children: [
                            const Text(
                              'A Flutter application built with Clean Architecture, '
                              'BLoC pattern, and modern development practices.',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: UIConstants.spacingL),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  subtitle: const Text('Sign out of your account'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text(
                          'Are you sure you want to sign out?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              // Close the dialog first
                              context.pop();

                              // Trigger logout event
                              context.read<AuthBloc>().add(
                                const AuthLogoutEvent(),
                              );

                              // Navigate to login page
                              context.go('/login');
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: UIConstants.spacingL),

              // Account Delete Section (Danger Zone)
              Text(
                'Danger Zone',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.red[700]),
              ),
              const SizedBox(height: UIConstants.spacingM),
              Card(
                color: Colors.red[50],
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red[700]),
                  title: Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Permanently delete your account and all data',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                  onTap: () {
                    _showDeleteAccountDialog(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Colors.red[600],
          size: 48,
        ),
        title: Text(
          'Delete Account',
          style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. Deleting your account will:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text('• Delete all your posts and reels'),
            const Text('• Remove your profile permanently'),
            const Text('• Cancel any active subscriptions'),
            const Text('• Delete all your messages and chat history'),
            const Text('• Remove you from all rooms and groups'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action is permanent and cannot be reversed',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              _showFinalDeleteConfirmation(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmation(BuildContext context) {
    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Final Confirmation',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type "DELETE" to confirm account deletion:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  hintText: 'Type DELETE here',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: confirmController.text.trim().toUpperCase() == 'DELETE'
                  ? () {
                      context.pop();
                      _performAccountDeletion(context);
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _performAccountDeletion(BuildContext context) {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Deleting account...'),
          ],
        ),
      ),
    );

    // TODO: Implement actual account deletion API call
    // For now, show a placeholder implementation
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deletion feature coming soon!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    });

    // TODO: Add this to your AuthBloc events:
    // context.read<AuthBloc>().add(const AuthDeleteAccountEvent());
    //
    // And handle the deletion in your backend API:
    // - Delete user data from database
    // - Remove uploaded files (posts, reels, avatar)
    // - Cancel subscriptions
    // - Send confirmation email
    // - Sign out the user
  }
}
