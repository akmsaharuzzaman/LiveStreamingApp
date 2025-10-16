import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../core/network/models/ban_user_model.dart';
import '../../../core/network/models/joined_user_model.dart';
import '../../../core/network/models/left_user_model.dart';
import '../../../core/network/models/mute_user_model.dart';
import '../models/audio_room_details.dart';
import '../models/chat_model.dart';
import '../models/seat_model.dart';
import 'socket_constants.dart';
import 'audio_room_operations.dart';

/// Handles socket event listeners and stream controllers
class AudioSocketEventHandler {
  late IO.Socket socket;
  final StreamController<Map<String, dynamic>> errorController;
  final AudioSocketRoomOperations? roomOperations;

  // Stream controllers for audio events
  final StreamController<List<AudioRoomDetails>> _getAllRoomsController = StreamController<List<AudioRoomDetails>>.broadcast();
  final StreamController<AudioRoomDetails?> _audioRoomDetailsController = StreamController<AudioRoomDetails?>.broadcast();
  final StreamController<AudioRoomDetails> _createRoomController = StreamController<AudioRoomDetails>.broadcast();
  final StreamController<List<String>> _closeRoomController = StreamController<List<String>>.broadcast();
  final StreamController<AudioRoomDetails> _joinRoomController = StreamController<AudioRoomDetails>.broadcast();
  final StreamController<AudioRoomDetails> _leaveRoomController = StreamController<AudioRoomDetails>.broadcast();
  final StreamController<LeftUserModel> _userLeftController = StreamController<LeftUserModel>.broadcast();
  final StreamController<JoinedUserModel> _joinSeatRequestController = StreamController<JoinedUserModel>.broadcast();
  final StreamController<SeatModel> _leaveSeatRequestController = StreamController<SeatModel>.broadcast();
  final StreamController<SeatModel> _removeFromSeatController = StreamController<SeatModel>.broadcast();
  final StreamController<AudioChatModel> _sendMessageController = StreamController<AudioChatModel>.broadcast();
  final StreamController<MuteUserModel> _muteUnmuteUserController = StreamController<MuteUserModel>.broadcast();
  final StreamController<BanUserModel> _banUserController = StreamController<BanUserModel>.broadcast();
  final StreamController<BanUserModel> _unbanUserController = StreamController<BanUserModel>.broadcast();

  AudioSocketEventHandler(this.errorController, this.roomOperations);

  void setSocket(IO.Socket socket) {
    this.socket = socket;
  }

  void _log(String message) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';

