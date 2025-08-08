import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static DeviceService? _instance;
  static DeviceService get instance => _instance ??= DeviceService._();
  DeviceService._();

  String? _deviceId;

  /// Get unique device ID
  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor ?? 'ios_unknown';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        _deviceId = windowsInfo.deviceId;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        _deviceId = linuxInfo.machineId ?? 'linux_${linuxInfo.id}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        _deviceId = macInfo.systemGUID ?? 'mac_${macInfo.computerName}';
      } else if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        _deviceId = 'web_${webInfo.userAgent.hashCode}';
      } else {
        _deviceId = 'unknown_device';
      }

      debugPrint('Device ID generated: $_deviceId');
      return _deviceId!;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      // Fallback to a generated ID based on timestamp
      _deviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      return _deviceId!;
    }
  }

  /// Get a shortened version of device ID for display purposes
  String getShortDeviceId(String deviceId) {
    if (deviceId.length <= 8) return deviceId;
    return '${deviceId.substring(0, 4)}...${deviceId.substring(deviceId.length - 4)}';
  }

  /// Reset device ID (for testing purposes)
  void resetDeviceId() {
    _deviceId = null;
  }
}
