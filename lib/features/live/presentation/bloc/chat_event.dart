import 'package:equatable/equatable.dart';
import '../../../../core/network/models/chat_model.dart';

/// Events for Chat feature
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Send a chat message
class SendChatMessage extends ChatEvent {
  final String roomId;
  final String userId;
  final String userName;
  final String message;
  final String? avatar;

  const SendChatMessage({
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.message,
    this.avatar,
  });

  @override
  List<Object?> get props => [roomId, userId, userName, message, avatar];
}

/// Receive a chat message
class ReceiveChatMessage extends ChatEvent {
  final ChatModel message;

  const ReceiveChatMessage(this.message);

  @override
  List<Object?> get props => [message];
}

/// Load initial messages
class LoadInitialMessages extends ChatEvent {
  final List<ChatModel> messages;

  const LoadInitialMessages(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// Clear all messages
class ClearChatMessages extends ChatEvent {
  const ClearChatMessages();
}