    if (kDebugMode) {
      debugPrint('\n$yellow[AUDIO_ROOM] : Event - $reset $message\n');
    }
  }

  /// Stream getters
  Stream<List<AudioRoomDetails>> get getAllRoomsStream => _getAllRoomsController.stream;
  Stream<AudioRoomDetails?> get audioRoomDetailsStream => _audioRoomDetailsController.stream;
  Stream<AudioRoomDetails> get createRoomStream => _createRoomController.stream;
  Stream<List<String>> get closeRoomStream => _closeRoomController.stream;
  Stream<AudioRoomDetails> get joinRoomStream => _joinRoomController.stream;
  Stream<AudioRoomDetails> get leaveRoomStream => _leaveRoomController.stream;
  Stream<LeftUserModel> get userLeftStream => _userLeftController.stream;
  Stream<JoinedUserModel> get joinSeatRequestStream => _joinSeatRequestController.stream;
  Stream<SeatModel> get leaveSeatRequestStream => _leaveSeatRequestController.stream;
  Stream<SeatModel> get removeFromSeatStream => _removeFromSeatController.stream;
  Stream<AudioChatModel> get sendMessageStream => _sendMessageController.stream;
  Stream<Map<String, dynamic>> get errorMessageStream => errorController.stream;
  Stream<MuteUserModel> get muteUnmuteUserStream => _muteUnmuteUserController.stream;
  Stream<BanUserModel> get banUserStream => _banUserController.stream;
  Stream<BanUserModel> get unbanUserStream => _unbanUserController.stream;

  /// Setup all socket event listeners
  void setupListeners() {
    _log('🔧 Setting up Audio socket listeners');

    // Clear any existing listeners to prevent duplicates
    _clearListeners();

    // Connection events
    socket.onReconnect((_) {
      _log('🔄 Audio Socket reconnected');
    });

    socket.onReconnectError((error) {
      _log('❌ Audio Socket reconnection error: $error');
      errorController.add({'status': 'error', 'message': 'Reconnection failed: $error'});
    });

    // Audio room specific events
    socket.on(AudioSocketConstants.errorMessageEvent, _handleErrorMessage);
    socket.on(AudioSocketConstants.createRoomEvent, _handleCreateRoom);
    socket.on(AudioSocketConstants.joinAudioRoomEvent, _handleJoinRoom);
    socket.on(AudioSocketConstants.userLeftEvent, _handleUserLeft);
    socket.on(AudioSocketConstants.leaveAudioRoomEvent, _handleLeaveRoom);
    socket.on(AudioSocketConstants.removeFromSeatEvent, _handleRemoveFromSeat);
    socket.on(AudioSocketConstants.audioRoomDetailsEvent, _handleAudioRoomDetails);
    socket.on(AudioSocketConstants.getAllRoomsEvent, _handleGetAllRooms);
    socket.on(AudioSocketConstants.sendMessageEvent, _handleSendMessage);
    socket.on(AudioSocketConstants.banUserEvent, _handleBanUser);
    socket.on(AudioSocketConstants.muteUnmuteUserEvent, _handleMuteUnmuteUser);
  }

  /// Clear all event listeners
  void _clearListeners() {
    socket.off(AudioSocketConstants.getAllRoomsEvent);
    socket.off(AudioSocketConstants.audioRoomDetailsEvent);
    socket.off(AudioSocketConstants.createRoomEvent);
    socket.off(AudioSocketConstants.joinAudioRoomEvent);
    socket.off(AudioSocketConstants.leaveAudioRoomEvent);
    socket.off(AudioSocketConstants.userLeftEvent);
    socket.off(AudioSocketConstants.joinSeatRequestEvent);
    socket.off(AudioSocketConstants.leaveSeatRequestEvent);
    socket.off(AudioSocketConstants.removeFromSeatEvent);
    socket.off(AudioSocketConstants.sendMessageEvent);
    socket.off(AudioSocketConstants.errorMessageEvent);
    socket.off(AudioSocketConstants.muteUnmuteUserEvent);
    socket.off(AudioSocketConstants.banUserEvent);
    socket.off(AudioSocketConstants.unbanUserEvent);
  }

  void _handleErrorMessage(dynamic data) {
    _log('❌ Audio Error message: $data');
    if (data is Map<String, dynamic>) {
      errorController.add(data);
    }
  }

  void _handleCreateRoom(dynamic data) {
    _log('🏠 Audio room created: $data');
    if (data is Map<String, dynamic>) {
      _createRoomController.add(AudioRoomDetails.fromJson(data));
      // Refresh room list after room creation
      roomOperations?.refreshRoomList();
    }
  }

  void _handleJoinRoom(dynamic data) {
    _log('🚪 User joined audio room: $data');
    if (data is Map<String, dynamic>) {
      _joinRoomController.add(AudioRoomDetails.fromJson(data));
      // Refresh room list after user joins
      roomOperations?.refreshRoomList();
    }
  }

  void _handleUserLeft(dynamic data) {
    _log('👋 Audio user left: $data');
    if (data is Map<String, dynamic>) {
      _userLeftController.add(LeftUserModel.fromJson(data));
      // Refresh room list after user leaves
      roomOperations?.refreshRoomList();
    }
  }

  void _handleLeaveRoom(dynamic data) {
    _log('🚪 Audio room left/deleted: $data');
    if (data is Map<String, dynamic>) {
      _leaveRoomController.add(AudioRoomDetails.fromJson(data));
      // Refresh room list after room is left/deleted
      roomOperations?.refreshRoomList();
    }
  }

  void _handleRemoveFromSeat(dynamic data) {
    _log('🚫 Remove from seat: $data');
    if (data is Map<String, dynamic>) {
      _removeFromSeatController.add(SeatModel.fromJson(data));
    }
  }

  void _handleAudioRoomDetails(dynamic data) {
    _log('📺 Audio room details response received');
    _log('📺 Raw response: $data');

    try {
      if (data is Map<String, dynamic>) {
        // Check if this is a room closure notification
        if (data['success'] == true && data['message'] == 'Room has been closed by the host' && data['data'] is Map && (data['data'] as Map).isEmpty) {
          _log('🏠 Room has been closed by the host - notifying listeners');
          _audioRoomDetailsController.add(null);
          return;
        }

        // Normal room details response
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          final roomData = data['data'] as Map<String, dynamic>;

          // Check if room doesn't exist (roomId is null)
          if (roomData['roomId'] == null) {
            _log('🏠 Room does not exist - notifying listeners');
            _audioRoomDetailsController.add(null);
            return;
          }

          final roomDetails = AudioRoomDetails.fromJson(roomData);
          _log('✅ Parsed room details for: ${roomDetails.roomId}');
          _audioRoomDetailsController.add(roomDetails);
        } else {
          _log('❌ Invalid room details response format');
        }
      } else {
        _log('❌ Room details response is not a Map');
      }
    } catch (e, stackTrace) {
      _log('💥 Error processing room details response: $e');
      _log('💥 Stack trace: $stackTrace');
    }
  }

  void _handleGetAllRooms(dynamic data) {
    _log('🏠 Get all audio rooms response received');
    _log('🏠 Raw data type: ${data.runtimeType}');
    _log('🏠 Raw data: $data');

    try {
      if (data is List) {
        _log('✅ Data is List with ${data.length} items');
        final rooms = data.map((room) => AudioRoomDetails.fromJson(room as Map<String, dynamic>)).toList();
        _log('✅ Successfully parsed ${rooms.length} rooms');
        _getAllRoomsController.add(rooms);
      } else if (data is Map<String, dynamic>) {
        _log('📦 Data is Map, checking for data key...');
        if (data.containsKey('data')) {
          final roomsData = data['data'];
          _log('📦 Found data key, type: ${roomsData.runtimeType}');
          if (roomsData is List) {
            _log('✅ Data.data is List with ${roomsData.length} items');
            final rooms = roomsData.map((room) => AudioRoomDetails.fromJson(room as Map<String, dynamic>)).toList();
            _log('✅ Successfully parsed ${rooms.length} rooms from data field');
            _getAllRoomsController.add(rooms);
          } else {
            _log('❌ Invalid audio rooms data format: data field is not a List, got: ${roomsData.runtimeType}');
          }
        } else {
          _log('❌ Map does not contain data key. Available keys: ${data.keys}');
        }
      } else {
        _log('❌ Invalid audio rooms response format: expected List or Map, got ${data.runtimeType}');
      }
    } catch (e, stackTrace) {
      _log('💥 Error processing audio rooms response: $e');
      _log('💥 Stack trace: $stackTrace');
      _log('💥 Raw data that caused error: $data');
    }
  }

  void _handleSendMessage(dynamic data) {
    _log('💬 Audio message response: ${data['message']}');
    try {
      if (data is Map<String, dynamic>) {
        _sendMessageController.add(AudioChatModel.fromJson(data['data']));
      }
    } catch (e) {
      _log('❌ Audio message response error: $e');
    }
  }

  void _handleBanUser(dynamic data) {
    _log('🚫 Ban audio user response: $data');
    if (data is Map<String, dynamic>) {
      _banUserController.add(BanUserModel.fromJson(data));
    }
  }

  void _handleMuteUnmuteUser(dynamic data) {
    _log('🔇 Audio mute/unmute user response: $data');
    if (data is Map<String, dynamic>) {
      _muteUnmuteUserController.add(MuteUserModel.fromJson(data));
    }
  }

  /// Dispose all stream controllers
  void dispose() {
    _getAllRoomsController.close();
    _audioRoomDetailsController.close();
    _createRoomController.close();
    _closeRoomController.close();
    _joinRoomController.close();
    _leaveRoomController.close();
    _userLeftController.close();
    _joinSeatRequestController.close();
    _leaveSeatRequestController.close();
    _removeFromSeatController.close();
    _sendMessageController.close();
    _muteUnmuteUserController.close();
    _banUserController.close();
    _unbanUserController.close();
  }
}
