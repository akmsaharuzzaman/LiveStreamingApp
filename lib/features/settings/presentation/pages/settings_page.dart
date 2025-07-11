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
            ],
          ),
        ),
      ),
    );
  }
}
