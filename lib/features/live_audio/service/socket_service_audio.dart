import 'dart:async';
import 'package:injectable/injectable.dart';

import '../../../core/network/models/ban_user_model.dart';
import '../../../core/network/models/left_user_model.dart';
import '../../../core/network/models/mute_user_model.dart';
import '../data/models/audio_room_details.dart';
import '../data/models/chat_model.dart';
import '../data/models/joined_seat.dart';
import 'connection_manager.dart';
import 'socket_event_handler.dart';
import 'audio_room_operations.dart';
import 'audio_seat_operations.dart';
import 'audio_user_operations.dart';
import 'socket_constants.dart';

/// Comprehensive Socket Service for Audio Live Streaming
/// Handles all socket operations including room management and real-time events
/// Uses composition pattern with specialized operation classes
@injectable
class AudioSocketService {
  // Remove static instance and singleton pattern
  // static AudioSocketService? _instance;

  // Specialized operation classes
  late final AudioSocketConnectionManager _connectionManager;
  late final AudioSocketEventHandler _eventHandler;
  late final AudioSocketRoomOperations _roomOperations;
  late final AudioSocketSeatOperations _seatOperations;
  late final AudioSocketUserOperations _userOperations;

  // Error handling
  late final StreamController<Map<String, dynamic>> _errorController;

  /// Remove singleton instance getter
  // static AudioSocketService get instance {
  //   _instance ??= AudioSocketService._internal();
  //   return _instance!;
  // }

  /// Public constructor for dependency injection
  AudioSocketService() {
    _initializeComponents();
  }

  /// Remove private constructor
  // AudioSocketService._internal() {
  //   _initializeComponents();
  // }

  void _initializeComponents() {
    // Initialize connection manager first
    _connectionManager = AudioSocketConnectionManager();

    // Initialize error controller
    _errorController = StreamController<Map<String, dynamic>>.broadcast();

    // Initialize room operations
    _roomOperations = AudioSocketRoomOperations(_errorController, null);

    // Initialize event handler with room operations
    _eventHandler = AudioSocketEventHandler(_errorController, _roomOperations);

    // Set event handler reference in room operations for refresh calls
    _roomOperations.setEventHandler(_eventHandler);

    // Initialize other operation classes
    _seatOperations = AudioSocketSeatOperations(_errorController);

    _userOperations = AudioSocketUserOperations(_errorController, () => _connectionManager.currentRoomId);

    // Setup listeners after all components are initialized
    // _eventHandler.setupListeners(); // Moved to connect method
  }

  /// Stream getters for listening to events
  Stream<List<AudioRoomDetails>> get getAllRoomsStream => _eventHandler.getAllRoomsStream;
  Stream<AudioRoomDetails?> get audioRoomDetailsStream => _eventHandler.audioRoomDetailsStream;
  // Room events
  Stream<AudioRoomDetails> get createRoomStream => _eventHandler.createRoomStream;
  Stream<List<String>> get closeRoomStream => _eventHandler.closeRoomStream;
  Stream<AudioRoomDetails> get joinRoomStream => _eventHandler.joinRoomStream;
  Stream<AudioRoomDetails> get leaveRoomStream => _eventHandler.leaveRoomStream;
  // User events
  Stream<LeftUserModel> get userLeftStream => _eventHandler.userLeftStream;
  // Seat events
  Stream<JoinedSeatModel> get joinSeatStream => _eventHandler.joinSeatStream;
  Stream<JoinedSeatModel> get leaveSeatStream => _eventHandler.leaveSeatStream;
  Stream<JoinedSeatModel> get removeFromSeatStream => _eventHandler.removeFromSeatStream;
  // Chat events
  Stream<AudioChatModel> get sendMessageStream => _eventHandler.sendMessageStream;
  // Error events
  Stream<Map<String, dynamic>> get errorMessageStream => _eventHandler.errorMessageStream;
  // User events
  Stream<MuteUserModel> get muteUnmuteUserStream => _eventHandler.muteUnmuteUserStream;
  Stream<BanUserModel> get banUserStream => _eventHandler.banUserStream;
  Stream<BanUserModel> get unbanUserStream => _eventHandler.unbanUserStream;

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
      _eventHandler.setSocket(socket);
      _seatOperations.setSocket(socket);
      _userOperations.setSocket(socket);

      // Setup listeners after socket is set
      _eventHandler.setupListeners();

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

  Future<bool> deleteRoom(String roomId) => _roomOperations.deleteRoom(roomId);

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
  Future<bool> joinSeat({required String roomId, required String seatKey, required String targetId}) =>
      _seatOperations.joinSeat(roomId: roomId, seatKey: seatKey, targetId: targetId);

  Future<bool> leaveSeat({required String roomId, required String seatKey, required String targetId}) =>
      _seatOperations.leaveSeat(roomId: roomId, seatKey: seatKey, targetId: targetId);

  Future<bool> removeFromSeat({required String roomId, required String seatKey, required String targetId}) =>
      _seatOperations.removeFromSeat(roomId: roomId, seatKey: seatKey, targetId: targetId);

  /// User operations
  Future<bool> banUser(String userId) => _userOperations.banUser(userId);

  Future<bool> unbanUser(String userId) => _userOperations.unbanUser(userId);

  Future<bool> muteUnmuteUser(String userId) => _userOperations.muteUnmuteUser(userId);

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
    _eventHandler.dispose();
    _errorController.close();
    // Remove _instance = null;
  }
}
