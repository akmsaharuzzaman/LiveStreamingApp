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

  // Subscriptions
  StreamSubscription? _audioRoomsSubscription;
  StreamSubscription? _connectionStatusSubscription;

  // State
  List<AudioRoomDetails> _cachedAudioRooms = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _currentUserId;

  // Loading state stream
  final StreamController<bool> _loadingController = StreamController<bool>.broadcast();

  // Getters
  Stream<List<AudioRoomDetails>> get audioRoomsStream => _audioRoomsController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;
  List<AudioRoomDetails> get cachedAudioRooms => _cachedAudioRooms;
  bool get isConnected => _audioSocket.isConnected;
  bool get isLoading => _isLoading;

  void _log(String message) {
    if (kDebugMode) {
      const magenta = '\x1B[35m';
      const reset = '\x1B[0m';
      debugPrint('\n$magenta[AUDIO_ROOM_SERVICE] - $reset $message\n');
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    _loadingController.add(loading);
    _log('🔄 Loading state: $loading');
  }

  /// Initialize audio room service with user ID
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId && _audioSocket.isConnected) {
      _log('✅ Already initialized for user: $userId');
      return;
    }

    _log('🚀 Initializing audio room service for user: $userId');
    _currentUserId = userId;

    try {
      // Setup connection status listener for auto-recovery
      _setupConnectionListener();

      // Set loading state
      _setLoading(true);

      // Connect audio socket
      bool connected = await _audioSocket.connect(userId);
      
      if (connected) {
        _log('✅ Audio socket connected');
        _setupAudioRoomListener();
        
        // Request initial room data and wait a bit for response
        _audioSocket.getRooms();
        
        // Wait for initial data (max 2 seconds)
        await Future.delayed(const Duration(milliseconds: 500));
        
        _isInitialized = true;
        _setLoading(false);
      } else {
        _log('❌ Failed to connect audio socket');
        _setLoading(false);
      }
    } catch (e) {
      _log('❌ Error initializing: $e');
    }
  }

  /// Setup connection status listener for auto-recovery
  void _setupConnectionListener() {
    _connectionStatusSubscription?.cancel();
    _connectionStatusSubscription = _audioSocket.connectionStatusStream.listen(
      (isConnected) {
        _log('🔌 Connection status changed: ${isConnected ? "Connected" : "Disconnected"}');
        
        if (!isConnected) {
          _log('⚠️ Socket disconnected, will attempt recovery on next operation');
        } else {
          // Reconnected - re-setup listeners and refresh data
          _log('🔄 Socket reconnected, re-establishing listeners');
          _setupAudioRoomListener();
          requestAudioRooms();
        }
      },
      onError: (error) {
        _log('❌ Connection status error: $error');
      },
      cancelOnError: false,
    );
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
          if (_isInitialized) {
            _setupAudioRoomListener();
          }
        });
      },
      cancelOnError: false,
    );
  }

  /// Request audio rooms from socket
  Future<void> requestAudioRooms() async {
    _log('🔄 Requesting audio rooms');
    _setLoading(true);
    
    if (_audioSocket.isConnected) {
      _audioSocket.getRooms();
      // Wait a bit for response
      await Future.delayed(const Duration(milliseconds: 300));
      _setLoading(false);
    } else {
      _log('⚠️ Audio socket not connected, attempting reconnect');
      
      // Attempt reconnection if we have user ID
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        bool reconnected = await _audioSocket.connect(_currentUserId!);
        if (reconnected) {
          _log('✅ Reconnected successfully');
          _setupAudioRoomListener();
          _audioSocket.getRooms();
          await Future.delayed(const Duration(milliseconds: 300));
          _setLoading(false);
        } else {
          _log('❌ Failed to reconnect audio socket');
          _setLoading(false);
        }
      } else {
        _log('❌ Cannot reconnect: No user ID available');
        _setLoading(false);
      }
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
    _connectionStatusSubscription?.cancel();
  }

  /// Full dispose - only call when app is shutting down
  void dispose() {
    _log('🧹 Disposing audio room service');
    _audioRoomsSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _audioRoomsController.close();
    _loadingController.close();
    _cachedAudioRooms.clear();
    _isInitialized = false;
    _isLoading = false;
    _currentUserId = null;
  }
}
