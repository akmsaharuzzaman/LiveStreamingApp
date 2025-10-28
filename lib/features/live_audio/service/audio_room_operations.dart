import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../data/models/audio_room_details.dart';
import 'socket_constants.dart';
import 'socket_event_listeners.dart';

/// Handles room-related operations
class AudioSocketRoomOperations {
  late socket_io.Socket socket;
  final StreamController<Map<String, dynamic>> errorController;
  AudioSocketEventListeners? eventListeners;

  AudioSocketRoomOperations(this.errorController, this.eventListeners);

  void setSocket(socket_io.Socket socket) {
    this.socket = socket;
  }

  void setEventHandler(AudioSocketEventListeners handler) {
    eventListeners = handler;
  }

  void _log(String message) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';

    if (kDebugMode) {
      debugPrint('\n$yellow[AUDIO_ROOM] : Room - $reset $message\n');
    }
  }

  /// Create a new room
  Future<bool> createRoom(
    String roomId,
    String title, {
    int numberOfSeats = AudioSocketConstants.defaultNumberOfSeats,
  }) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🏠 Creating audio room: $roomId with $numberOfSeats seats');

      final Map<String, dynamic> roomData = {
        'roomId': roomId,
        'title': title,
        'numberOfSeats': numberOfSeats
      };

      socket.emit(AudioSocketConstants.createRoomEvent, roomData);
      return true;
    } catch (e) {
      _log('❌ Error creating room: $e');
      errorController.add({'status': 'error', 'message': 'Failed to create room: $e'});
      return false;
    }
  }

  /// Delete a room (only host can delete)
  Future<bool> deleteRoom(String roomId) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🗑️ Deleting room: $roomId');
      socket.emit(AudioSocketConstants.leaveAudioRoomEvent, {'roomId': roomId});
      return true;
    } catch (e) {
      _log('❌ Error deleting room: $e');
      errorController.add({'status': 'error', 'message': 'Failed to delete room: $e'});
      return false;
    }
  }

  /// Join a room
  Future<bool> joinRoom(String roomId) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🚪 Joining Audio room: $roomId');
      socket.emit(AudioSocketConstants.joinAudioRoomEvent, {'roomId': roomId});
      return true;
    } catch (e) {
      _log('❌ Error joining Audio room: $e');
      errorController.add({'status': 'error', 'message': 'Failed to join Audio room: $e'});
      return false;
    }
  }

  /// Leave a room
  Future<bool> leaveRoom(String roomId) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🚪 Leaving Audio room: $roomId');
      socket.emit(AudioSocketConstants.leaveAudioRoomEvent, {'roomId': roomId});
      return true;
    } catch (e) {
      _log('❌ Error leaving Audio room: $e');
      errorController.add({'status': 'error', 'message': 'Failed to leave Audio room: $e'});
      return false;
    }
  }

  /// Get list of all rooms
  Future<bool> getRooms() async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('📋 Getting audio rooms list');
      socket.emit(AudioSocketConstants.getAllRoomsEvent, {});
      return true;
    } catch (e) {
      _log('❌ Error getting audio rooms: $e');
      errorController.add({'status': 'error', 'message': 'Failed to get audio rooms: $e'});
      return false;
    }
  }

  /// Get room details by room ID
  Future<AudioRoomDetails?> getRoomDetails(String roomId) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return null;
    }

    try {
      _log('📋 Getting audio room details for: $roomId');

      // Create a completer to wait for the response
      final completer = Completer<AudioRoomDetails?>();

      // Listen for the room details response
      void onRoomDetails(dynamic data) {
        try {
          if (data is Map<String, dynamic>) {
            data = data['data'];
            _log('📺 Raw getRoomDetails response: $data');
            if (data['roomId'] == null) {
              _log('🏠 Room does not exist - notifying listeners');
              completer.complete(null);
              return;
            }
            final roomDetails = AudioRoomDetails.fromJson(data);
            _log('✅ Received room details for: ${roomDetails.roomId}');
            completer.complete(roomDetails);
          } else {
            _log('❌ Invalid room details format: $data');
            completer.complete(null);
          }
        } catch (e) {
          _log('❌ Error parsing room details: $e');
          completer.complete(null);
        }
      }

      // Set up one-time listener for room details
      socket.once(AudioSocketConstants.audioRoomDetailsEvent, onRoomDetails);

      // Emit the request
      socket.emit(AudioSocketConstants.audioRoomDetailsEvent, {'roomId': roomId});

      // Wait for response with timeout
      return await completer.future.timeout(
        AudioSocketConstants.roomDetailsTimeout,
        onTimeout: () {
          _log('⏰ Room details request timeout');
          socket.off(AudioSocketConstants.audioRoomDetailsEvent, onRoomDetails);
          return null;
        },
      );
    } catch (e) {
      _log('❌ Error getting audio room details: $e');
      errorController.add({'status': 'error', 'message': 'Failed to get audio room details: $e'});
      return null;
    }
  }

  /// Send Message
  Future<bool> sendMessage(String roomId, String message) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('💬 Sending audio message: $message');
      socket.emit(AudioSocketConstants.sendMessageEvent, {'roomId': roomId, 'text': message});
      return true;
    } catch (e) {
      _log('❌ Error sending audio message: $e');
      errorController.add({'status': 'error', 'message': 'Failed to send audio message: $e'});
      return false;
    }
  }

  bool get _isConnected => socket.connected;
}
