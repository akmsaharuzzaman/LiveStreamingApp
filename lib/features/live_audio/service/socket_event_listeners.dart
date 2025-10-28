import 'dart:async';
import 'package:dlstarlive/features/live_audio/data/models/audio_member_model.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../../../core/network/models/ban_user_model.dart';
import '../../../core/network/models/left_user_model.dart';
import '../../../core/network/models/mute_user_model.dart';
import '../data/models/audio_room_details.dart';
import '../data/models/chat_model.dart';
import '../data/models/joined_seat.dart';
import 'socket_constants.dart';
import 'audio_room_operations.dart';

/// Handles socket event listeners and stream controllers
class AudioSocketEventListeners {
  late socket_io.Socket socket;
  final StreamController<Map<String, dynamic>> errorController;
  final AudioSocketRoomOperations? roomOperations;

  // Stream controllers for audio events
  final StreamController<List<AudioRoomDetails>> _getAllRoomsController =
      StreamController<List<AudioRoomDetails>>.broadcast();
  final StreamController<AudioRoomDetails?> _audioRoomDetailsController =
      StreamController<AudioRoomDetails?>.broadcast();
  // Room events
  final StreamController<AudioRoomDetails> _createRoomController = StreamController<AudioRoomDetails>.broadcast();
  final StreamController<List<String>> _closeRoomController = StreamController<List<String>>.broadcast();
  final StreamController<AudioMember> _joinRoomController = StreamController<AudioMember>.broadcast();
  final StreamController<AudioRoomDetails> _leaveRoomController = StreamController<AudioRoomDetails>.broadcast();
  // User events
  final StreamController<LeftUserModel> _userLeftController = StreamController<LeftUserModel>.broadcast();
  // Seat events
  final StreamController<JoinedSeatModel> _joinSeatController = StreamController<JoinedSeatModel>.broadcast();
  final StreamController<JoinedSeatModel> _leaveSeatController = StreamController<JoinedSeatModel>.broadcast();
  final StreamController<JoinedSeatModel> _removeFromSeatController = StreamController<JoinedSeatModel>.broadcast();
  // Chat events
  final StreamController<AudioChatModel> _sendMessageController = StreamController<AudioChatModel>.broadcast();
  // User events
  final StreamController<MuteUserModel> _muteUnmuteUserController = StreamController<MuteUserModel>.broadcast();
  final StreamController<BanUserModel> _banUserController = StreamController<BanUserModel>.broadcast();
  final StreamController<BanUserModel> _unbanUserController = StreamController<BanUserModel>.broadcast();

  AudioSocketEventListeners(this.errorController, this.roomOperations);

  void setSocket(socket_io.Socket socket) {
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
  // Room events
  Stream<AudioRoomDetails> get createRoomStream => _createRoomController.stream;
  Stream<List<String>> get closeRoomStream => _closeRoomController.stream;
  Stream<AudioMember> get joinRoomStream => _joinRoomController.stream;
  Stream<AudioRoomDetails> get leaveRoomStream => _leaveRoomController.stream;
  // User events
  Stream<LeftUserModel> get userLeftStream => _userLeftController.stream;
  // Seat events
  Stream<JoinedSeatModel> get joinSeatStream => _joinSeatController.stream;
  Stream<JoinedSeatModel> get leaveSeatStream => _leaveSeatController.stream;
  Stream<JoinedSeatModel> get removeFromSeatStream => _removeFromSeatController.stream;
  // Chat events
  Stream<AudioChatModel> get sendMessageStream => _sendMessageController.stream;
  // Error events
  Stream<Map<String, dynamic>> get errorMessageStream => errorController.stream;
  // User events
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
    socket.on(AudioSocketConstants.joinSeatEvent, _handleJoinSeat);
    socket.on(AudioSocketConstants.leaveSeatEvent, _handleLeaveSeat);
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
    socket.off(AudioSocketConstants.joinSeatEvent);
    socket.off(AudioSocketConstants.leaveSeatEvent);
    socket.off(AudioSocketConstants.removeFromSeatEvent);
    socket.off(AudioSocketConstants.sendMessageEvent);
    socket.off(AudioSocketConstants.errorMessageEvent);
    socket.off(AudioSocketConstants.muteUnmuteUserEvent);
    socket.off(AudioSocketConstants.banUserEvent);
    socket.off(AudioSocketConstants.unbanUserEvent);
  }

