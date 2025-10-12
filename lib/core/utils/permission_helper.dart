import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionHelper {
  // Request camera and microphone permissions for live streaming
  static Future<bool> requestLiveStreamPermissions() async {
    Map<Permission, PermissionStatus> permissions = await [Permission.camera, Permission.microphone].request();

    bool cameraGranted = permissions[Permission.camera] == PermissionStatus.granted;
    bool microphoneGranted = permissions[Permission.microphone] == PermissionStatus.granted;

    return cameraGranted && microphoneGranted;
  }

  // Check if camera and microphone permissions are granted
  static Future<bool> hasLiveStreamPermissions() async {
    bool cameraGranted = await Permission.camera.isGranted;
    bool microphoneGranted = await Permission.microphone.isGranted;

    return cameraGranted && microphoneGranted;
  }

  static Future<bool> requestAudioStreamPermissions() async {
    final permissions = await [Permission.microphone].request();
    return permissions[Permission.microphone] == PermissionStatus.granted;
  }

  static Future<bool> hasAudioStreamPermissions() async {
    return await Permission.microphone.isGranted;
  }

  // Show permission dialog if permissions are denied
  static Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'This app needs camera and microphone permissions to enable live streaming. '
            'Please grant these permissions in your device settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Request specific permission with proper handling
  static Future<bool> requestPermission(Permission permission) async {
    PermissionStatus status = await permission.request();
    return status == PermissionStatus.granted;
  }

  // Check specific permission status
  static Future<bool> checkPermission(Permission permission) async {
    return await permission.isGranted;
  }
}
