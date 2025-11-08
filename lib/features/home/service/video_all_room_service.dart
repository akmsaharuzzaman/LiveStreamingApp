import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:dlstarlive/core/network/socket_service.dart';

/// Video Room Service - Centralized management of all video room operations
/// Handles: socket connection, listeners, room data streaming
class VideoAllRoomService {
  static final VideoAllRoomService _instance = VideoAllRoomService._internal();

  factory VideoAllRoomService() {
    return _instance;
  }

  VideoAllRoomService._internal();

  final SocketService _videoSocket = SocketService.instance;

  // Broadcast stream for video rooms
  final StreamController<List<GetRoomModel>> _videoRoomsController =
      StreamController<List<GetRoomModel>>.broadcast();

  // Subscriptions
  StreamSubscription? _videoRoomsSubscription;
  StreamSubscription? _connectionStatusSubscription;

  // State
  List<GetRoomModel> _cachedVideoRooms = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _currentUserId;

  // Loading state stream
  final StreamController<bool> _loadingController = StreamController<bool>.broadcast();

  // Getters
  Stream<List<GetRoomModel>> get videoRoomsStream => _videoRoomsController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;
  List<GetRoomModel> get cachedVideoRooms => _cachedVideoRooms;
  bool get isConnected => _videoSocket.isConnected;
  bool get isLoading => _isLoading;

  void _log(String message) {
    if (kDebugMode) {
      const cyan = '\x1B[36m';
      const reset = '\x1B[0m';
      debugPrint('\n$cyan[VIDEO_ROOM_SERVICE] - $reset $message\n');
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    _loadingController.add(loading);
    _log('🔄 Loading state: $loading');
  }

  /// Initialize video room service with user ID
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId && _videoSocket.isConnected) {
      _log('✅ Already initialized for user: $userId');
      return;
    }

    _log('🚀 Initializing video room service for user: $userId');
    _currentUserId = userId;

    try {
      // Setup connection status listener for auto-recovery
      _setupConnectionListener();

      // Set loading state
      _setLoading(true);

      // Connect video socket
      bool connected = await _videoSocket.connect(userId);
      
      if (connected) {
        _log('✅ Video socket connected');
        _setupVideoRoomListener();
        
        // Request initial room data
        await _videoSocket.getRooms();
        
        // Wait for initial data
        await Future.delayed(const Duration(milliseconds: 500));
        
        _isInitialized = true;
        _setLoading(false);
      } else {
        _log('❌ Failed to connect video socket');
        _setLoading(false);
      }
    } catch (e) {
      _log('❌ Error initializing: $e');
    }
  }

  /// Setup connection status listener for auto-recovery
  void _setupConnectionListener() {
    _connectionStatusSubscription?.cancel();
    _connectionStatusSubscription = _videoSocket.connectionStatusStream.listen(
      (isConnected) {
        _log('🔌 Connection status changed: ${isConnected ? "Connected" : "Disconnected"}');
        
        if (!isConnected) {
          _log('⚠️ Socket disconnected, will attempt recovery on next operation');
        } else {
          // Reconnected - re-setup listeners and refresh data
          _log('🔄 Socket reconnected, re-establishing listeners');
          _setupVideoRoomListener();
          requestVideoRooms();
        }
      },
      onError: (error) {
        _log('❌ Connection status error: $error');
      },
      cancelOnError: false,
    );
  }

  /// Setup video room listener
  void _setupVideoRoomListener() {
    _log('📡 Setting up video room listener');

    _videoRoomsSubscription?.cancel();
    _videoRoomsSubscription = _videoSocket.getRoomsStream.listen(
      (rooms) {
        _log('📹 Video rooms received: ${rooms.length}');
        _cachedVideoRooms = rooms;
        _videoRoomsController.add(rooms);
      },
      onError: (error) {
        _log('❌ Video rooms error: $error');
        // Re-setup listener on error to keep it alive
        Future.delayed(const Duration(seconds: 1), () {
          if (_isInitialized) {
            _setupVideoRoomListener();
          }
        });
      },
      cancelOnError: false,
    );
  }

  /// Request video rooms from socket
  Future<void> requestVideoRooms() async {
    _log('🔄 Requesting video rooms');
    _setLoading(true);
    
    if (_videoSocket.isConnected) {
      await _videoSocket.getRooms();
      await Future.delayed(const Duration(milliseconds: 300));
      _setLoading(false);
    } else {
      _log('⚠️ Video socket not connected, attempting reconnect');
      
      // Attempt reconnection if we have user ID
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        bool reconnected = await _videoSocket.connect(_currentUserId!);
        if (reconnected) {
          _log('✅ Reconnected successfully');
          _setupVideoRoomListener();
          await _videoSocket.getRooms();
          await Future.delayed(const Duration(milliseconds: 300));
          _setLoading(false);
        } else {
          _log('❌ Failed to reconnect video socket');
          _setLoading(false);
        }
      } else {
        _log('❌ Cannot reconnect: No user ID available');
        _setLoading(false);
      }
    }
  }

  /// Ensure video listener is still active and re-setup if needed
  void ensureListenersActive() {
    _log('🔍 Ensuring video listener is active');

    if (_videoRoomsSubscription == null) {
      _log('⚠️ Video listener was null, re-setting up');
      _setupVideoRoomListener();
    }

    // Request fresh data
    requestVideoRooms();
  }

  /// Cleanup - only cancels subscriptions, keeps streams open
  void cleanup() {
    _log('🧹 Cleaning up video subscriptions');
    _videoRoomsSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
  }

  /// Full dispose - only call when app is shutting down
  void dispose() {
    _log('🧹 Disposing video room service');
    _videoRoomsSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _videoRoomsController.close();
    _loadingController.close();
    _cachedVideoRooms.clear();
    _isInitialized = false;
    _isLoading = false;
    _currentUserId = null;
  }
}
