import 'dart:async';
import 'package:injectable/injectable.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/network/models/chat_model.dart';

abstract class ChatRepository {
  // Send message
  void sendMessage({
    required String roomId,
    required String userId,
    required String userName,
    required String message,
    String? avatar,
  });

  // Stream of incoming messages
  Stream<ChatModel> get messagesStream;
}

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final SocketService _socketService;

  ChatRepositoryImpl(this._socketService);

  @override
  void sendMessage({
    required String roomId,
    required String userId,
    required String userName,
    required String message,
    String? avatar,
  }) {
    _socketService.emit('send-message', {
      'roomId': roomId,
      'userId': userId,
      'userName': userName,
      'message': message,
      'avatar': avatar,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Stream<ChatModel> get messagesStream => _socketService.sentMessageStream;
}
