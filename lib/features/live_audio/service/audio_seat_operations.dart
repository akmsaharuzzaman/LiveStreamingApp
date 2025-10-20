import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'socket_constants.dart';

/// Handles seat-related operations
class AudioSocketSeatOperations {
  late IO.Socket socket;
  final StreamController<Map<String, dynamic>> errorController;

  AudioSocketSeatOperations(this.errorController);

  void setSocket(IO.Socket socket) {
    this.socket = socket;
  }

  void _log(String message) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';

    if (kDebugMode) {
      debugPrint('\n$yellow[AUDIO_ROOM] : Seat - $reset $message\n');
    }
  }

  /// Join a specific seat in audio room
  Future<bool> joinSeat({required String roomId, required String seatKey, required String targetId}) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🪑 Joining seat: $seatKey in room: $roomId');

      final Map<String, dynamic> data = {'roomId': roomId, 'seatKey': seatKey, 'targetId': targetId};

      socket.emit(AudioSocketConstants.joinSeatEvent, data);
      return true;
    } catch (e) {
      _log('❌ Error joining seat: $e');
      errorController.add({'status': 'error', 'message': 'Failed to join seat: $e'});
      return false;
    }
  }

  /// Leave a specific seat in audio room
  Future<bool> leaveSeat({required String roomId, required String seatKey, required String targetId}) async {
    if (!_isConnected) {
      errorController.add({'status': 'error', 'message': 'Socket not connected'});
      return false;
    }

    try {
      _log('🚪 Leaving seat: $seatKey in room: $roomId');

      final Map<String, dynamic> data = {'roomId': roomId, 'seatKey': seatKey, 'targetId': targetId};

      socket.emit(AudioSocketConstants.leaveSeatEvent, data);
      return true;
    } catch (e) {
      _log('❌ Error leaving seat: $e');
      errorController.add({'status': 'error', 'message': 'Failed to leave seat: $e'});
      return false;
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

  bool get _isConnected => socket.connected;
}
