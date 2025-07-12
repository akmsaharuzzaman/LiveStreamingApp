import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../data/services/chat_api_service.dart';
import '../../data/models/chat_models.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversationsEvent extends ChatEvent {
  const LoadConversationsEvent();
}

class LoadMessagesEvent extends ChatEvent {
  final String otherUserId;
  const LoadMessagesEvent({required this.otherUserId});

  @override
  List<Object?> get props => [otherUserId];
}

class SendMessageEvent extends ChatEvent {
  final String receiverId;
  final String text;
  final File? file;

  const SendMessageEvent({
    required this.receiverId,
    required this.text,
    this.file,
  });

  @override
  List<Object?> get props => [receiverId, text, file];
}

class MarkMessagesSeenEvent extends ChatEvent {
  final String senderId;
  final String receiverId;

  const MarkMessagesSeenEvent({
    required this.senderId,
    required this.receiverId,
  });

  @override
  List<Object?> get props => [senderId, receiverId];
}

class EditMessageEvent extends ChatEvent {
  final String messageId;
  final String newText;

  const EditMessageEvent({required this.messageId, required this.newText});

  @override
  List<Object?> get props => [messageId, newText];
}

class DeleteMessageEvent extends ChatEvent {
  final String messageId;

  const DeleteMessageEvent({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class RefreshConversationsEvent extends ChatEvent {
  const RefreshConversationsEvent();
}

// States
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatConversationsLoaded extends ChatState {
  final List<Conversation> conversations;

  const ChatConversationsLoaded({required this.conversations});

  @override
  List<Object?> get props => [conversations];
}

class ChatMessagesLoaded extends ChatState {
  final List<ChatMessage> messages;
  final String otherUserId;

  const ChatMessagesLoaded({required this.messages, required this.otherUserId});

  @override
  List<Object?> get props => [messages, otherUserId];
}

class ChatMessageSent extends ChatState {
  final ChatMessage message;

  const ChatMessageSent({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChatMessageEdited extends ChatState {
  final ChatMessage message;

  const ChatMessageEdited({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChatMessageDeleted extends ChatState {
  final String messageId;

  const ChatMessageDeleted({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class ChatMessagesMarkedSeen extends ChatState {
  final String senderId;
  final String receiverId;

  const ChatMessagesMarkedSeen({
    required this.senderId,
    required this.receiverId,
  });

  @override
  List<Object?> get props => [senderId, receiverId];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatApiService _chatApiService;

  ChatBloc(this._chatApiService) : super(const ChatInitial()) {
    on<LoadConversationsEvent>(_onLoadConversations);
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<MarkMessagesSeenEvent>(_onMarkMessagesSeen);
    on<EditMessageEvent>(_onEditMessage);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<RefreshConversationsEvent>(_onRefreshConversations);
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());

    final result = await _chatApiService.getAllConversations();

    result.fold(
      (conversations) {
        emit(ChatConversationsLoaded(conversations: conversations));
      },
      (error) {
        emit(ChatError(message: error));
      },
    );
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());

    final result = await _chatApiService.getAllMessages(
      otherUserId: event.otherUserId,
    );

    result.fold(
      (messages) {
        emit(
          ChatMessagesLoaded(
            messages: messages,
            otherUserId: event.otherUserId,
          ),
        );
      },
      (error) {
        emit(ChatError(message: error));
      },
    );
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _chatApiService.sendMessage(
      receiverId: event.receiverId,
      text: event.text,
      file: event.file,
    );

    result.fold(
      (message) {
        emit(ChatMessageSent(message: message));
        // Optionally reload messages after sending
        add(LoadMessagesEvent(otherUserId: event.receiverId));
      },
      (error) {
        emit(ChatError(message: error));
      },
    );
  }

  Future<void> _onMarkMessagesSeen(
    MarkMessagesSeenEvent event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _chatApiService.markMessagesSeen(
      senderId: event.senderId,
      receiverId: event.receiverId,
    );

    result.fold(
      (data) {
        emit(
          ChatMessagesMarkedSeen(
            senderId: event.senderId,
            receiverId: event.receiverId,
          ),
        );
      },
      (error) {
        emit(ChatError(message: error));
      },
    );
  }

  Future<void> _onEditMessage(
    EditMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _chatApiService.editMessage(
      messageId: event.messageId,
      newText: event.newText,
    );

    result.fold(
      (message) {
        emit(ChatMessageEdited(message: message));
      },
      (error) {
        emit(ChatError(message: error));
      },
    );
  }

  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _chatApiService.deleteMessage(
      messageId: event.messageId,
    );

    result.fold(
      (success) {
        emit(ChatMessageDeleted(messageId: event.messageId));
      },
      (error) {
        emit(ChatError(message: error));
      },
    );
  }

  Future<void> _onRefreshConversations(
    RefreshConversationsEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Don't emit loading state for refresh to avoid UI flickering
    final result = await _chatApiService.getAllConversations();

    result.fold(
      (conversations) {
        emit(ChatConversationsLoaded(conversations: conversations));
      },
      (error) {
        emit(ChatError(message: error));
      },
    );
  }
}
