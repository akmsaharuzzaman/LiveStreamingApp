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
    // ✅ Use the socket service's sendMessage method which properly emits the event
    _socketService.sendMessage(roomId, message);
  }

  @override
  Stream<ChatModel> get messagesStream => _socketService.sentMessageStream;
}
