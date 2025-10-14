import 'dart:async';
import 'package:dlstarlive/core/network/models/ban_user_model.dart';
import 'package:dlstarlive/core/network/models/broadcaster_model.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:dlstarlive/core/network/models/joined_user_model.dart';
import 'package:dlstarlive/core/network/models/left_user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../core/network/models/mute_user_model.dart';
import '../models/chat_model.dart';

/// Comprehensive Socket Service for Audio Live Streaming
/// Handles all socket operations including room management and real-time events
class AudioSocketService {
  static AudioSocketService? _instance;
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentRoomId;

  void _log(String message) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';

    if (kDebugMode) {
      debugPrint('\n$yellow[AUDIO_ROOM] : Socket - $reset $message\n');
    }
  }

  // Constants
  static const String _baseUrl = 'http://31.97.222.97:8000';

  // Event names - Audio room specific events
  static const String _getAllRoomsEvent = 'get-all-audio-rooms'; // 1
  static const String _audioRoomDetailsEvent = 'audio-room-details'; // 2

  static const String _createRoomEvent = 'create-audio-room'; // 3
  static const String _closeRoomEvent = 'close-audio-room'; // 4

  static const String _joinAudioRoomEvent = 'join-audio-room'; // 5
  static const String _leaveAudioRoomEvent = 'leave-audio-room'; // 6
  static const String _userLeftEvent = 'audio-user-left'; // 7

  static const String _joinSeatRequestEvent = 'join-audio-seat'; // 8
  static const String _leaveSeatRequestEvent = 'leave-audio-seat'; // 9
  static const String _removeFromSeatEvent = 'remove-from-seat'; // 10

  static const String _sendMessageEvent = 'send-audio-message'; // 11
  static const String _errorMessageEvent = 'error-message'; // 12

  static const String _muteUnmuteUserEvent = 'audio-mute-unmute'; // 13

  static const String _banUserEvent = 'ban-audio-user'; // 14
  static const String _unbanUserEvent = 'unban-audio-user'; // 15

  // create-audio-room      join-audio-room   join-audio-seat   leave-audio-room     get-all-audio-rooms ;
  //    send-audio-message.   error-message.
  // remove-from-seat.   leave-audio-seat.   audio-room-details.  audio-mute-unmute.   audio-user-left.   ban-audio-user.   unban-audio-user

  // Stream controllers for the 15 events

  // Get all audio rooms stream
  final StreamController<List<GetRoomModel>> _getAllRoomsController = StreamController<List<GetRoomModel>>.broadcast(); // 1

  // Audio room details stream
  final StreamController<List<BroadcasterModel>> _audioRoomDetailsController =
      StreamController<List<BroadcasterModel>>.broadcast(); // 2

  // Create audio room stream
  final StreamController<List<BroadcasterModel>> _createRoomController =
      StreamController<List<BroadcasterModel>>.broadcast(); // 3

  // Close audio room stream
  final StreamController<List<String>> _closeRoomController =
      StreamController<List<String>>.broadcast(); // 4

  // Join audio room stream
  final StreamController<List<BroadcasterModel>> _joinRoomController =
      StreamController<List<BroadcasterModel>>.broadcast(); // 5

  // Leave audio room stream
  final StreamController<List<BroadcasterModel>> _leaveRoomController =
      StreamController<List<BroadcasterModel>>.broadcast(); // 6

  // User left stream
  final StreamController<LeftUserModel> _userLeftController = StreamController<LeftUserModel>.broadcast(); // 7

  // Join audio seat stream
  final StreamController<JoinedUserModel> _joinSeatRequestController =
      StreamController<JoinedUserModel>.broadcast(); // 8

  // Leave audio seat stream
  final StreamController<List<BroadcasterModel>> _leaveSeatRequestController =
      StreamController<List<BroadcasterModel>>.broadcast(); // 9

  // Remove from seat stream
  final StreamController<List<BroadcasterModel>> _removeFromSeatController =
      StreamController<List<BroadcasterModel>>.broadcast(); // 10

  // Send Audio Message stream
  final StreamController<AudioChatModel> _sendMessageController =
      StreamController<AudioChatModel>.broadcast(); // 11

  // Error message stream
  final StreamController<Map<String, dynamic>> _errorMessageController =
      StreamController<Map<String, dynamic>>.broadcast(); // 12

  // Mute/Unmute user stream
  final StreamController<MuteUserModel> _muteUnmuteUserController =
      StreamController<MuteUserModel>.broadcast(); // 13

  // Ban user stream
  final StreamController<BanUserModel> _banUserController =
      StreamController<BanUserModel>.broadcast(); // 14

  // Unban user stream
  final StreamController<BanUserModel> _unbanUserController =
      StreamController<BanUserModel>.broadcast(); // 15

  // Connection status stream
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();


  /// Singleton instance
  static AudioSocketService get instance {
    _instance ??= AudioSocketService._internal();
    return _instance!;
  }

  AudioSocketService._internal();

  /// Stream getters for listening to the 15 events
  Stream<List<GetRoomModel>> get getAllRoomsStream => _getAllRoomsController.stream; // 1
  Stream<List<BroadcasterModel>> get audioRoomDetailsStream => _audioRoomDetailsController.stream; // 2
  Stream<List<BroadcasterModel>> get createRoomStream => _createRoomController.stream; // 3
  Stream<List<String>> get closeRoomStream => _closeRoomController.stream; // 4
  Stream<List<BroadcasterModel>> get joinRoomStream => _joinRoomController.stream; // 5
  Stream<List<BroadcasterModel>> get leaveRoomStream => _leaveRoomController.stream; // 6
  Stream<LeftUserModel> get userLeftStream => _userLeftController.stream; // 7
  Stream<JoinedUserModel> get joinSeatRequestStream => _joinSeatRequestController.stream; // 8
  Stream<List<BroadcasterModel>> get leaveSeatRequestStream => _leaveSeatRequestController.stream; // 9
  Stream<List<BroadcasterModel>> get removeFromSeatStream => _removeFromSeatController.stream; // 10
  Stream<AudioChatModel> get sendMessageStream => _sendMessageController.stream; // 11
  Stream<Map<String, dynamic>> get errorMessageStream => _errorMessageController.stream; // 12
  Stream<MuteUserModel> get muteUnmuteUserStream => _muteUnmuteUserController.stream; // 13
  Stream<BanUserModel> get banUserStream => _banUserController.stream; // 14
  Stream<BanUserModel> get unbanUserStream => _unbanUserController.stream; // 15

  /// Connection status stream
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// Getters
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  String? get currentRoomId => _currentRoomId;

  /// Initialize and connect to socket
  Future<bool> connect(String userId) async {
    try {
      if (_isConnected && _currentUserId == userId) {
        _log('🔌 Socket already connected for user: $userId');
        return true;
      }

      // Disconnect if already connected with different user
      if (_isConnected) {
        await disconnect();
      }

      _currentUserId = userId;

      _log('🔌 Connecting to socket with userId: $userId');

      // Create socket with userId in query
      _socket = IO.io(
        _baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'userId': userId})
            .disableAutoConnect() // Disable auto connect
            .enableForceNew() // Force new connection
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build(),
      );

      // Connect to socket
      final completer = Completer<bool>();

      _socket!.onConnect((_) {
        _isConnected = true;
        _connectionStatusController.add(true);
        _log('✅ Socket connected successfully');
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });

      _socket!.onConnectError((error) {
        _log('❌ Socket connection error: $error');
        _errorMessageController.add({'status': 'error', 'message': 'Connection failed: $error'});
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      _setupSocketListeners();

      _socket!.connect();

      // Wait for connection with timeout
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _log('⏰ Socket connection timeout');
          _errorMessageController.add({'status': 'error', 'message': 'Connection timeout'});
          return false;
        },
      );
    } catch (e) {
      _log('💥 Socket connection exception: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Connection exception: $e'});
      return false;
    }
  }

  /// Clear existing socket listeners to prevent duplicates
  void _clearSocketListeners() {
    if (_socket == null) return;

    _log('🧹 Clearing existing audio socket listeners');

    // Clear all 15 audio event listeners
    _socket!.off(_getAllRoomsEvent); // 1
    _socket!.off(_audioRoomDetailsEvent); // 2
    _socket!.off(_createRoomEvent); // 3
    _socket!.off(_closeRoomEvent); // 4
    _socket!.off(_joinAudioRoomEvent); // 5
    _socket!.off(_leaveAudioRoomEvent); // 6
    _socket!.off(_userLeftEvent); // 7
    _socket!.off(_joinSeatRequestEvent); // 8
    _socket!.off(_leaveSeatRequestEvent); // 9
    _socket!.off(_removeFromSeatEvent); // 10
    _socket!.off(_sendMessageEvent); // 11
    _socket!.off(_errorMessageEvent); // 12
    _socket!.off(_muteUnmuteUserEvent); // 13
    _socket!.off(_banUserEvent); // 14
    _socket!.off(_unbanUserEvent); // 15
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    _log('🔧 Setting up socket listeners');
    if (_socket == null) return;

    // Clear any existing listeners to prevent duplicates
    _clearSocketListeners();

    // Connection events
    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionStatusController.add(false);
      _log('🔌 Socket disconnected');
    });

    _socket!.onReconnect((_) {
      _isConnected = true;
      _connectionStatusController.add(true);
      _log('🔄 Socket reconnected');
    });

    _socket!.onReconnectError((error) {
      _log('❌ Socket reconnection error: $error');
      _errorMessageController.add({'status': 'error', 'message': 'Reconnection failed: $error'});
    });

    // Audio room specific events
    _socket!.on(_errorMessageEvent, (data) {
      _log('❌ Error message: $data');
      if (data is Map<String, dynamic>) {
        _errorMessageController.add(data);
      }
    });

    // User left
    _socket!.on(_userLeftEvent, (data) {
      _log('👋 Audio user left: $data');
      if (data is Map<String, dynamic>) {
        _userLeftController.add(LeftUserModel.fromJson(data));
      }
    });

    // Remove from seat
    _socket!.on(_removeFromSeatEvent, (data) {
      _log('🚫 Remove from seat: $data');
      if (data is List) {
        _removeFromSeatController.add(List<BroadcasterModel>.from(data));
      }
    });

    // Audio room details
    _socket!.on(_audioRoomDetailsEvent, (data) {
      _log('📺 Audio room details: $data');
      if (data is List) {
        _audioRoomDetailsController.add(BroadcasterModel.fromListJson(data));
      }
    });

    // Get all audio rooms
    _socket!.on(_getAllRoomsEvent, (data) {
      _log('🏠 Get all audio rooms response: $data');
      if (data is List) {
        _getAllRoomsController.add(GetRoomModel.listFromJson(data));
      }
    });

    // Sent messages
    _socket!.on(_sendMessageEvent, (data) {
      _log('💬 Audio message response: ${data['message']}');
      try {
        if (data is Map<String, dynamic>) {
          _sendMessageController.add(AudioChatModel.fromJson(data['data']));
        }
      } catch (e) {
        _log('❌ Audio message response error: $e');
      }
    });

    //Ban Audio User
    _socket!.on(_banUserEvent, (data) {
      _log('🚫 Ban audio user response: $data');
      if (data is Map<String, dynamic>) {
        _banUserController.add(BanUserModel.fromJson(data));
      }
    });

    //Mute/Unmute Audio User
    _socket!.on(_muteUnmuteUserEvent, (data) {
      _log('🔇 Audio mute/unmute user response: $data');
      if (data is Map<String, dynamic>) {
        _muteUnmuteUserController.add(MuteUserModel.fromJson(data));
      }
    });
  }

  /// Create a new room
  Future<bool> createRoom(
    String roomId,
    String title, {
    String? targetId,
    int numberOfSeats = 6,
    String seatKey = 'seat-1',
  }) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🏠 Creating audio room: $roomId with $numberOfSeats seats');

      final Map<String, dynamic> roomData = {
        'roomId': roomId,
        'title': title,
        // 'roomType': 'audio',
        'numberOfSeats': numberOfSeats,
        'seatKey': seatKey,
      };

      // Add targetId if provided
      if (targetId != null && targetId.isNotEmpty) {
        roomData['targetId'] = targetId;
      }

      _socket!.emit(_createRoomEvent, roomData);
      _currentRoomId = roomId;
      return true;
    } catch (e) {
      _log('❌ Error creating room: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to create room: $e'});
      return false;
    }
  }

  /// Delete a room (only host can delete)
  Future<bool> deleteRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🗑️ Deleting room: $roomId');

      _socket!.emit(_closeRoomEvent, {'roomId': roomId});

      if (_currentRoomId == roomId) {
        _currentRoomId = null;
      }

      return true;
    } catch (e) {
      _log('❌ Error deleting room: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to delete room: $e'});
      return false;
    }
  }

  /// Join a room
  Future<bool> joinRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🚪 Joining room: $roomId');

      _socket!.emit(_joinAudioRoomEvent, {'roomId': roomId});
      _currentRoomId = roomId;
      return true;
    } catch (e) {
      _log('❌ Error joining room: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to join room: $e'});
      return false;
    }
  }

  /// Leave a room
  Future<bool> leaveRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🚪 Leaving room: $roomId');

      _socket!.emit(_leaveAudioRoomEvent, {'roomId': roomId});

      if (_currentRoomId == roomId) {
        _currentRoomId = null;
      }

      return true;
    } catch (e) {
      _log('❌ Error leaving room: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to leave room: $e'});
      return false;
    }
  }

  /// Get list of all rooms
  Future<bool> getRooms() async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('📋 Getting rooms list');

      _socket!.emit(_getAllRoomsEvent, {});
      return true;
    } catch (e) {
      _log('❌ Error getting rooms: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to get rooms: $e'});
      return false;
    }
  }

  /// Send Message
  Future<bool> sendMessage(String roomId, String message) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('💬 Sending audio message: $message');

      _socket!.emit(_sendMessageEvent, {'roomId': roomId, 'text': message});
      return true;
    } catch (e) {
      _log('❌ Error sending audio message: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to send message: $e'});
      return false;
    }
  }

  ///Ban User
  Future<bool> banUser(String userId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🚫 Banning audio user: $userId');

      _socket!.emit(_banUserEvent, {'roomId': _currentRoomId, 'targetId': userId});
      return true;
    } catch (e) {
      _log('❌ Error banning audio user: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to ban user: $e'});
      return false;
    }
  }

  // Unban User
  Future<bool> unbanUser(String userId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🚫 Unbanning audio user: $userId');

      _socket!.emit(_unbanUserEvent, {'roomId': _currentRoomId, 'targetId': userId});
      return true;
    } catch (e) {
      _log('❌ Error unbanning audio user: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to unban user: $e'});
      return false;
    }
  }

  ///Mute/Unmute User
  Future<bool> muteUnmuteUser(String userId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🔇 Muting/Unmuting audio user: $userId');

      _socket!.emit(_muteUnmuteUserEvent, {'roomId': _currentRoomId, 'targetId': userId});
      return true;
    } catch (e) {
      _log('❌ Error muting/Unmuting audio user: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to mute user: $e'});
      return false;
    }
  }

  /// Send custom event
  void emit(String event, [dynamic data]) {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return;
    }

    try {
      _log('📤 Emitting event: $event, data: $data');

      if (data != null) {
        _socket!.emit(event, data);
      } else {
        _socket!.emit(event);
      }
    } catch (e) {
      _log('❌ Error emitting event: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to emit event: $e'});
    }
  }

  /// Join a specific seat in audio room
  Future<bool> joinSeat({
    required String roomId,
    required String seatKey,
    required String targetId,
    int? numberOfSeats,
  }) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🪑 Joining seat: $seatKey in room: $roomId');

      final Map<String, dynamic> data = {'roomId': roomId, 'seatKey': seatKey, 'targetId': targetId};

      if (numberOfSeats != null) {
        data['numberOfSeats'] = numberOfSeats;
      }

      _socket!.emit(_joinSeatRequestEvent, data);
      return true;
    } catch (e) {
      _log('❌ Error joining seat: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to join seat: $e'});
      return false;
    }
  }

  /// Leave a specific seat in audio room
  Future<bool> leaveSeat({required String roomId, required String seatKey, required String targetId}) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🚪 Leaving seat: $seatKey in room: $roomId');

      _socket!.emit(_leaveSeatRequestEvent, {'roomId': roomId, 'seatKey': seatKey, 'targetId': targetId});
      return true;
    } catch (e) {
      _log('❌ Error leaving seat: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to leave seat: $e'});
      return false;
    }
  }

  /// Remove user from a specific seat (host only)
  Future<bool> removeFromSeat({required String roomId, required String seatKey, required String targetId}) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🚫 Removing user from seat: $seatKey');

      _socket!.emit(_removeFromSeatEvent, {'roomId': roomId, 'seatKey': seatKey, 'targetId': targetId});
      return true;
    } catch (e) {
      _log('❌ Error removing from seat: $e');
      _errorMessageController.add({'status': 'error', 'message': 'Failed to remove from seat: $e'});
      return false;
    }
  }

  /// Listen to custom events
  void on(String event, Function(dynamic) callback) {
    if (_socket == null) {
      _errorMessageController.add({'status': 'error', 'message': 'Socket not initialized'});
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
      _log('🔌 Disconnecting socket');

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

      _log('✅ Socket disconnected successfully');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disconnecting socket: $e');
      }
    }
  }

  /// Dispose all resources
  void dispose() {
    disconnect();

    // Close all stream controllers for the 15 new events
    _getAllRoomsController.close(); // 1
    _audioRoomDetailsController.close(); // 2
    _createRoomController.close(); // 3
    _closeRoomController.close(); // 4
    _joinRoomController.close(); // 5
    _leaveRoomController.close(); // 6
    _userLeftController.close(); // 7
    _joinSeatRequestController.close(); // 8
    _leaveSeatRequestController.close(); // 9
    _removeFromSeatController.close(); // 10
    _sendMessageController.close(); // 11
    _errorMessageController.close(); // 12
    _muteUnmuteUserController.close(); // 13
    _banUserController.close(); // 14
    _unbanUserController.close(); // 15

    _instance = null;
  }

  /// Check if socket is healthy
  bool get isHealthy {
    return _isConnected && _socket != null && _socket!.connected;
  }

  /// Reconnect if disconnected
  Future<bool> reconnect() async {
    if (_currentUserId == null) {
      _errorMessageController.add({'status': 'error', 'message': 'No user ID available for reconnection'});
      return false;
    }

    await disconnect();
    return await connect(_currentUserId!);
  }
}
