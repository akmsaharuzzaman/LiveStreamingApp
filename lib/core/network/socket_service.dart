import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Comprehensive Socket Service for Live Streaming
/// Handles all socket operations including room management and real-time events
class SocketService {
  static SocketService? _instance;
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentRoomId;

  // Stream controllers for different events
  final StreamController<List<String>> _roomListController =
      StreamController<List<String>>.broadcast();
  final StreamController<String> _roomCreatedController =
      StreamController<String>.broadcast();
  final StreamController<String> _roomDeletedController =
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _userJoinedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userLeftController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Constants
  static const String _baseUrl = 'http://dlstarlive.com:8000';

  // Event names
  static const String _createRoomEvent = 'create-room';
  static const String _deleteRoomEvent = 'delete-room';
  static const String _joinRoomEvent = 'join-room';
  static const String _leaveRoomEvent = 'leave-room';
  static const String _getRoomsEvent = 'get-rooms';

  /// Singleton instance
  static SocketService get instance {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  SocketService._internal();

  /// Stream getters for listening to events
  Stream<List<String>> get roomListStream => _roomListController.stream;
  Stream<String> get roomCreatedStream => _roomCreatedController.stream;
  Stream<String> get roomDeletedStream => _roomDeletedController.stream;
  Stream<Map<String, dynamic>> get userJoinedStream =>
      _userJoinedController.stream;
  Stream<Map<String, dynamic>> get userLeftStream => _userLeftController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  Stream<String> get errorStream => _errorController.stream;

  /// Getters
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  String? get currentRoomId => _currentRoomId;

  /// Initialize and connect to socket
  Future<bool> connect(String userId) async {
    try {
      if (_isConnected && _currentUserId == userId) {
        if (kDebugMode) {
          print('🔌 Socket already connected for user: $userId');
        }
        return true;
      }

      // Disconnect if already connected with different user
      if (_isConnected) {
        await disconnect();
      }

      _currentUserId = userId;

      if (kDebugMode) {
        print('🔌 Connecting to socket with userId: $userId');
      }

      // Create socket with userId in query
      _socket = IO.io(
        _baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'userId': userId})
            .disableAutoConnect() // Disable auto connect
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build(),
      );

      _setupSocketListeners();

      // Connect to socket
      final completer = Completer<bool>();

      _socket!.onConnect((_) {
        _isConnected = true;
        _connectionStatusController.add(true);
        if (kDebugMode) {
          print('✅ Socket connected successfully');
        }
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });

      _socket!.onConnectError((error) {
        if (kDebugMode) {
          print('❌ Socket connection error: $error');
        }
        _errorController.add('Connection failed: $error');
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      _socket!.connect();

      // Wait for connection with timeout
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            print('⏰ Socket connection timeout');
          }
          _errorController.add('Connection timeout');
          return false;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('💥 Socket connection exception: $e');
      }
      _errorController.add('Connection exception: $e');
      return false;
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    print('🔧 Setting up socket listeners');
    if (_socket == null) return;

    // Connection events
    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionStatusController.add(false);
      if (kDebugMode) {
        print('🔌 Socket disconnected');
      }
    });

    _socket!.onReconnect((_) {
      _isConnected = true;
      _connectionStatusController.add(true);
      if (kDebugMode) {
        print('🔄 Socket reconnected');
      }
    });

    _socket!.onReconnectError((error) {
      if (kDebugMode) {
        print('❌ Socket reconnection error: $error');
      }
      _errorController.add('Reconnection failed: $error');
    });

    // Room events
    _socket!.on('room-created', (data) {
      if (kDebugMode) {
        print('🏠 Room created: $data');
      }
      if (data is String) {
        _roomCreatedController.add(data);
      }
    });

    _socket!.on('room-deleted', (data) {
      if (kDebugMode) {
        print('🗑️ Room deleted: $data');
      }
      if (data is String) {
        _roomDeletedController.add(data);
      }
    });

    _socket!.on('user-joined', (data) {
      if (kDebugMode) {
        print('👋 User joined: $data');
      }
      if (data is Map<String, dynamic>) {
        _userJoinedController.add(data);
      }
    });

    _socket!.on('user-left', (data) {
      if (kDebugMode) {
        print('👋 User left: $data');
      }
      if (data is Map<String, dynamic>) {
        _userLeftController.add(data);
      }
    });

    _socket!.on('room-list', (data) {
      if (kDebugMode) {
        print('📋 Rooms list received: $data');
      }
      if (data is List) {
        final rooms = data.map((room) => room.toString()).toList();
        _roomListController.add(rooms);
      }
    });

    // Error events
    _socket!.on('error', (error) {
      if (kDebugMode) {
        print('❌ Socket error: $error');
      }
      _errorController.add('Socket error: $error');
    });

    // Custom events for live streaming
    _socket!.on('stream-started', (data) {
      if (kDebugMode) {
        print('🎥 Stream started: $data');
      }
    });

    _socket!.on('stream-ended', (data) {
      if (kDebugMode) {
        print('🛑 Stream ended: $data');
      }
    });

    _socket!.on('viewer-count-updated', (data) {
      if (kDebugMode) {
        print('👥 Viewer count updated: $data');
      }
    });
  }

  /// Create a new room
  Future<bool> createRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return false;
    }

    try {
      if (kDebugMode) {
        print('🏠 Creating room: $roomId');
      }

      _socket!.emit(_createRoomEvent, roomId);
      _currentRoomId = roomId;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating room: $e');
      }
      _errorController.add('Failed to create room: $e');
      return false;
    }
  }

  /// Delete a room (only host can delete)
  Future<bool> deleteRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return false;
    }

    try {
      if (kDebugMode) {
        print('🗑️ Deleting room: $roomId');
      }

      _socket!.emit(_deleteRoomEvent, roomId);

      if (_currentRoomId == roomId) {
        _currentRoomId = null;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting room: $e');
      }
      _errorController.add('Failed to delete room: $e');
      return false;
    }
  }

  /// Join a room
  Future<bool> joinRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return false;
    }

    try {
      if (kDebugMode) {
        print('🚪 Joining room: $roomId');
      }

      _socket!.emit(_joinRoomEvent, roomId);
      _currentRoomId = roomId;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error joining room: $e');
      }
      _errorController.add('Failed to join room: $e');
      return false;
    }
  }

  /// Leave a room
  Future<bool> leaveRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return false;
    }

    try {
      if (kDebugMode) {
        print('🚪 Leaving room: $roomId');
      }

      _socket!.emit(_leaveRoomEvent, roomId);

      if (_currentRoomId == roomId) {
        _currentRoomId = null;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error leaving room: $e');
      }
      _errorController.add('Failed to leave room: $e');
      return false;
    }
  }

  /// Get list of all rooms
  Future<bool> getRooms() async {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return false;
    }

    try {
      if (kDebugMode) {
        print('📋 Getting rooms list');
      }

      _socket!.emit(_getRoomsEvent);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting rooms: $e');
      }
      _errorController.add('Failed to get rooms: $e');
      return false;
    }
  }

  /// Send custom event
  void emit(String event, [dynamic data]) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return;
    }

    try {
      if (kDebugMode) {
        print('📤 Emitting event: $event, data: $data');
      }

      if (data != null) {
        _socket!.emit(event, data);
      } else {
        _socket!.emit(event);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error emitting event: $e');
      }
      _errorController.add('Failed to emit event: $e');
    }
  }

  /// Listen to custom events
  void on(String event, Function(dynamic) callback) {
    if (_socket == null) {
      _errorController.add('Socket not initialized');
      return;
    }

    _socket!.on(event, callback);
  }

  /// Remove event listener
  void off(String event) {
    if (_socket == null) return;
    _socket!.off(event);
  }

  /// Disconnect from socket
  Future<void> disconnect() async {
    try {
      if (kDebugMode) {
        print('🔌 Disconnecting socket');
      }

      // Leave current room if any
      if (_currentRoomId != null) {
        await leaveRoom(_currentRoomId!);
      }

      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }

      _isConnected = false;
      _currentUserId = null;
      _currentRoomId = null;
      _connectionStatusController.add(false);

      if (kDebugMode) {
        print('✅ Socket disconnected successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disconnecting socket: $e');
      }
    }
  }

  /// Dispose all resources
  void dispose() {
    disconnect();

    // Close all stream controllers
    _roomListController.close();
    _roomCreatedController.close();
    _roomDeletedController.close();
    _userJoinedController.close();
    _userLeftController.close();
    _connectionStatusController.close();
    _errorController.close();

    _instance = null;
  }

  /// Check if socket is healthy
  bool get isHealthy {
    return _isConnected && _socket != null && _socket!.connected;
  }

  /// Reconnect if disconnected
  Future<bool> reconnect() async {
    if (_currentUserId == null) {
      _errorController.add('No user ID available for reconnection');
      return false;
    }

    await disconnect();
    return await connect(_currentUserId!);
  }
}
