import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Service to manage screen wakelock functionality
/// Prevents the device screen from sleeping when the app is active
class WakelockService {
  static final WakelockService _instance = WakelockService._internal();
  factory WakelockService() => _instance;
  WakelockService._internal();

  bool _isEnabled = false;

  /// Enable wakelock to prevent screen sleep
  Future<void> enable() async {
    try {
      await WakelockPlus.enable();
      _isEnabled = true;
      if (kDebugMode) {
        debugPrint('WakelockService: Wakelock enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WakelockService: Failed to enable wakelock - $e');
      }
    }
  }

  /// Disable wakelock to allow screen sleep
  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
      _isEnabled = false;
      if (kDebugMode) {
        debugPrint('WakelockService: Wakelock disabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WakelockService: Failed to disable wakelock - $e');
      }
    }
  }

  /// Toggle wakelock state
  Future<void> toggle() async {
    if (_isEnabled) {
      await disable();
    } else {
      await enable();
    }
  }

  /// Check if wakelock is currently enabled
  Future<bool> isEnabled() async {
    try {
      return await WakelockPlus.enabled;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WakelockService: Failed to check wakelock status - $e');
      }
      return false;
    }
  }

  /// Get current cached status (without async check)
  bool get isEnabledSync => _isEnabled;
}
