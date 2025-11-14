import 'package:equatable/equatable.dart';
import '../../../../core/network/models/chat_model.dart';

/// States for Chat feature
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Chat loaded with messages
class ChatLoaded extends ChatState {
  final List<ChatModel> messages;

  const ChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// Sending message
class ChatSending extends ChatState {
  const ChatSending();
}

/// Message sent successfully
class ChatMessageSent extends ChatState {
  const ChatMessageSent();
}

/// Error sending message
class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
