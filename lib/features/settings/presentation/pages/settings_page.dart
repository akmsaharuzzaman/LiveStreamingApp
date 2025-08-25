import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/utils/device_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _deviceId = 'Loading...';
  bool _deviceIdLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    try {
      final deviceId = await DeviceService.instance.getDeviceId();
      setState(() {
        _deviceId = deviceId;
        _deviceIdLoading = false;
      });
    } catch (e) {
      setState(() {
        _deviceId = 'Error: $e';
        _deviceIdLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Check if this is from account deletion (loading dialog would be showing)
          if (Navigator.of(context).canPop()) {
            // Close loading dialog if it's showing
            Navigator.of(context).popUntil((route) => route.isFirst);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account deleted successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );

            // Navigate to login screen
            context.go('/login');
          } else {
            // Regular logout
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully signed out'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (state is AuthError) {
          // Check if loading dialog is showing (would indicate delete account error)
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Close loading dialog

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete account: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          centerTitle: true,
        ),
        // Match other pages by using a subtle grey background
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha:0.02),
        body: Container(
          color: Theme.of(context).colorScheme.surface,
          height: MediaQuery.of(context).size.height,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: UIConstants.spacingM,
                vertical: UIConstants.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: App Settings
                  Text(
                    'App Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: UIConstants.spacingM),
                  _SectionContainer(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.palette,
                          title: 'Theme',
                          subtitle: 'Light/Dark mode',
                          trailing: Switch(
                            value:
                                Theme.of(context).brightness == Brightness.dark,
                            onChanged: (value) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Theme switching coming soon!'),
                                ),
                              );
                            },
                          ),
                        ),
                        const _SectionDivider(),
                        _SettingsTile(
                          icon: Icons.notifications,
                          title: 'Notifications',
                          subtitle: 'Push notifications',
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
                        const _SectionDivider(),
                        _SettingsTile(
                          icon: Icons.info,
                          title: 'About',
                          subtitle: 'App version and info',
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            _showAboutDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: UIConstants.spacingL),

                  // Section: Account
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: UIConstants.spacingM),
                  _SectionContainer(
                    child: _SettingsTile(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      subtitle: 'Sign out of your account',
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
                                  context.pop();
                                  context.read<AuthBloc>().add(
                                    const AuthLogoutEvent(),
                                  );
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

                  SizedBox(height: UIConstants.spacingL),

                  // Section: Danger Zone
                  Text(
                    'Danger Zone',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: UIConstants.spacingM),
                  _SectionContainer(
                    backgroundColor: Colors.red[50],
                    borderColor: Colors.red[200],
                    child: _SettingsTile(
                      icon: Icons.delete_forever,
                      iconColor: Colors.red[700],
                      title: 'Delete Account',
                      titleColor: Colors.red[700],
                      subtitle: 'Permanently delete your account and all data',
                      subtitleColor: Colors.red[600],
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final shortDeviceId = DeviceService.instance.getShortDeviceId(_deviceId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.music_note, size: 32),
            const SizedBox(width: 8),
            Text(AppConstants.appName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version: ${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Device ID: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Expanded(
                  child: _deviceIdLoading
                      ? const SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _deviceId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Device ID copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    shortDeviceId,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontFamily: 'monospace'),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'A Flutter application built with Clean Architecture, BLoC pattern, and modern development practices.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Close'),
          ),
        ],
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

    // Trigger the delete account event
    context.read<AuthBloc>().add(const AuthDeleteAccountEvent());
  }
}

/// Styled container that matches the Profile page boxes
class _SectionContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  const _SectionContainer({
    required this.child,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.grey.withValues(alpha:0.15));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Color? subtitleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18.r,
        backgroundColor: (iconColor ?? Theme.of(context).colorScheme.primary)
            .withValues(alpha:0.08),
        child: Icon(icon, color: iconColor ?? Colors.black87, size: 20.r),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: titleColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: subtitleColor ?? Colors.black54,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
    );
  }
}
