import 'dart:async';
import 'package:flutter/foundation.dart';

/// Lightweight notifier for real-time active speaker tracking
/// Designed for high-frequency updates (200ms intervals from Agora)
///
/// Why not BLoC?
/// - BLoC is heavy for 5 updates/second
/// - Causes unnecessary rebuilds
/// - Wastes CPU on low-end devices
///
/// This is exactly how big apps (Clubhouse, Twitter Spaces) do it.
class ActiveSpeakersNotifier extends ChangeNotifier {
  /// Maps UID -> isSpeaking status
  final Map<int, bool> _activeSpeakers = {};

  /// Maps UID -> cooldown timer (prevents flicker from jittery volume)
  final Map<int, Timer> _cooldownTimers = {};

  /// Get all currently active speaker UIDs
  Set<int> get activeSpeakerUIDs =>
      _activeSpeakers.entries.where((entry) => entry.value).map((entry) => entry.key).toSet();

  /// Check if a specific UID is currently speaking
  bool isSpeaking(int uid) => _activeSpeakers[uid] ?? false;

  /// Update speaker status from Agora volume indication
  /// Uses cooldown timers to prevent flicker from jittery volume readings
  void updateSpeakers(List<int> speakingUIDs) {
    bool hasChanges = false;

    // Mark currently speaking UIDs as active
    for (final uid in speakingUIDs) {
      // Cancel any existing cooldown timer
      _cooldownTimers[uid]?.cancel();

      // Mark as active if not already
      if (_activeSpeakers[uid] != true) {
        _activeSpeakers[uid] = true;
        hasChanges = true;
        // debugPrint('🔊 NOTIFIER: UID $uid started speaking');
      }

      // Set cooldown timer: keep active for 400ms after last detection
      _cooldownTimers[uid] = Timer(const Duration(milliseconds: 400), () {
        if (_activeSpeakers[uid] == true) {
          _activeSpeakers[uid] = false;
          _cooldownTimers.remove(uid);
          // debugPrint('🔊 NOTIFIER: UID $uid stopped speaking (cooldown expired)');
          notifyListeners();
        }
      });
    }

    // Notify if any new speakers became active
    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Clear all speaker states (when leaving room)
  void clear() {
    // Cancel all timers
    for (final timer in _cooldownTimers.values) {
      timer.cancel();
    }
    _cooldownTimers.clear();

    if (_activeSpeakers.isNotEmpty) {
      _activeSpeakers.clear();
      notifyListeners();
    }
  }

  /// Remove a specific UID (when user leaves room)
  void removeUser(int uid) {
    _cooldownTimers[uid]?.cancel();
    _cooldownTimers.remove(uid);

    if (_activeSpeakers.remove(uid) != null) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Cancel all timers
    for (final timer in _cooldownTimers.values) {
      timer.cancel();
    }
    _cooldownTimers.clear();
    _activeSpeakers.clear();
    super.dispose();
  }
}
