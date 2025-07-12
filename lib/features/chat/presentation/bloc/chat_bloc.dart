import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../data/services/chat_api_service.dart';
import '../../data/models/chat_models.dart';

// Events for Chat List
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversationsEvent extends ChatEvent {
  const LoadConversationsEvent();
}

class RefreshConversationsEvent extends ChatEvent {
  const RefreshConversationsEvent();
}

// States for Chat List
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

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC for Chat List
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatApiService _chatApiService;

  ChatBloc(this._chatApiService) : super(const ChatInitial()) {
    on<LoadConversationsEvent>(_onLoadConversations);
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
