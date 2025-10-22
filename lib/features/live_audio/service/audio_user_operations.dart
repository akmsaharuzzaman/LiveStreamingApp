import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'socket_constants.dart';

/// Handles user management operations like mute, ban, unban
class AudioSocketUserOperations {
  late socket_io.Socket socket;
  final StreamController<Map<String, dynamic>> errorController;
  final String? Function() getCurrentRoomId;

  AudioSocketUserOperations(this.errorController, this.getCurrentRoomId);

  void setSocket(socket_io.Socket socket) {
    this.socket = socket;
  }

  void _log(String message) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';

    if (kDebugMode) {
      debugPrint('\n$yellow[AUDIO_ROOM] : User - $reset $message\n');
    }
  }

  ///Ban User
  Future<bool> banUser(String userId) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    final roomId = getCurrentRoomId();
    if (roomId == null) {
      errorController.add({'status': 'error', 'message': 'No current room'});
      return false;
    }

    try {
      _log('🚫 Banning audio user: $userId');

      socket.emit(AudioSocketConstants.banUserEvent, {'roomId': roomId, 'targetId': userId});
      return true;
    } catch (e) {
      _log('❌ Error banning audio user: $e');
      errorController.add({'status': 'error', 'message': 'Failed to ban user: $e'});
      return false;
    }
  }

  // Unban User
  Future<bool> unbanUser(String userId) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    final roomId = getCurrentRoomId();
    if (roomId == null) {
      errorController.add({'status': 'error', 'message': 'No current room'});
      return false;
    }

    try {
      _log('🚫 Unbanning audio user: $userId');

      socket.emit(AudioSocketConstants.unbanUserEvent, {'roomId': roomId, 'targetId': userId});
      return true;
    } catch (e) {
      _log('❌ Error unbanning audio user: $e');
      errorController.add({'status': 'error', 'message': 'Failed to unban user: $e'});
      return false;
    }
  }

  ///Mute/Unmute User
  Future<bool> muteUnmuteUser(String userId) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    final roomId = getCurrentRoomId();
    if (roomId == null) {
      errorController.add({'status': 'error', 'message': 'No current room'});
      return false;
    }

    try {
      _log('🔇 Muting/Unmuting audio user: $userId');

      socket.emit(AudioSocketConstants.muteUnmuteUserEvent, {'roomId': roomId, 'targetId': userId});
      return true;
    } catch (e) {
      _log('❌ Error muting/Unmuting audio user: $e');
      errorController.add({'status': 'error', 'message': 'Failed to mute user: $e'});
      return false;
    }
  }

  bool get _isConnected => socket.connected;
}
