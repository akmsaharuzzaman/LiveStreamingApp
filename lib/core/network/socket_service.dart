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
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'models/admin_details_model.dart';
import 'models/mute_user_model.dart';

enum RoomType { live, pk, audio, party }

/// Comprehensive Socket Service for Live Streaming
/// Handles all socket operations including room management and real-time events
class SocketService {
  static SocketService? _instance;
  socket_io.Socket? _socket;
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

  // Event names - Updated to match your new event structure
  static const String _createRoomEvent = 'create-room';
  static const String _deleteRoomEvent = 'delete-room';
  static const String _joinRoomEvent = 'join-room';
  static const String _leaveRoomEvent = 'leave-room';
  static const String _getRoomsEvent = 'get-rooms';
  static const String _joinCallRequestEvent = 'join-call-request';
  static const String _joinCallRequestListEvent = 'join-call-request-list';
  static const String _sendMessageEvent = 'sent-message';
  static const String _acceptCallRequestEvent = 'accept-call-request';
  static const String _rejectCallRequestEvent = 'reject-call-request';
  static const String _removeBroadcasterEvent = 'remove-broadcaster';
  static const String _broadcasterListEvent = 'broadcaster-list';
  static const String _broadcasterDetailsEvent = 'broadcaster-details';
  static const String _sentGiftEvent = 'sent-gift';
  static const String _banUserEvent = 'ban-user';
  static const String _makeAdminEvent = 'make-admin';
  static const String _bannedListEvent = 'banned-list';
  static const String _muteUserEvent = 'mute-user';

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
      _socket = socket_io.io(
        _baseUrl,
        socket_io.OptionBuilder()
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

    debugPrint('🧹 Clearing existing socket listeners');

    // Clear all event listeners
    _socket!.off('error-message');
    _socket!.off('room-closed');
    _socket!.off('user-joined');
    _socket!.off('user-left');
    _socket!.off('join-call-request');
    _socket!.off('join-call-request-list');
    _socket!.off('accept-call-request');
    _socket!.off('remove-broadcaster');
    _socket!.off('broadcaster-list');
    _socket!.off('room-list');
    _socket!.off('get-rooms');
    _socket!.off('sent-message');
    _socket!.off('sent-gift');
    _socket!.off('broadcaster-details');
    _socket!.off('ban-user');
    _socket!.off('make-admin');
    _socket!.off('banned-list');
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
      if (data is Map<String, dynamic>) {
        _userJoinedController.add(JoinedUserModel.fromJson(data));
      }
    });

    _socket!.on('user-left', (data) {
      if (kDebugMode) {
        print('👋 User left: $data');
      }
      if (data is Map<String, dynamic>) {
        _userLeftController.add(LeftUserModel.fromJson(data));
      }
    });

    _socket!.on('join-call-request', (data) {
      if (kDebugMode) {
        print('📱 Join call request: $data');
      }
      if (data is Map<String, dynamic>) {
        _joinCallRequestController.add(CallRequestModel.fromJson(data));
      }
    });

    _socket!.on('join-call-request-list', (data) {
      if (kDebugMode) {
        print('📞 Join call request list: $data');
      }
      if (data is List) {
        _joinCallRequestListController.add(
          CallRequestListModel.fromListJson(data),
        );
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

    _socket!.on('broadcaster-details', (data) {
      if (kDebugMode) {
        print('📺 Broadcaster details List: $data');
      }
      if (data is List) {
        _broadcasterDetailsController.add(BroadcasterModel.fromListJson(data));
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
      // if (kDebugMode) {
      //   print('� Get rooms response: $data');
      // }
      if (data is List) {
        _getRoomsController.add(GetRoomModel.listFromJson(data));
      }
    });

    _socket!.on('sent-message', (data) {
      if (kDebugMode) {
        print('💬 Sent message response: $data');
      }
      if (data is Map<String, dynamic>) {
        _sentMessageController.add(ChatModel.fromJson(data));
      }
    });

    // Sent Gift events
    _socket!.on('sent-gift', (data) {
      if (kDebugMode) {
        print('🎁 Sent gift response: $data');
      }
      if (data is Map<String, dynamic>) {
        _sentGiftController.add(GiftModel.fromJson(data));
      }
    });

    //Ban User events
    _socket!.on('ban-user', (data) {
      if (kDebugMode) {
        print('🚫 Ban user response: $data');
      }
      if (data is Map<String, dynamic>) {
        _bannedUserController.add(BanUserModel.fromJson(data));
      }
    });

    //Make admin
    _socket!.on('make-admin', (data) {
      if (kDebugMode) {
        print('👑 Make admin response: $data');
      }
      if (data is Map<String, dynamic>) {
        _adminDetailsController.add(AdminDetailsModel.fromJson(data));
      }
    });

    //Banned List
    _socket!.on('banned-list', (data) {
      if (kDebugMode) {
        print('🚫 Banned list response: $data');
      }
      if (data is List) {
        _bannedListController.add(List<String>.from(data));
      }
    });

    //Mute User
    _socket!.on('mute-user', (data) {
      if (kDebugMode) {
        print('🔇 Mute user response: $data');
      }
      if (data is Map<String, dynamic>) {
        _muteUserController.add(MuteUserModel.fromJson(data));
      }
    });
  }

  /// Create a new room
  Future<bool> createRoom(
    String roomId,
    String title,
    RoomType roomType,
  ) async {
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
        'roomType': roomType
            .toString()
            .split('.')
            .last, // Convert enum to string
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
      if (kDebugMode) {
        print(
          '❌ Socket not connected. isConnected: $_isConnected, socket: ${_socket != null}',
        );
      }
      _errorMessageController.add({
        'status': 'error',
        'message': 'Socket not connected',
      });
      return false;
    }

    try {
      if (kDebugMode) {
        print('📋 Getting rooms list from socket');
      }

      // Emit the request
      _socket!.emit(_getRoomsEvent, {});

      // Give socket time to send and receive response
      await Future.delayed(const Duration(milliseconds: 500));

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
