import 'dart:async';
import 'package:dlstarlive/core/network/models/gift_model.dart';
import 'package:dlstarlive/features/live_audio/data/models/audio_member_model.dart';
import 'package:injectable/injectable.dart';

import '../../../core/network/models/mute_user_model.dart';
import '../data/models/audio_room_details.dart';
import '../data/models/chat_model.dart';
import '../data/models/joined_seat.dart';
import 'socket_connection_manager.dart';
import 'socket_event_listeners.dart';
import 'audio_room_operations.dart';
import 'audio_seat_operations.dart';
import 'audio_user_operations.dart';
import 'socket_constants.dart';

/// Comprehensive Socket Service for Audio Live Streaming
/// Handles all socket operations including room management and real-time events
/// Uses composition pattern with specialized operation classes
@lazySingleton
class AudioSocketService {
  // Specialized operation classes
  late final AudioSocketConnectionManager _connectionManager;
  late final AudioSocketEventListeners _eventListeners;
  late final AudioSocketRoomOperations _roomOperations;
  late final AudioSocketSeatOperations _seatOperations;
  late final AudioSocketUserOperations _userOperations;

  // Error handling
  late final StreamController<Map<String, dynamic>> _errorController;

  /// Public constructor for dependency injection
  AudioSocketService() {
    _initializeComponents();
  }

  void _initializeComponents() {
    // Initialize connection manager first
    _connectionManager = AudioSocketConnectionManager();
    // Initialize error controller
    _errorController = StreamController<Map<String, dynamic>>.broadcast();
    // Initialize room operations
    _roomOperations = AudioSocketRoomOperations(_errorController, null);
    // Initialize event handler with room operations and current user ID callback
    _eventListeners = AudioSocketEventListeners(
      _errorController,
      _roomOperations,
      () => _connectionManager.currentUserId,
    );
    // Set event handler reference in room operations for refresh calls
    _roomOperations.setEventHandler(_eventListeners);
    // Initialize other operation classes
    _seatOperations = AudioSocketSeatOperations(_errorController);
    _userOperations = AudioSocketUserOperations(_errorController, () => _connectionManager.currentRoomId);
  }

  /// Stream getters for listening to events
  Stream<List<AudioRoomDetails>> get getAllRoomsStream => _eventListeners.getAllRoomsStream;
  Stream<AudioRoomDetails?> get audioRoomDetailsStream => _eventListeners.audioRoomDetailsStream;
  // Room events
  Stream<AudioRoomDetails> get createRoomStream => _eventListeners.createRoomStream;
  Stream<List<String>> get closeRoomStream => _eventListeners.closeRoomStream;
  Stream<AudioMember> get joinRoomStream => _eventListeners.joinRoomStream;
  Stream<AudioRoomDetails> get leaveRoomStream => _eventListeners.leaveRoomStream;
  // User events
  Stream<String> get userLeftStream => _eventListeners.userLeftStream;
  // Seat events
  Stream<JoinedSeatModel> get joinSeatStream => _eventListeners.joinSeatStream;
  Stream<JoinedSeatModel> get leaveSeatStream => _eventListeners.leaveSeatStream;
  Stream<JoinedSeatModel> get removeFromSeatStream => _eventListeners.removeFromSeatStream;
  Stream<Map<String, dynamic>> get lockUnlockSeatStream => _eventListeners.lockUnlockSeatStream;
  // Chat events
  Stream<AudioChatModel> get sendMessageStream => _eventListeners.sendMessageStream;
  // Error events
  Stream<Map<String, dynamic>> get errorMessageStream => _eventListeners.errorMessageStream;
  // User events
  Stream<MuteUserModel> get muteUnmuteUserStream => _eventListeners.muteUnmuteUserStream;
  Stream<List<String>> get banUserStream => _eventListeners.banUserStream;
  // Host bonus events
  Stream<int> get updateHostBonusStream => _eventListeners.updateHostBonusStream;
  // Sent audio gifts events
  Stream<GiftModel> get sentAudioGiftsStream => _eventListeners.sentAudioGiftsStream;
  // Sent audio emoji events
  Stream<dynamic> get recievedAudioEmojiStream => _eventListeners.recievedAudioEmojiStream;
  // Muted users stream
  Stream<String> get mutedUserIdStream => _eventListeners.mutedUserIdStream;

  /// Connection status stream
  Stream<bool> get connectionStatusStream => _connectionManager.connectionStatusStream;

  /// Getters
  bool get isConnected => _connectionManager.isConnected;
  String? get currentUserId => _connectionManager.currentUserId;
  String? get currentRoomId => _connectionManager.currentRoomId;