  void _handleGetAllRooms(dynamic data) {
    _log('🏠 Get all audio rooms listener response received');
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
      _log('💥 Error processing audio rooms listener response: $e');
      _log('💥 Stack trace: $stackTrace');
      _log('💥 Raw data that caused error: $data');
    }
  }

  void _handleAudioRoomDetails(dynamic data) {
    _log('📺 Audio room details listener response');
    _log('📺 Raw response: $data');

    try {
      if (data is Map<String, dynamic>) {
        // Check if this is a room closure notification
        if (data['success'] == true &&
            data['message'] == 'Room has been closed by the host' &&
            data['data'] is Map &&
            (data['data'] as Map).isEmpty) {
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
      _log('💥 Error processing room details listener response: $e');
      _log('💥 Stack trace: $stackTrace');
    }
  }

  void _handleCreateRoom(dynamic data) {
    _log('🏠 Audio room created listener response: $data');
    if (data is Map<String, dynamic>) {
      _createRoomController.add(AudioRoomDetails.fromJson(data));
      // Refresh room list after room creation
      roomOperations?.refreshRoomList();
    }
  }

  void _handleJoinRoom(dynamic data) {
    _log('🚪 User joined audio room listener response: $data');
    if (data is Map<String, dynamic>) {
      _joinRoomController.add(AudioMember.fromJson(data['data']));
      // Refresh room list after user joins
      roomOperations?.refreshRoomList();
    }
  }

  void _handleLeaveRoom(dynamic data) {
    _log('🚪 Audio room left/deleted listener response: $data');
    if (data is Map<String, dynamic>) {
      _leaveRoomController.add(AudioRoomDetails.fromJson(data));
      // Refresh room list after room is left/deleted
      roomOperations?.refreshRoomList();
    }
  }

  void _handleUserLeft(dynamic data) {
    _log('👋 Audio user left listener response: $data');
    if (data is Map<String, dynamic>) {
      _userLeftController.add(LeftUserModel.fromJson(data));
      // Refresh room list after user leaves
      roomOperations?.refreshRoomList();
    }
  }

  void _handleJoinSeat(dynamic data) {
    _log('🪑 Join seat listener response: $data');
    try {
      if (data is Map<String, dynamic>) {
        _joinSeatController.add(JoinedSeatModel.fromJson(data['data']));
      }
    } catch (e) {
      _log('🪑 Join seat listener error: $e');
    }
  }

  void _handleLeaveSeat(dynamic data) {
    _log('🪑 Leave seat listener response: $data');
    try {
      if (data is Map<String, dynamic>) {
        _leaveSeatController.add(JoinedSeatModel.fromJson(data['data']));
      }
    } catch (e) {
      _log('🪑 Leave seat listener error: $e');
    }
  }

  void _handleSendMessage(dynamic data) {
    _log('💬 Audio message listener response: ${data['message']}');
    try {
      if (data is Map<String, dynamic>) {
        _sendMessageController.add(AudioChatModel.fromJson(data['data']));
      }
    } catch (e) {
      _log('❌ Audio message listener response error: $e');
    }
  }

  void _handleErrorMessage(dynamic data) {
    _log('❌ Audio Error listener message: $data');
    if (data is Map<String, dynamic>) {
      errorController.add(data);
    }
  }

  void _handleBanUser(dynamic data) {
    _log('🚫 Ban audio user listener response: $data');
    if (data is Map<String, dynamic>) {
      _banUserController.add(BanUserModel.fromJson(data));
    }
  }

  void _handleMuteUnmuteUser(dynamic data) {
    _log('🔇 Audio mute/unmute user listener response: $data');
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
    _joinSeatController.close();
    _leaveSeatController.close();
    _removeFromSeatController.close();
    _sendMessageController.close();
    _muteUnmuteUserController.close();
    _banUserController.close();
    _unbanUserController.close();
  }
}
