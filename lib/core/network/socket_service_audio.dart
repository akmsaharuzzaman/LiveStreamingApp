import 'dart:async';
import 'package:dlstarlive/core/network/models/ban_user_model.dart';
import 'package:dlstarlive/core/network/models/broadcaster_model.dart';
import 'package:dlstarlive/core/network/models/call_request_list_model.dart';
import 'package:dlstarlive/core/network/models/call_request_model.dart';
import 'package:dlstarlive/core/network/models/chat_model.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:dlstarlive/core/network/models/gift_model.dart';
import 'package:dlstarlive/core/network/models/joined_user_model.dart';
import 'package:dlstarlive/core/network/models/left_user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'models/admin_details_model.dart';
import 'models/mute_user_model.dart';


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
  final StreamController<JoinedUserModel> _userJoinedController =
      StreamController<JoinedUserModel>.broadcast();
  final StreamController<LeftUserModel> _userLeftController =
      StreamController<LeftUserModel>.broadcast();
  final StreamController<CallRequestModel> _joinCallRequestController =
      StreamController<CallRequestModel>.broadcast();
  final StreamController<List<CallRequestListModel>>
  _joinCallRequestListController =
      StreamController<List<CallRequestListModel>>.broadcast();
  final StreamController<List<String>> _acceptCallRequestController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<String>> _removeBroadcasterController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<BroadcasterModel>> _broadcasterListController =
      StreamController<List<BroadcasterModel>>.broadcast();
  final StreamController<List<BroadcasterModel>> _broadcasterDetailsController =
      StreamController<List<BroadcasterModel>>.broadcast();
  final StreamController<List<String>> _roomListController =
      StreamController<List<String>>.broadcast();
  final StreamController<List<GetRoomModel>> _getRoomsController =
      StreamController<List<GetRoomModel>>.broadcast();
  final StreamController<ChatModel> _sentMessageController =
      StreamController<ChatModel>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  final StreamController<GiftModel> _sentGiftController =
      StreamController<GiftModel>.broadcast();
  final StreamController<BanUserModel> _bannedUserController =
      StreamController<BanUserModel>.broadcast();
  final StreamController<AdminDetailsModel> _adminDetailsController =
      StreamController<AdminDetailsModel>.broadcast();
  final StreamController<List<String>> _bannedListController =
      StreamController<List<String>>.broadcast();
  final StreamController<MuteUserModel> _muteUserController =
      StreamController<MuteUserModel>.broadcast();

  // Constants
  static const String _baseUrl = 'http://31.97.222.97:8000';

  // Event names - Audio room specific events
  static const String _createRoomEvent = 'create-audio-room';
  static const String _deleteRoomEvent = 'delete-audio-room';
  static const String _joinRoomEvent = 'join-audio-room';
  static const String _leaveRoomEvent = 'leave-audio-room';
  static const String _getRoomsEvent = 'get-all-audio-rooms';
  static const String _joinCallRequestEvent = 'join-audio-seat';
  static const String _joinCallRequestListEvent = 'audio-seat-list';
  static const String _sendMessageEvent = 'send-audio-message';
  static const String _acceptCallRequestEvent = 'accept-audio-seat';
  static const String _rejectCallRequestEvent = 'reject-audio-seat';
  static const String _removeBroadcasterEvent = 'remove-from-seat';
  static const String _broadcasterListEvent = 'audio-room-data';
  static const String _broadcasterDetailsEvent = 'audio-room-details';
  static const String _sentGiftEvent = 'send-audio-gift';
  static const String _banUserEvent = 'ban-audio-user';
  static const String _makeAdminEvent = 'make-audio-admin';
  static const String _bannedListEvent = 'audio-banned-list';
  static const String _muteUserEvent = 'audio-mute-or-mute';

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
  Stream<JoinedUserModel> get userJoinedStream => _userJoinedController.stream;
  Stream<LeftUserModel> get userLeftStream => _userLeftController.stream;
  Stream<CallRequestModel> get joinCallRequestStream =>
      _joinCallRequestController.stream;
  Stream<List<BroadcasterModel>> get broadcasterDetailsStream =>
      _broadcasterDetailsController.stream;
  Stream<List<CallRequestListModel>> get joinCallRequestListStream =>
      _joinCallRequestListController.stream;
  Stream<List<String>> get acceptCallRequestStream =>
      _acceptCallRequestController.stream;
  Stream<List<String>> get removeBroadcasterStream =>
      _removeBroadcasterController.stream;
  Stream<List<BroadcasterModel>> get broadcasterListStream =>
      _broadcasterListController.stream;
  Stream<List<String>> get roomListStream => _roomListController.stream;
  Stream<List<GetRoomModel>> get getRoomsStream => _getRoomsController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  Stream<ChatModel> get sentMessageStream => _sentMessageController.stream;
  Stream<GiftModel> get sentGiftStream => _sentGiftController.stream;
  Stream<AdminDetailsModel> get adminDetailsStream =>
      _adminDetailsController.stream;
  Stream<BanUserModel> get bannedUserStream => _bannedUserController.stream;
  Stream<List<String>> get bannedListStream => _bannedListController.stream;
  Stream<MuteUserModel> get muteUserStream => _muteUserController.stream;

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

  /// Clear existing socket listeners to prevent duplicates
  void _clearSocketListeners() {
    if (_socket == null) return;

    debugPrint('🧹 Clearing existing audio socket listeners');

    // Clear all audio event listeners
    _socket!.off('error-message');
    _socket!.off('audio-room-closed');
    _socket!.off('create-audio-user');
    _socket!.off('audio-user-left');
    _socket!.off('join-audio-seat');
    _socket!.off('audio-seat-list');
    _socket!.off('accept-audio-seat');
    _socket!.off('remove-from-seat');
    _socket!.off('audio-room-data');
    _socket!.off('audio-room-list');
    _socket!.off('get-all-audio-rooms');
    _socket!.off('send-audio-data');
    _socket!.off('send-audio-gift');
    _socket!.off('audio-room-details');
    _socket!.off('ban-audio-user');
    _socket!.off('make-audio-admin');
    _socket!.off('audio-banned-list');
    _socket!.off('audio-mute-or-mute');
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    debugPrint('🔧 Setting up socket listeners');
    if (_socket == null) return;

    // Clear any existing listeners to prevent duplicates
    _clearSocketListeners();

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

    // Audio room specific events
    _socket!.on('error-message', (data) {
      if (kDebugMode) {
        print('❌ Error message: $data');
      }
      if (data is Map<String, dynamic>) {
        _errorMessageController.add(data);
      }
    });

    _socket!.on('audio-room-closed', (data) {
      if (kDebugMode) {
        print('🚪 Audio room closed: $data');
      }
      if (data is List) {
        _roomClosedController.add(List<String>.from(data));
      }
    });

    _socket!.on('create-audio-user', (data) {
      if (kDebugMode) {
        print('👋 Audio user joined: $data');
      }
      if (data is Map<String, dynamic>) {
        _userJoinedController.add(JoinedUserModel.fromJson(data));
      }
    });

    _socket!.on('audio-user-left', (data) {
      if (kDebugMode) {
        print('👋 Audio user left: $data');
      }
      if (data is Map<String, dynamic>) {
        _userLeftController.add(LeftUserModel.fromJson(data));
      }
    });

    _socket!.on('join-audio-seat', (data) {
      if (kDebugMode) {
        print('📞 Join audio seat request: $data');
      }
      if (data is Map<String, dynamic>) {
        _joinCallRequestController.add(CallRequestModel.fromJson(data));
      }
    });

    _socket!.on('audio-seat-list', (data) {
      if (kDebugMode) {
        print('📞 Audio seat list: $data');
      }
      if (data is List) {
        _joinCallRequestListController.add(
          CallRequestListModel.fromListJson(data),
        );
      }
    });

    _socket!.on('accept-audio-seat', (data) {
      if (kDebugMode) {
        print('✅ Accept audio seat: $data');
      }
      if (data is List) {
        _acceptCallRequestController.add(List<String>.from(data));
      }
    });

    _socket!.on('remove-from-seat', (data) {
      if (kDebugMode) {
        print('🚫 Remove from seat: $data');
      }
      if (data is List) {
        _removeBroadcasterController.add(List<String>.from(data));
      }
    });

    _socket!.on('audio-room-data', (data) {
      if (kDebugMode) {
        print('📺 Audio room data: $data');
      }
      if (data is List) {
        List<BroadcasterModel> broadcasters = BroadcasterModel.fromListJson(
          data,
        );
        // Remove duplicates based on ID
        Set<String> seenIds = {};
        broadcasters = broadcasters
            .where((broadcaster) => seenIds.add(broadcaster.id))
            .toList();
        _broadcasterListController.add(broadcasters);
      }
    });

    _socket!.on('audio-room-details', (data) {
      if (kDebugMode) {
        print('📺 Audio room details: $data');
      }
      if (data is List) {
        _broadcasterDetailsController.add(BroadcasterModel.fromListJson(data));
      }
    });

    _socket!.on('audio-room-list', (data) {
      if (kDebugMode) {
        print('📋 Audio room list: $data');
      }
      if (data is List) {
        _roomListController.add(List<String>.from(data));
      }
    });

    _socket!.on('get-all-audio-rooms', (data) {
      if (kDebugMode) {
        print('🏠 Get all audio rooms response: $data');
      }
      if (data is List) {
        _getRoomsController.add(GetRoomModel.listFromJson(data));
      }
    });

    _socket!.on('send-audio-data', (data) {
      if (kDebugMode) {
        print('💬 Audio message response: $data');
      }
      if (data is Map<String, dynamic>) {
        _sentMessageController.add(ChatModel.fromJson(data));
      }
    });

    // Audio Gift events
    _socket!.on('send-audio-gift', (data) {
      if (kDebugMode) {
        print('🎁 Audio gift response: $data');
      }
      if (data is Map<String, dynamic>) {
        _sentGiftController.add(GiftModel.fromJson(data));
      }
    });

    //Ban Audio User events
    _socket!.on('ban-audio-user', (data) {
      if (kDebugMode) {
        print('🚫 Ban audio user response: $data');
      }
      if (data is Map<String, dynamic>) {
        _bannedUserController.add(BanUserModel.fromJson(data));
      }
    });

    //Make audio admin
    _socket!.on('make-audio-admin', (data) {
      if (kDebugMode) {
        print('👑 Make audio admin response: $data');
      }
      if (data is Map<String, dynamic>) {
        _adminDetailsController.add(AdminDetailsModel.fromJson(data));
      }
    });

    //Audio Banned List
    _socket!.on('audio-banned-list', (data) {
      if (kDebugMode) {
        print('🚫 Audio banned list response: $data');
      }
      if (data is List) {
        _bannedListController.add(List<String>.from(data));
      }
    });

    //Mute Audio User
    _socket!.on('audio-mute-or-mute', (data) {
      if (kDebugMode) {
        print('🔇 Audio mute user response: $data');
      }
      if (data is Map<String, dynamic>) {
        _muteUserController.add(MuteUserModel.fromJson(data));
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
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('🏠 Creating audio room: $roomId with $numberOfSeats seats');
      }

      final Map<String, dynamic> roomData = {
        'roomId': roomId,
        'title': title,
        'roomType': 'audio',
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

      _socket!.emit(_deleteRoomEvent, {'roomId': roomId});

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

      _socket!.emit(_joinRoomEvent, {'roomId': roomId});
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

      _socket!.emit(_leaveRoomEvent, {'roomId': roomId});

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

      _socket!.emit(_getRoomsEvent, {});
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

  /// Join call request
  Future<bool> joinCallRequest(String roomId) async {
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

      _socket!.emit(_joinCallRequestEvent, {'roomId': roomId});
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

  /// Send Message
  Future<bool> sendMessage(String roomId, String message) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('💬 Sending message to room: $roomId');
      }

      _socket!.emit(_sendMessageEvent, {
        'roomId': roomId,
        'messageText': message,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to send message: $e',
      });
      return false;
    }
  }

  /// Get join call request list
  Future<bool> getJoinCallRequestList() async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('📋 Getting join call request list');
      }

      _socket!.emit(_joinCallRequestListEvent, {'roomId': _currentRoomId});
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting join call request list: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to get join call request list: $e',
      });
      return false;
    }
  }

  /// Accept call request
  Future<bool> acceptCallRequest(String userId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('✅ Accepting call request from user: $userId');
      }

      _socket!.emit(_acceptCallRequestEvent, {
        'roomId': _currentRoomId,
        'targetId': userId,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error accepting call request: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to accept call request: $e',
      });
      return false;
    }
  }

  /// Reject call request
  Future<bool> rejectCallRequest(String userId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('❌ Rejecting call request from user: $userId');
      }

      _socket!.emit(_rejectCallRequestEvent, {
        'roomId': _currentRoomId,
        'targetId': userId,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error rejecting call request: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to reject call request: $e',
      });
      return false;
    }
  }

  /// Remove broadcaster
  Future<bool> removeBroadcaster(String userId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('🚫 Removing broadcaster: $userId');
      }

      _socket!.emit(_removeBroadcasterEvent, {
        'roomId': _currentRoomId,
        'targetId': userId,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing broadcaster: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to remove broadcaster: $e',
      });
      return false;
    }
  }

  ///Ban User
  Future<bool> banUser(String userId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('🚫 Banning user: $userId');
      }

      _socket!.emit(_banUserEvent, {
        'roomId': _currentRoomId,
        'targetId': userId,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error banning user: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to ban user: $e',
      });
      return false;
    }
  }

  ///Mute User
  Future<bool> muteUser(String userId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('🔇 Muting user: $userId');
      }

      _socket!.emit(_muteUserEvent, {
        'roomId': _currentRoomId,
        'targetId': userId,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error muting user: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to mute user: $e',
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

  ///Make admin
  Future<bool> makeAdmin(String userId) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('👑 Making user admin: $userId');
      }

      _socket!.emit(_makeAdminEvent, {
        'roomId': _currentRoomId,
        'targetId': userId,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error making admin: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to make admin: $e',
      });
      return false;
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
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('🪑 Joining seat: $seatKey in room: $roomId');
      }

      final Map<String, dynamic> data = {
        'roomId': roomId,
        'seatKey': seatKey,
        'targetId': targetId,
      };
      
      if (numberOfSeats != null) {
        data['numberOfSeats'] = numberOfSeats;
      }

      _socket!.emit('join-audio-seat', data);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error joining seat: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to join seat: $e',
      });
      return false;
    }
  }

  /// Leave a specific seat in audio room
  Future<bool> leaveSeat({
    required String roomId,
    required String seatKey,
    required String targetId,
  }) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('🚪 Leaving seat: $seatKey in room: $roomId');
      }

      _socket!.emit('leave-audio-seat', {
        'roomId': roomId,
        'seatKey': seatKey,
        'targetId': targetId,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error leaving seat: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to leave seat: $e',
      });
      return false;
    }
  }

  /// Accept user to a specific seat (host only)
  Future<bool> acceptToSeat({
    required String roomId,
    required String seatKey,
    required String targetId,
  }) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('✅ Accepting user to seat: $seatKey');
      }

      _socket!.emit('accept-audio-seat', {
        'roomId': roomId,
        'seatKey': seatKey,
        'targetId': targetId,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error accepting to seat: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to accept to seat: $e',
      });
      return false;
    }
  }

  /// Remove user from a specific seat (host only)
  Future<bool> removeFromSeat({
    required String roomId,
    required String seatKey,
    required String targetId,
  }) async {
    if (!_isConnected || _socket == null) {
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('🚫 Removing user from seat: $seatKey');
      }

      _socket!.emit('remove-from-seat', {
        'roomId': roomId,
        'seatKey': seatKey,
        'targetId': targetId,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing from seat: $e');
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Failed to remove from seat: $e',
      });
      return false;
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
}
