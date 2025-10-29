import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'socket_constants.dart';

/// Manages socket connection, disconnection, and reconnection
class AudioSocketConnectionManager {
  socket_io.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentRoomId;

  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  void _log(String message) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';

    if (kDebugMode) {
      debugPrint('\n$yellow[AUDIO_ROOM] : Connection - $reset $message\n');
    }
  }

  /// Getters
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  String? get currentRoomId => _currentRoomId;
  socket_io.Socket? get socket => _socket;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// Initialize and connect to socket
  Future<bool> connect(String userId) async {
    try {
      if (_isConnected && _currentUserId == userId) {
        _log('🔌  Audio Socket already connected for user: $userId');
        return true;
      }

      // Disconnect if already connected with different user
      if (_isConnected) {
        await disconnect();
      }

      _currentUserId = userId;

      _log('🔌 Audio Socket connecting to socket with userId: $userId');

      // Create socket with userId in query
      _socket = socket_io.io(
        AudioSocketConstants.baseUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'userId': userId})
            .disableAutoConnect() // Disable auto connect
            .enableForceNew() // Force new connection
            .enableReconnection()
            .setReconnectionAttempts(AudioSocketConstants.reconnectionAttempts)
            .setReconnectionDelay(AudioSocketConstants.reconnectionDelayMs)
            .build(),
      );

      // Connect to socket
      final completer = Completer<bool>();

      _socket!.onConnect((_) {
        _isConnected = true;
        _connectionStatusController.add(true);
        _log('✅ Audio Socket connected successfully');
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });

      _socket!.onConnectError((error) {
        _log('❌ Audio Socket connection error: $error');
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      _socket!.connect();

      // Wait for connection with timeout
      return await completer.future.timeout(
        AudioSocketConstants.connectionTimeout,
        onTimeout: () {
          _log('⏰ Audio Socket connection timeout');
          return false;
        },
      );
    } catch (e) {
      _log('💥 Audio Socket connection exception: $e');
      return false;
    }
  }

  /// Disconnect from socket
  Future<void> disconnect() async {
    try {
      _log('🔌 Disconnecting socket');

      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }

      _isConnected = false;
      _currentUserId = null;
      _currentRoomId = null;
      _connectionStatusController.add(false);

      _log('✅ Socket disconnected successfully');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disconnecting socket: $e');
      }
    }
  }

  /// Reconnect if disconnected
  Future<bool> reconnect() async {
    if (_currentUserId == null) {
      return false;
    }

    await disconnect();
    return await connect(_currentUserId!);
  }

  /// Check if socket is healthy
  bool get isHealthy {
    return _isConnected && _socket != null && _socket!.connected;
  }

  /// Set current room ID
  void setCurrentRoomId(String? roomId) {
    _currentRoomId = roomId;
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionStatusController.close();
  }
}
