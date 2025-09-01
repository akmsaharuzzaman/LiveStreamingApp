import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/api_clients.dart';
import '../models/server_update_model.dart';
import '../constants/app_constants.dart';
import '../../injection/injection.dart';

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

  /// Check for server-side updates first, then fall back to Play Store updates
  static Future<void> checkForForcedUpdate(BuildContext context) async {
    try {
      // Check server-side updates first
      final hasServerUpdate = await _checkServerSideUpdate(context);

      // If no server update required, check Play Store updates
      if (!hasServerUpdate) {
        await checkForUpdate(context: context, isForced: true);
      }
    } catch (e) {
      debugPrint('Error in comprehensive update check: $e');
      // Fall back to Play Store update check
      await checkForUpdate(context: context, isForced: true);
    }
  }

  /// Check for server-side update
  static Future<bool> _checkServerSideUpdate(BuildContext context) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Get server update info
      final genericApiClient = getIt<GenericApiClient>();
      final response = await genericApiClient.get<Map<String, dynamic>>(
        ApiConstants.latestRelease,
      );

      if (response.isSuccess && response.data != null) {
        final serverUpdate = ServerUpdateModel.fromJson(response.data!);

        // Compare versions
        if (_isUpdateRequired(currentVersion, serverUpdate.version)) {
          debugPrint(
            'Server update required: $currentVersion -> ${serverUpdate.version}',
          );

          if (context.mounted) {
            await _showServerUpdateDialog(context, serverUpdate);
          }
          return true;
        } else {
          debugPrint(
            'App is up to date. Current: $currentVersion, Latest: ${serverUpdate.version}',
          );
          return false;
        }
      } else {
        debugPrint('Failed to fetch server update info: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking server-side update: $e');
      return false;
    }
  }

  /// Compare version strings to determine if update is required
  static bool _isUpdateRequired(String currentVersion, String latestVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);

      // Compare major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (latest[i] > current[i]) {
          return true;
        } else if (latest[i] < current[i]) {
          return false;
        }
      }
      return false; // Versions are equal
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false; // Assume no update needed on error
    }
  }

  /// Parse version string into [major, minor, patch] integers
  static List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return [
      int.parse(parts.isNotEmpty ? parts[0] : '0'),
      int.parse(parts.length > 1 ? parts[1] : '0'),
      int.parse(parts.length > 2 ? parts[2] : '0'),
    ];
  }

  /// Show server update dialog with force update
  static Future<void> _showServerUpdateDialog(
    BuildContext context,
    ServerUpdateModel updateInfo,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button
          child: AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.system_update,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text('Update Required'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A new version (${updateInfo.version}) is available and required to continue using the app.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (updateInfo.releaseNote.isNotEmpty) ...[
                    Text(
                      'What\'s New:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        updateInfo.releaseNote,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _launchUpdateUrl(updateInfo.downloadURL);
                  // Close app after directing to download
                  exit(0);
                },
                icon: const Icon(Icons.download),
                label: const Text('Update Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Launch update URL (Play Store or direct download)
  static Future<void> _launchUpdateUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch update URL: $url');
      }
    } catch (e) {
      debugPrint('Error launching update URL: $e');
    }
  }

  /// Check for update and show optional update dialog
  static Future<void> checkForOptionalUpdate(BuildContext context) async {
    try {
      // Check server-side updates first
      final hasServerUpdate = await _checkServerSideUpdateOptional(context);

      // If no server update found, check Play Store updates
      if (!hasServerUpdate) {
        await checkForUpdate(context: context, isForced: false);
      }
    } catch (e) {
      debugPrint('Error in optional update check: $e');
      // Fall back to Play Store update check
      await checkForUpdate(context: context, isForced: false);
    }
  }

  /// Check for server-side update (optional)
  static Future<bool> _checkServerSideUpdateOptional(
    BuildContext context,
  ) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Get server update info
      final genericApiClient = getIt<GenericApiClient>();
      final response = await genericApiClient.get<Map<String, dynamic>>(
        ApiConstants.latestRelease,
      );

      if (response.isSuccess && response.data != null) {
        final serverUpdate = ServerUpdateModel.fromJson(response.data!);

        // Compare versions
        if (_isUpdateRequired(currentVersion, serverUpdate.version)) {
          debugPrint(
            'Optional server update available: $currentVersion -> ${serverUpdate.version}',
          );

          if (context.mounted) {
            await _showOptionalServerUpdateDialog(context, serverUpdate);
          }
          return true;
        } else {
          debugPrint(
            'App is up to date. Current: $currentVersion, Latest: ${serverUpdate.version}',
          );
          return false;
        }
      } else {
        debugPrint('Failed to fetch server update info: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking optional server-side update: $e');
      return false;
    }
  }

  /// Show optional server update dialog
  static Future<void> _showOptionalServerUpdateDialog(
    BuildContext context,
    ServerUpdateModel updateInfo,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.system_update_alt,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('Update Available'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A new version (${updateInfo.version}) is available.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (updateInfo.releaseNote.isNotEmpty) ...[
                  Text(
                    'What\'s New:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      updateInfo.releaseNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _launchUpdateUrl(updateInfo.downloadURL);
              },
              icon: const Icon(Icons.download),
              label: const Text('Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
