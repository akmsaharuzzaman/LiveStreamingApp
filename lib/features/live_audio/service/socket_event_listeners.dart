import 'dart:async';
import 'package:dlstarlive/core/network/models/gift_model.dart';
import 'package:dlstarlive/features/live_audio/data/models/audio_member_model.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

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
  final String? Function()? getCurrentUserId;

  /// Stream controllers for audio events
  final StreamController<List<AudioRoomDetails>> _getAllRoomsController =
      StreamController<List<AudioRoomDetails>>.broadcast(); // 1
  final StreamController<AudioRoomDetails?> _audioRoomDetailsController =
      StreamController<AudioRoomDetails?>.broadcast(); // 2
  // Room events
  final StreamController<AudioRoomDetails> _createRoomController = StreamController<AudioRoomDetails>.broadcast(); // 3
  final StreamController<List<String>> _closeRoomController = StreamController<List<String>>.broadcast(); //
  final StreamController<AudioMember> _joinRoomController = StreamController<AudioMember>.broadcast(); // 4
  final StreamController<AudioRoomDetails> _leaveRoomController = StreamController<AudioRoomDetails>.broadcast(); // 5
  // User events
  final StreamController<String> _userLeftController = StreamController<String>.broadcast(); // 6
  // Seat events
  final StreamController<JoinedSeatModel> _joinSeatController = StreamController<JoinedSeatModel>.broadcast(); // 7
  final StreamController<JoinedSeatModel> _leaveSeatController = StreamController<JoinedSeatModel>.broadcast(); // 8
  final StreamController<JoinedSeatModel> _removeFromSeatController =
      StreamController<JoinedSeatModel>.broadcast(); // 9
  // Chat events
  final StreamController<AudioChatModel> _sendMessageController = StreamController<AudioChatModel>.broadcast(); // 10
  // User events
  final StreamController<MuteUserModel> _muteUnmuteUserController = StreamController<MuteUserModel>.broadcast(); // 12
  final StreamController<List<String>> _banUserController = StreamController<List<String>>.broadcast(); // 13
  // final StreamController<List<String>> _unbanUserController = StreamController<List<String>>.broadcast(); // 14
  // Host bonus events
  final StreamController<int> _updateHostBonusController = StreamController<int>.broadcast(); // 15
  // Sent audio gifts events
  final StreamController<GiftModel> _sentAudioGiftsController = StreamController<GiftModel>.broadcast(); // 16
  // Muted users stream
  final StreamController<String> _mutedUserIdController = StreamController<String>.broadcast();

  AudioSocketEventListeners(this.errorController, this.roomOperations, [this.getCurrentUserId]);

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
  Stream<List<AudioRoomDetails>> get getAllRoomsStream => _getAllRoomsController.stream; // 1
  Stream<AudioRoomDetails?> get audioRoomDetailsStream => _audioRoomDetailsController.stream; // 2
  Stream<AudioRoomDetails> get createRoomStream => _createRoomController.stream; // 3 - Room events
  Stream<List<String>> get closeRoomStream => _closeRoomController.stream; //
  Stream<AudioMember> get joinRoomStream => _joinRoomController.stream; // 4
  Stream<AudioRoomDetails> get leaveRoomStream => _leaveRoomController.stream; // 5
  Stream<String> get userLeftStream => _userLeftController.stream; // 6 - User events
  Stream<JoinedSeatModel> get joinSeatStream => _joinSeatController.stream; // 7 - Seat events
  Stream<JoinedSeatModel> get leaveSeatStream => _leaveSeatController.stream; // 8
  Stream<JoinedSeatModel> get removeFromSeatStream => _removeFromSeatController.stream; // 9
  Stream<AudioChatModel> get sendMessageStream => _sendMessageController.stream; // 10 - Chat events
  Stream<Map<String, dynamic>> get errorMessageStream => errorController.stream; // 11 - Error events
  Stream<MuteUserModel> get muteUnmuteUserStream => _muteUnmuteUserController.stream; // 12 - User events
  Stream<List<String>> get banUserStream => _banUserController.stream; // 13
  // Stream<List<String>> get unbanUserStream => _unbanUserController.stream; // 14
  Stream<int> get updateHostBonusStream => _updateHostBonusController.stream; // 15 - Host bonus events
  Stream<GiftModel> get sentAudioGiftsStream => _sentAudioGiftsController.stream; // 16 - Sent audio gifts events
  // Muted users stream
  Stream<String> get mutedUserIdStream => _mutedUserIdController.stream;

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
    socket.on(AudioSocketConstants.getAllRoomsEvent, _handleGetAllRooms); // 1
    socket.on(AudioSocketConstants.audioRoomDetailsEvent, _handleAudioRoomDetails); // 2
    socket.on(AudioSocketConstants.createRoomEvent, _handleCreateRoom); // 3
    socket.on(AudioSocketConstants.joinAudioRoomEvent, _handleJoinRoom); // 4
    socket.on(AudioSocketConstants.leaveAudioRoomEvent, _handleLeaveRoom); // 5
    socket.on(AudioSocketConstants.userLeftEvent, _handleUserLeft); // 6
    socket.on(AudioSocketConstants.joinSeatEvent, _handleJoinSeat); // 7
    socket.on(AudioSocketConstants.leaveSeatEvent, _handleLeaveSeat); // 8
    socket.on(AudioSocketConstants.sendMessageEvent, _handleSendMessage); // 10
    socket.on(AudioSocketConstants.errorMessageEvent, _handleErrorMessage); // 11
    socket.on(AudioSocketConstants.banUserEvent, _handleBanUser); // 13
    // socket.on(AudioSocketConstants.muteUnmuteUserEvent, _handleMuteUnmuteUser);
    socket.on(AudioSocketConstants.updateHostBonusEvent, _handleUpdateHostBonus); // 15
    socket.on(AudioSocketConstants.sentAudioGiftsEvent, _handleSentAudioGifts); // 16
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
    // socket.off(AudioSocketConstants.muteUnmuteUserEvent);
    socket.off(AudioSocketConstants.banUserEvent);
    // socket.off(AudioSocketConstants.unbanUserEvent);
    socket.off(AudioSocketConstants.updateHostBonusEvent);
    socket.off(AudioSocketConstants.sentAudioGiftsEvent);
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
          _closeRoomController.add([]);
          return;
        }

        // Normal room details response
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          final roomData = data['data'] as Map<String, dynamic>;

          // Check if room doesn't exist (roomId is null)
          if (roomData['roomId'] == null) {
            _log('🏠 Room does not exist - notifying listeners');
            _closeRoomController.add([]);
            return;
          }

          final roomDetails = AudioRoomDetails.fromJson(roomData);
          _log('✅ Parsed room details for: ${roomDetails.roomId}');
          _audioRoomDetailsController.add(roomDetails);

          // Check if current user is in mutedUsers list and emit muted user ID
          if (roomDetails.mutedUsers.isNotEmpty) {
            final currentUserId = getCurrentUserId?.call();
            if (currentUserId != null && roomDetails.mutedUsers.contains(currentUserId)) {
              _log('🔇 Current user is muted, emitting muted user ID: $currentUserId');
              _mutedUserIdController.add(currentUserId);
            }
          }
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
    try {
      if (data is Map<String, dynamic>) {
        _createRoomController.add(AudioRoomDetails.fromJson(data));
        // Refresh room list after room creation
        // roomOperations?.refreshRoomList();
      }
    } catch (e) {
      _log('❌ Error processing room creation listener response: $e');
    }
  }

  void _handleJoinRoom(dynamic data) {
    _log('🚪 User joined audio room listener response: $data');
    try {
      if (data is Map<String, dynamic>) {
        _joinRoomController.add(AudioMember.fromJson(data['data']));
        // Refresh room list after user joins
        // roomOperations?.refreshRoomList();
      }
    } catch (e) {
      _log('❌ Error processing user join listener response: $e');
    }
  }

  void _handleLeaveRoom(dynamic data) {
    _log('🚪 Audio room left/deleted listener response: $data');
    try {
      if (data is Map<String, dynamic>) {
        _leaveRoomController.add(AudioRoomDetails.fromJson(data));
        // Refresh room list after room is left/deleted
        // roomOperations?.refreshRoomList();
      }
    } catch (e) {
      _log('❌ Error processing room leave listener response: $e');
    }
  }

  void _handleUserLeft(dynamic data) {
    _log('👋 Audio user left listener response: $data');
    try {
      if (data is Map<String, dynamic>) {
        _userLeftController.add(data['data']['_id']); // data['data']['_id'] is the user id
        // Refresh room list after user leaves
        // roomOperations?.refreshRoomList();
      }
    } catch (e) {
      _log('❌ Error processing user leave listener response: $e');
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
    try {
      if (data is Map<String, dynamic>) {
        errorController.add(data);
      }
    } catch (e) {
      _log('❌ Error processing error message listener response: $e');
    }
  }

  void _handleBanUser(dynamic data) {
    _log('🚫 Ban audio user listener response: $data');
    try {
      // Map<String, dynamic> json = {
      //   "success": true,
      //   "message": "Successfully banned the user",
      //   "data": {
      //     "bannedUsers": ["68bf1f02d21d6918d27d513a"],
      //   },
      // };
      if (data is Map<String, dynamic>) {
        final dataMap = data['data'];
        if (dataMap is Map<String, dynamic>) {
          final bannedUsers = dataMap['bannedUsers'];
          if (bannedUsers is List<dynamic>) {
            List<String> bannedUserIds = bannedUsers
                .where((item) => item != null)
                .map((item) => item.toString())
                .toList();
            _banUserController.add(bannedUserIds);
          }
        }
      }
    } catch (e) {
      _log('🚫 Ban audio user listener error: $e');
    }
  }

  // void _handleMuteUnmuteUser(dynamic data) {
  //   _log('🔇 Audio mute/unmute user listener response: $data');
  //   try {
  //     if (data is Map<String, dynamic>) {
  //       _muteUnmuteUserController.add(MuteUserModel.fromJson(data));
  //     }
  //   } catch (e) {
  //     _log('🔇 Audio mute/unmute user listener error: $e');
  //   }
  // }

  void _handleUpdateHostBonus(dynamic data) {
    _log('💰 Audio update host bonus listener response: $data');
    try {
      if (data is Map<String, dynamic>) {
        _updateHostBonusController.add(data['data']['hostBonus']);
      }
    } catch (e) {
      _log('💰 Audio update host bonus listener error: $e');
    }
  }

  void _handleSentAudioGifts(dynamic data) {
    _log('🎁 Audio sent audio gifts listener response: $data');
    try {
      if (data is Map<String, dynamic>) {
        _sentAudioGiftsController.add(GiftModel.fromJson(data));
      }
    } catch (e) {
      _log('🎁 Audio sent audio gifts listener error: $e');
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
    // _unbanUserController.close();
    _updateHostBonusController.close();
    _mutedUserIdController.close();
  }
}
