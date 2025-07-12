import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../data/services/chat_api_service.dart';
import '../../data/models/chat_models.dart';

// Events for Chat Detail
abstract class ChatDetailEvent extends Equatable {
  const ChatDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessagesEvent extends ChatDetailEvent {
  final String otherUserId;
  const LoadMessagesEvent({required this.otherUserId});

  @override
  List<Object?> get props => [otherUserId];
}

class SendMessageEvent extends ChatDetailEvent {
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

class MarkMessagesSeenEvent extends ChatDetailEvent {
  final String senderId;
  final String receiverId;

  const MarkMessagesSeenEvent({
    required this.senderId,
    required this.receiverId,
  });

  @override
  List<Object?> get props => [senderId, receiverId];
}

class EditMessageEvent extends ChatDetailEvent {
  final String messageId;
  final String newText;

  const EditMessageEvent({required this.messageId, required this.newText});

  @override
  List<Object?> get props => [messageId, newText];
}

class DeleteMessageEvent extends ChatDetailEvent {
  final String messageId;

  const DeleteMessageEvent({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class RefreshMessagesEvent extends ChatDetailEvent {
  final String otherUserId;
  const RefreshMessagesEvent({required this.otherUserId});

  @override
  List<Object?> get props => [otherUserId];
}

// States for Chat Detail
abstract class ChatDetailState extends Equatable {
  const ChatDetailState();

  @override
  List<Object?> get props => [];
}

class ChatDetailInitial extends ChatDetailState {
  const ChatDetailInitial();
}

class ChatDetailLoading extends ChatDetailState {
  const ChatDetailLoading();
}

class ChatDetailMessagesLoaded extends ChatDetailState {
  final List<ChatMessage> messages;
  final String otherUserId;

  const ChatDetailMessagesLoaded({
    required this.messages,
    required this.otherUserId,
  });

  @override
  List<Object?> get props => [messages, otherUserId];
}

class ChatDetailMessageSent extends ChatDetailState {
  final ChatMessage message;

  const ChatDetailMessageSent({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChatDetailMessageEdited extends ChatDetailState {
  final ChatMessage message;

  const ChatDetailMessageEdited({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChatDetailMessageDeleted extends ChatDetailState {
  final String messageId;

  const ChatDetailMessageDeleted({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class ChatDetailMessagesMarkedSeen extends ChatDetailState {
  final String senderId;
  final String receiverId;

  const ChatDetailMessagesMarkedSeen({
    required this.senderId,
    required this.receiverId,
  });

  @override
  List<Object?> get props => [senderId, receiverId];
}

class ChatDetailError extends ChatDetailState {
  final String message;

  const ChatDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC for Chat Detail
@injectable
class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final ChatApiService _chatApiService;

  ChatDetailBloc(this._chatApiService) : super(const ChatDetailInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<MarkMessagesSeenEvent>(_onMarkMessagesSeen);
    on<EditMessageEvent>(_onEditMessage);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<RefreshMessagesEvent>(_onRefreshMessages);
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    emit(const ChatDetailLoading());

    final result = await _chatApiService.getAllMessages(
      otherUserId: event.otherUserId,
    );

    result.fold(
      (messages) {
        emit(
          ChatDetailMessagesLoaded(
            messages: messages,
            otherUserId: event.otherUserId,
          ),
        );
      },
      (error) {
        emit(ChatDetailError(message: error));
      },
    );
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    final result = await _chatApiService.sendMessage(
      receiverId: event.receiverId,
      text: event.text,
      file: event.file,
    );

    result.fold(
      (message) {
        emit(ChatDetailMessageSent(message: message));
        // Reload messages after sending to show the new message
        add(LoadMessagesEvent(otherUserId: event.receiverId));
      },
      (error) {
        emit(ChatDetailError(message: error));
      },
    );
  }

  Future<void> _onMarkMessagesSeen(
    MarkMessagesSeenEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    final result = await _chatApiService.markMessagesSeen(
      senderId: event.senderId,
      receiverId: event.receiverId,
    );

    result.fold(
      (data) {
        emit(
          ChatDetailMessagesMarkedSeen(
            senderId: event.senderId,
            receiverId: event.receiverId,
          ),
        );
      },
      (error) {
        emit(ChatDetailError(message: error));
      },
    );
  }

  Future<void> _onEditMessage(
    EditMessageEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    final result = await _chatApiService.editMessage(
      messageId: event.messageId,
      newText: event.newText,
    );

    result.fold(
      (message) {
        emit(ChatDetailMessageEdited(message: message));
      },
      (error) {
        emit(ChatDetailError(message: error));
      },
    );
  }

  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    final result = await _chatApiService.deleteMessage(
      messageId: event.messageId,
    );

    result.fold(
      (success) {
        emit(ChatDetailMessageDeleted(messageId: event.messageId));
      },
      (error) {
        emit(ChatDetailError(message: error));
      },
    );
  }

  Future<void> _onRefreshMessages(
    RefreshMessagesEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    // Don't emit loading state for refresh to avoid UI flickering
    final result = await _chatApiService.getAllMessages(
      otherUserId: event.otherUserId,
    );

    result.fold(
      (messages) {
        emit(
          ChatDetailMessagesLoaded(
            messages: messages,
            otherUserId: event.otherUserId,
          ),
        );
      },
      (error) {
        emit(ChatDetailError(message: error));
      },
    );
  }
}
