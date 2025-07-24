import 'dart:async';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum RoomType { live, pk, audio, party }

/// Comprehensive Socket Service for Live Streaming
/// Handles all socket operations including room management and real-time events
class SocketService {
  static SocketService? _instance;
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentRoomId;

  // Stream controllers for the 11 new events
  final StreamController<Map<String, dynamic>> _errorMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<String>> _roomClosedController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<String>> _userJoinedController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<String>> _userLeftController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<String>> _joinCallRequestController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<String>> _joinCallRequestListController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<String>> _acceptCallRequestController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<String>> _removeBroadcasterController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<String>> _broadcasterListController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<String>> _roomListController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<GetRoomModel>> _getRoomsController =
      StreamController<List<GetRoomModel>>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  // Constants
  static const String _baseUrl = 'http://dlstarlive.com:8000';

  // Event names - Updated to match your new event structure
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

  /// Stream getters for listening to the 11 events
  Stream<Map<String, dynamic>> get errorMessageStream =>
      _errorMessageController.stream;
  Stream<List<String>> get roomClosedStream => _roomClosedController.stream;
  Stream<List<String>> get userJoinedStream => _userJoinedController.stream;
  Stream<List<String>> get userLeftStream => _userLeftController.stream;
  Stream<List<String>> get joinCallRequestStream =>
      _joinCallRequestController.stream;
  Stream<List<String>> get joinCallRequestListStream =>
      _joinCallRequestListController.stream;
  Stream<List<String>> get acceptCallRequestStream =>
      _acceptCallRequestController.stream;
  Stream<List<String>> get removeBroadcasterStream =>
      _removeBroadcasterController.stream;
  Stream<List<String>> get broadcasterListStream =>
      _broadcasterListController.stream;
  Stream<List<String>> get roomListStream => _roomListController.stream;
  Stream<List<GetRoomModel>> get getRoomsStream => _getRoomsController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

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
        _errorMessageController.add({
          'status': 'error',
          'message': 'Connection failed: $error',
        });
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
          _errorMessageController.add({
            'status': 'error',
            'message': 'Connection timeout',
          });
          return false;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('💥 Socket connection exception: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Connection exception: $e',
      });
      return false;
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    debugPrint('🔧 Setting up socket listeners');
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
      _errorMessageController.add({
        'status': 'error',
        'message': 'Reconnection failed: $error',
      });
    });

    // The 11 new events
    _socket!.on('error-message', (data) {
      if (kDebugMode) {
        print('❌ Error message: $data');
      }
      if (data is Map<String, dynamic>) {
        _errorMessageController.add(data);
      }
    });

    _socket!.on('room-closed', (data) {
      if (kDebugMode) {
        print('� Room closed: $data');
      }
      if (data is List) {
        _roomClosedController.add(List<String>.from(data));
      }
    });

    _socket!.on('user-joined', (data) {
      if (kDebugMode) {
        print('👋 User joined: $data');
      }
      if (data is List) {
        _userJoinedController.add(List<String>.from(data));
      }
    });

    _socket!.on('user-left', (data) {
      if (kDebugMode) {
        print('👋 User left: $data');
      }
      if (data is List) {
        _userLeftController.add(List<String>.from(data));
      }
    });

    _socket!.on('join-call-request', (data) {
      if (kDebugMode) {
        print('� Join call request: $data');
      }
      if (data is List) {
        _joinCallRequestController.add(List<String>.from(data));
      }
    });

    _socket!.on('join-call-request-list', (data) {
      if (kDebugMode) {
        print('📞 Join call request list: $data');
      }
      if (data is List) {
        _joinCallRequestListController.add(List<String>.from(data));
      }
    });

    _socket!.on('accept-call-request', (data) {
      if (kDebugMode) {
        print('✅ Accept call request: $data');
      }
      if (data is List) {
        _acceptCallRequestController.add(List<String>.from(data));
      }
    });

    _socket!.on('remove-broadcaster', (data) {
      if (kDebugMode) {
        print('🚫 Remove broadcaster: $data');
      }
      if (data is List) {
        _removeBroadcasterController.add(List<String>.from(data));
      }
    });

    _socket!.on('broadcaster-list', (data) {
      if (kDebugMode) {
        print('📺 Broadcaster list: $data');
      }
      if (data is List) {
        _broadcasterListController.add(List<String>.from(data));
      }
    });

    _socket!.on('room-list', (data) {
      if (kDebugMode) {
        print('📋 Room list: $data');
      }
      if (data is List) {
        _roomListController.add(List<String>.from(data));
      }
    });

    _socket!.on('get-rooms', (data) {
      if (kDebugMode) {
        print('� Get rooms response: $data');
      }
      if (data is List) {
        _getRoomsController.add(GetRoomModel.listFromJson(data));
      }
    });

    // Error events
    _socket!.on('error', (error) {
      if (kDebugMode) {
        print('❌ Socket error: $error');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket error: $error',
      });
    });

    _socket!.on('viewer-count-updated', (data) {
      if (kDebugMode) {
        print('👥 Viewer count updated: $data');
      }
    });
  }

  

  /// Create a new room
  Future<bool> createRoom(String roomId, String title,RoomType roomType) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('🏠 Creating room: $roomId');
      }

      _socket!.emit(_createRoomEvent, {
        'roomId': roomId,
        'title': title,
        'roomType': roomType.toString().split('.').last, // Convert enum to string
      });
      _currentRoomId = roomId;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating room: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to create room: $e',
      });
      return false;
    }
  }

  /// Delete a room (only host can delete)
  Future<bool> deleteRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
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
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to delete room: $e',
      });
      return false;
    }
  }

  /// Join a room
  Future<bool> joinRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('🚪 Joining room: $roomId');
      }

      _socket!.emit(_joinRoomEvent, {
        'roomId': roomId,
      });
      _currentRoomId = roomId;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error joining room: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to join room: $e',
      });
      return false;
    }
  }

  /// Leave a room
  Future<bool> leaveRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
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
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to leave room: $e',
      });
      return false;
    }
  }

  /// Get list of all rooms
  Future<bool> getRooms() async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
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
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to get rooms: $e',
      });
      return false;
    }
  }

  /// Send custom event
  void emit(String event, [dynamic data]) {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
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
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to emit event: $e',
      });
    }
  }

  /// Listen to custom events
  void on(String event, Function(dynamic) callback) {
    if (_socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not initialized',
      });
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

    // Close all stream controllers for the 11 new events
    _errorMessageController.close();
    _roomClosedController.close();
    _userJoinedController.close();
    _userLeftController.close();
    _joinCallRequestController.close();
    _joinCallRequestListController.close();
    _acceptCallRequestController.close();
    _removeBroadcasterController.close();
    _broadcasterListController.close();
    _roomListController.close();
    _getRoomsController.close();
    _connectionStatusController.close();

    _instance = null;
  }

  /// Check if socket is healthy
  bool get isHealthy {
    return _isConnected && _socket != null && _socket!.connected;
  }

  /// Reconnect if disconnected
  Future<bool> reconnect() async {
    if (_currentUserId == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'No user ID available for reconnection',
      });
      return false;
    }

    await disconnect();
    return await connect(_currentUserId!);
  }

  /// Helper method to get room IDs from the latest room list response
  List<String> getAvailableRoomIds() {
    // This would need to be implemented based on how you store the latest room list
    // For now, returning empty list
    return [];
  }

  /// New methods for the updated socket events

  /// Send join call request
  void sendJoinCallRequest(String roomId, String userId) {
    emit('join-call-request', {'roomId': roomId, 'userId': userId});
  }

  /// Send accept call request
  void sendAcceptCallRequest(String roomId, String userId) {
    emit('accept-call-request', {'roomId': roomId, 'userId': userId});
  }

  /// Send remove broadcaster request
  void sendRemoveBroadcasterRequest(String roomId, String userId) {
    emit('remove-broadcaster', {'roomId': roomId, 'userId': userId});
  }

  /// Request broadcaster list for a room
  void requestBroadcasterList(String roomId) {
    emit('broadcaster-list', {'roomId': roomId});
  }

  /// Request join call request list for a room
  void requestJoinCallRequestList(String roomId) {
    emit('join-call-request-list', {'roomId': roomId});
  }
}