  /// Initialize and connect to socket
  Future<bool> connect(String userId) async {
    final result = await _connectionManager.connect(userId);
    if (result) {
      // Set the socket in all operations
      final socket = _connectionManager.socket!;
      _roomOperations.setSocket(socket);
      _eventListeners.setSocket(socket);
      _seatOperations.setSocket(socket);
      _userOperations.setSocket(socket);

      // Setup listeners after socket is set
      _eventListeners.setupListeners();

      // Update room operations with current room ID
      _connectionManager.setCurrentRoomId(_connectionManager.currentRoomId);
    }
    return result;
  }

  /// Disconnect from socket
  Future<void> disconnect() => _connectionManager.disconnect();

  /// Reconnect if disconnected
  Future<bool> reconnect() => _connectionManager.reconnect();

  /// Check if socket is healthy
  bool get isHealthy => _connectionManager.isHealthy;

  /// Room operations
  Future<bool> createRoom(
    String roomId,
    String title, {
    int numberOfSeats = AudioSocketConstants.defaultNumberOfSeats,
  }) {
    final result = _roomOperations.createRoom(roomId, title, numberOfSeats: numberOfSeats);
    result.then((success) {
      if (success) {
        _connectionManager.setCurrentRoomId(roomId);
      }
    });
    return result;
  }

  Future<bool> joinRoom(String roomId) {
    final result = _roomOperations.joinRoom(roomId);
    result.then((success) {
      if (success) {
        _connectionManager.setCurrentRoomId(roomId);
      }
    });
    return result;
  }

  Future<bool> leaveRoom(String roomId) {
    final result = _roomOperations.leaveRoom(roomId);
    result.then((success) {
      if (success) {
        _connectionManager.setCurrentRoomId(null);
      }
    });
    return result;
  }

  Future<bool> getRooms() => _roomOperations.getRooms();

  Future<AudioRoomDetails?> getRoomDetails(String roomId) => _roomOperations.getRoomDetails(roomId);

  Future<bool> sendMessage(String roomId, String message) => _roomOperations.sendMessage(roomId, message);

  /// Seat operations
  void joinSeat({required String roomId, required String seatKey, required String targetId}) =>
      _seatOperations.joinSeat(roomId: roomId, seatKey: seatKey, targetId: targetId);

  void leaveSeat({required String roomId, required String seatKey, required String targetId}) =>
      _seatOperations.leaveSeat(roomId: roomId, seatKey: seatKey, targetId: targetId);

  Future<bool> removeFromSeat({required String roomId, required String seatKey, required String targetId}) =>
      _seatOperations.removeFromSeat(roomId: roomId, seatKey: seatKey, targetId: targetId);

  Future<bool> muteUserFromSeat({required String roomId, required String seatKey, required String targetId}) =>
      _seatOperations.muteUserFromSeat(roomId: roomId, seatKey: seatKey, targetId: targetId);

  Future<bool> lockUnlockSeat({required String roomId, required String seatKey}) =>
      _seatOperations.lockUnlockSeat(roomId: roomId, seatKey: seatKey);

  Future<bool> sendAudioEmoji({required String roomId, required String seatKey, required String emoji}) =>
      _seatOperations.sendAudioEmoji(roomId: roomId, seatKey: seatKey, emoji: emoji);

  /// User operations
  Future<bool> banUser(String targetUserId) => _userOperations.banUser(targetUserId);

  Future<bool> muteUnmuteUser(String targetUserId) => _userOperations.muteUnmuteUser(targetUserId);

  /// Send custom event
  void emit(String event, [dynamic data]) {
    if (!_connectionManager.isConnected || _connectionManager.socket == null) {
      _errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return;
    }

    try {
      if (data != null) {
        _connectionManager.socket!.emit(event, data);
      } else {
        _connectionManager.socket!.emit(event);
      }
    } catch (e) {
      _errorController.add({'status': 'error', 'message': 'Failed to emit event: $e'});
    }
  }

  /// Listen to custom events
  void on(String event, Function(dynamic) callback) {
    if (_connectionManager.socket == null) {
      _errorController.add({'status': 'error', 'message': 'Socket not initialized'});
      return;
    }
    _connectionManager.socket!.on(event, callback);
  }

  /// Remove event listener
  void off(String event) {
    if (_connectionManager.socket == null) return;
    _connectionManager.socket!.off(event);
  }

  /// Dispose all resources
  void dispose() {
    _connectionManager.dispose();
    _eventListeners.dispose();
    _errorController.close();
  }
}
