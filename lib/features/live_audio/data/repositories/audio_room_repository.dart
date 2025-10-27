import 'dart:async';
import 'package:dlstarlive/features/live_audio/data/models/audio_member_model.dart';
import 'package:injectable/injectable.dart';
import '../models/audio_room_details.dart';
import '../models/chat_model.dart';
import '../../service/socket_service_audio.dart';

/// Repository for Audio Room operations
/// Abstracts the socket service and provides a clean interface for the bloc
@injectable
class AudioRoomRepository {
  final AudioSocketService _socketService;
  AudioRoomRepository(this._socketService);

  /// Connection status stream
  Stream<bool> get connectionStatusStream => _socketService.connectionStatusStream;

  /// Room streams
  Stream<List<AudioRoomDetails>> get getAllRoomsStream => _socketService.getAllRoomsStream;
  Stream<AudioRoomDetails?> get audioRoomDetailsStream => _socketService.audioRoomDetailsStream;
  Stream<AudioRoomDetails> get createRoomStream => _socketService.createRoomStream;
  Stream<List<String>> get closeRoomStream => _socketService.closeRoomStream;
  Stream<AudioMember> get joinRoomStream => _socketService.joinRoomStream;
  Stream<AudioRoomDetails> get leaveRoomStream => _socketService.leaveRoomStream;

  /// User streams
  Stream<dynamic> get userLeftStream => _socketService.userLeftStream;

  /// Seat streams
  Stream<dynamic> get joinSeatStream => _socketService.joinSeatStream;
  Stream<dynamic> get leaveSeatStream => _socketService.leaveSeatStream;
  Stream<dynamic> get removeFromSeatStream => _socketService.removeFromSeatStream;

  /// Chat streams
  Stream<AudioChatModel> get sendMessageStream => _socketService.sendMessageStream;

  /// User management streams
  Stream<dynamic> get muteUnmuteUserStream => _socketService.muteUnmuteUserStream;
  Stream<dynamic> get banUserStream => _socketService.banUserStream;
  Stream<dynamic> get unbanUserStream => _socketService.unbanUserStream;

  /// Error stream
  Stream<Map<String, dynamic>> get errorMessageStream => _socketService.errorMessageStream;

  /// Getters
  bool get isConnected => _socketService.isConnected;
  String? get currentUserId => _socketService.currentUserId;
  String? get currentRoomId => _socketService.currentRoomId;

  /// Connection methods
  Future<bool> connect(String userId) => _socketService.connect(userId);
  Future<void> disconnect() => _socketService.disconnect();
  Future<bool> reconnect() => _socketService.reconnect();

  /// Room operations
  Future<bool> createRoom(String roomId, String title, {int numberOfSeats = 8}) =>
      _socketService.createRoom(roomId, title, numberOfSeats: numberOfSeats);

  Future<bool> joinRoom(String roomId) => _socketService.joinRoom(roomId);
  Future<bool> leaveRoom(String roomId) => _socketService.leaveRoom(roomId);
  Future<bool> deleteRoom(String roomId) => _socketService.deleteRoom(roomId);
  Future<bool> getRooms() => _socketService.getRooms();
  Future<AudioRoomDetails?> getRoomDetails(String roomId) => _socketService.getRoomDetails(roomId);

  /// Seat operations
  Future<bool> joinSeat({required String roomId, required String seatKey, required String targetId}) =>
      _socketService.joinSeat(roomId: roomId, seatKey: seatKey, targetId: targetId);

  Future<bool> leaveSeat({required String roomId, required String seatKey, required String targetId}) =>
      _socketService.leaveSeat(roomId: roomId, seatKey: seatKey, targetId: targetId);

  Future<bool> removeFromSeat({required String roomId, required String seatKey, required String targetId}) =>
      _socketService.removeFromSeat(roomId: roomId, seatKey: seatKey, targetId: targetId);

  /// Chat operations
  Future<bool> sendMessage(String roomId, String message) => _socketService.sendMessage(roomId, message);

  /// User operations
  Future<bool> banUser(String userId) => _socketService.banUser(userId);
  Future<bool> unbanUser(String userId) => _socketService.unbanUser(userId);
  Future<bool> muteUnmuteUser(String userId) => _socketService.muteUnmuteUser(userId);

  /// Dispose all subscriptions
  void dispose() {
    _socketService.dispose();
  }
}
