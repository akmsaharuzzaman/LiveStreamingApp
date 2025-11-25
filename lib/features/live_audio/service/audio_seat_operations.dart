import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'socket_constants.dart';

/// Handles seat-related operations
class AudioSocketSeatOperations {
  late socket_io.Socket socket;
  final StreamController<Map<String, dynamic>> errorController;
  AudioSocketSeatOperations(this.errorController);

  /// joinSeat
  /// leaveSeat
  /// removeFromSeat
  /// muteUserFromSeat
  /// sendAudioEmoji

  void setSocket(socket_io.Socket socket) {
    this.socket = socket;
  }

  void _log(String message) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';
    if (kDebugMode) debugPrint('\n$yellow[AUDIO_ROOM] : Seat - $reset $message\n');
  }

  /// Join a specific seat in audio room
  void joinSeat({required String roomId, required String seatKey, required String targetId}) {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return;
    }
    try {
      _log('🪑 Joining seat: $seatKey in room: $roomId');
      final Map<String, dynamic> data = {'roomId': roomId, 'seatKey': seatKey, 'targetId': targetId};
      socket.emit(AudioSocketConstants.joinSeatEvent, data);
    } catch (e) {
      _log('❌ Error joining seat: $e');
      errorController.add({'status': 'error', 'message': 'Failed to join seat: $e'});
    }
  }

  /// Leave a specific seat in audio room
  void leaveSeat({required String roomId, required String seatKey, required String targetId}) {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return;
    }
    try {
      _log('🚪 Leaving seat: $seatKey in room: $roomId');
      final Map<String, dynamic> data = {'roomId': roomId, 'seatKey': seatKey, 'targetId': targetId};
      socket.emit(AudioSocketConstants.leaveSeatEvent, data);
    } catch (e) {
      _log('❌ Error leaving seat: $e');
      errorController.add({'status': 'error', 'message': 'Failed to leave seat: $e'});
    }
  }

  /// Remove user from a specific seat (host only)
  Future<bool> removeFromSeat({required String roomId, required String seatKey, required String targetId}) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🚫 Removing user from seat: $seatKey');

      socket.emit(AudioSocketConstants.removeFromSeatEvent, {
        'roomId': roomId,
        'seatKey': seatKey,
        'targetId': targetId,
      });
      return true;
    } catch (e) {
      _log('❌ Error removing from seat: $e');
      errorController.add({'status': 'error', 'message': 'Failed to remove from seat: $e'});
      return false;
    }
  }

  /// Mute user from a specific seat (host only)
  Future<bool> muteUserFromSeat({required String roomId, required String seatKey, required String targetId}) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🔇 Muting user from seat: $seatKey');

      socket.emit(AudioSocketConstants.muteUnmuteUserEvent, {
        'roomId': roomId,
        'seatKey': seatKey,
        'targetId': targetId,
      });
      return true;
    } catch (e) {
      _log('❌ Error muting from seat: $e');
      errorController.add({'status': 'error', 'message': 'Failed to mute from seat: $e'});
      return false;
    }
  }

  /// Lock or unlock a specific seat (host only)
  Future<bool> lockUnlockSeat({required String roomId, required String seatKey}) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🔒 Toggling lock for seat: $seatKey in room: $roomId');

      socket.emit(AudioSocketConstants.lockUnlockSeatEvent, {'roomId': roomId, 'seatKey': seatKey});
      return true;
    } catch (e) {
      _log('❌ Error locking/unlocking seat: $e');
      errorController.add({'status': 'error', 'message': 'Failed to lock/unlock seat: $e'});
      return false;
    }
  }

  /// Send audio emoji
  Future<bool> sendAudioEmoji({required String roomId, required String seatKey, required String emoji}) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('💬 Sending audio emoji: $seatKey');
      socket.emit(AudioSocketConstants.sendAudioEmojiEvent, {'roomId': roomId, 'seatKey': seatKey, 'emoji': emoji});
      return true;
    } catch (e) {
      _log('❌ Error sending audio emoji: $e');
      errorController.add({'status': 'error', 'message': 'Failed to send audio emoji: $e'});
      return false;
    }
  }

  bool get _isConnected => socket.connected;
}
