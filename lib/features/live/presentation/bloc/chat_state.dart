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
  final int _timestamp; // ✅ Add timestamp to force state change detection

  ChatLoaded(this.messages, {int? timestamp})
    : _timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [_timestamp]; // ✅ Use timestamp for equality
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
