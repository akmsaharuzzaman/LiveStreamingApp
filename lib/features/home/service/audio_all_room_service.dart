import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:dlstarlive/features/live_audio/data/models/audio_room_details.dart';
import 'package:dlstarlive/features/live_audio/service/socket_service_audio.dart';

/// Audio Room Service - Centralized management of all audio room operations
/// Handles: socket connection, listeners, room data streaming
class AudioAllRoomService {
  static final AudioAllRoomService _instance = AudioAllRoomService._internal();

  factory AudioAllRoomService() {
    return _instance;
  }

  AudioAllRoomService._internal();

  final AudioSocketService _audioSocket = GetIt.instance<AudioSocketService>();

  // Broadcast stream for audio rooms
  final StreamController<List<AudioRoomDetails>> _audioRoomsController =
      StreamController<List<AudioRoomDetails>>.broadcast();

  // Subscription for audio rooms
  StreamSubscription? _audioRoomsSubscription;

  // State
  List<AudioRoomDetails> _cachedAudioRooms = [];

  // Getters
  Stream<List<AudioRoomDetails>> get audioRoomsStream => _audioRoomsController.stream;
  List<AudioRoomDetails> get cachedAudioRooms => _cachedAudioRooms;

  void _log(String message) {
    if (kDebugMode) {
      const magenta = '\x1B[35m';
      const reset = '\x1B[0m';
      debugPrint('\n$magenta[AUDIO_ROOM_SERVICE] - $reset $message\n');
    }
  }

  /// Initialize audio room service
  Future<void> initialize() async {
    // Ensure listeners are still active
    ensureListenersActive();

    _log('🚀 Initializing audio room service');

    try {
      _setupAudioRoomListener();
      _log('✅ Audio room service initialized');
    } catch (e) {
      _log('❌ Error initializing: $e');
    }
  }

  /// Setup audio room listener
  void _setupAudioRoomListener() {
    _log('📡 Setting up audio room listener');

    _audioRoomsSubscription?.cancel();
    _audioRoomsSubscription = _audioSocket.getAllRoomsStream.listen(
      (rooms) {
        _log('🎤 Audio rooms received: ${rooms.length}');
        _cachedAudioRooms = rooms;
        _audioRoomsController.add(rooms);
      },
      onError: (error) {
        _log('❌ Audio rooms error: $error');
        // Re-setup listener on error to keep it alive
        Future.delayed(const Duration(seconds: 1), () {
          _setupAudioRoomListener();
        });
      },
      cancelOnError: false,
    );
  }

  /// Request audio rooms from socket
  void requestAudioRooms() {
    _log('🔄 Requesting audio rooms');
    if (_audioSocket.isConnected) {
      _audioSocket.getRooms();
    } else {
      _log('⚠️ Audio socket not connected');
    }
  }

  /// Ensure audio listener is still active and re-setup if needed
  void ensureListenersActive() {
    _log('🔍 Ensuring audio listener is active');

    if (_audioRoomsSubscription == null) {
      _log('⚠️ Audio listener was null, re-setting up');
      _setupAudioRoomListener();
    }

    // Request fresh data
    requestAudioRooms();
  }

  /// Cleanup - only cancels subscriptions, keeps streams open
  void cleanup() {
    _log('🧹 Cleaning up audio subscriptions');
    _audioRoomsSubscription?.cancel();
  }

  /// Full dispose - only call when app is shutting down
  void dispose() {
    _log('🧹 Disposing audio room service');
    _audioRoomsSubscription?.cancel();
    _audioRoomsController.close();
    _cachedAudioRooms.clear();
  }
}
