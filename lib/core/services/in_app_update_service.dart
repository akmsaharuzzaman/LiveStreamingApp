import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService {
  static const InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;
  const InAppUpdateService._internal();

  /// Check for app updates and handle forced updates
  static Future<void> checkForUpdate({
    required BuildContext context,
    bool isForced = true,
  }) async {
    // Only check for updates on Android platform
    if (!Platform.isAndroid) {
      return;
    }

    try {
      // Check if update is available
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (isForced) {
          // Force immediate update - user cannot use app without updating
          await _performImmediateUpdate(context, updateInfo);
        } else {
          // Show flexible update option
          await _performFlexibleUpdate(context, updateInfo);
        }
      }
    } catch (e) {
      debugPrint('Error checking for app update: $e');
      // Continue app execution if update check fails
    }
  }

  /// Perform immediate update (forced)
  static Future<void> _performImmediateUpdate(
    BuildContext context,
    AppUpdateInfo updateInfo,
  ) async {
    try {
      if (updateInfo.immediateUpdateAllowed) {
        // Show loading dialog during update
        if (context.mounted) {
          _showUpdateDialog(context, isImmediate: true);
        }

        // Start immediate update
        await InAppUpdate.performImmediateUpdate();

        // This line should not be reached as the app will restart after update
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }
      } else {
        // If immediate update is not allowed, show manual update dialog
        if (context.mounted) {
          _showManualUpdateDialog(context);
        }
      }
    } catch (e) {
      debugPrint('Error performing immediate update: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showUpdateErrorDialog(context);
      }
    }
  }

  /// Perform flexible update (optional)
  static Future<void> _performFlexibleUpdate(
    BuildContext context,
    AppUpdateInfo updateInfo,
  ) async {
    try {
      if (updateInfo.flexibleUpdateAllowed) {
        // Show update available dialog
        final bool shouldUpdate = await _showFlexibleUpdateDialog(context);

        if (shouldUpdate) {
          // Start flexible update
          await InAppUpdate.startFlexibleUpdate();

          // Listen for update completion
          InAppUpdate.completeFlexibleUpdate().then((_) {
            if (context.mounted) {
              _showUpdateCompletedSnackBar(context);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error performing flexible update: $e');
      if (context.mounted) {
        _showUpdateErrorDialog(context);
      }
    }
  }

  /// Show update in progress dialog (for immediate updates)
  static void _showUpdateDialog(
    BuildContext context, {
    required bool isImmediate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during update
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button
          child: AlertDialog(
            title: const Text('Updating App'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  isImmediate
                      ? 'Please wait while the app updates...'
                      : 'Downloading update...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show flexible update dialog
  static Future<bool> _showFlexibleUpdateDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Update Available'),
              content: const Text(
                'A new version of the app is available. Would you like to update now?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Show manual update dialog (when in-app update fails)
  static void _showManualUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button
          child: AlertDialog(
            title: const Text('Update Required'),
            content: const Text(
              'A new version is required to continue using this app. '
              'Please update from Google Play Store.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // Close the app - user must update manually
                  // In production, you might want to navigate to Play Store
                  exit(0);
                },
                child: const Text('Exit App'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show update error dialog
  static void _showUpdateErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Error'),
          content: const Text(
            'Failed to update the app. Please try again or update manually from Google Play Store.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show update completed snack bar
  static void _showUpdateCompletedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App updated successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Check for update and show dialog if app needs forced update
  static Future<void> checkForForcedUpdate(BuildContext context) async {
    await checkForUpdate(context: context, isForced: true);
  }

  /// Check for update and show optional update dialog
  static Future<void> checkForOptionalUpdate(BuildContext context) async {
    await checkForUpdate(context: context, isForced: false);
  }
}
