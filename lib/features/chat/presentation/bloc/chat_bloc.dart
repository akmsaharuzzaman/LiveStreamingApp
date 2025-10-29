import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/auth/auth_bloc.dart';
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

class StartAutoRefreshEvent extends ChatEvent {
  const StartAutoRefreshEvent();
}

class StopAutoRefreshEvent extends ChatEvent {
  const StopAutoRefreshEvent();
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
  final int unreadCount;

  const ChatConversationsLoaded({
    required this.conversations,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [conversations, unreadCount];
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
  final AuthBloc _authBloc;
  Timer? _autoRefreshTimer;

  ChatBloc(this._chatApiService, this._authBloc) : super(const ChatInitial()) {
    on<LoadConversationsEvent>(_onLoadConversations);
    on<RefreshConversationsEvent>(_onRefreshConversations);
    on<StartAutoRefreshEvent>(_onStartAutoRefresh);
    on<StopAutoRefreshEvent>(_onStopAutoRefresh);
  }

  @override
  Future<void> close() {
    _autoRefreshTimer?.cancel();
    return super.close();
  }

  int _calculateUnreadCount(List<Conversation> conversations) {
    // Get current user ID from AuthBloc state
    String? currentUserId;

    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    } else if (authState is AuthProfileIncomplete) {
      currentUserId = authState.user.id;
    }

    if (currentUserId == null) {
      return 0; // If no user logged in, no unread count
    }

    // CORRECT LOGIC: Use lstMsg.senderId to determine who ACTUALLY sent the last message
    // The top-level senderId/receiverId are just participant information (fixed)
    // - If lstMsg.senderId == currentUserId: I sent the message
    //   - seenStatus false: Friend hasn't seen my message (NO unread count for me)
    //   - seenStatus true: Friend has seen my message (NO unread count for me)
    // - If lstMsg.senderId != currentUserId: Friend sent the message
    //   - seenStatus false: I haven't seen friend's message (COUNT as unread)
    //   - seenStatus true: I have seen friend's message (NO unread count)
    return conversations.where((conv) {
      // Use lstMsg.sender.id if available, fallback to top-level sender.id
      final actualSenderId = conv.lstMsg?.sender?.id ?? conv.sender?.id;
      final sentByMe = actualSenderId == currentUserId;
      // Only count as unread if: NOT sent by me AND not seen yet
      return !sentByMe && !conv.seenStatus;
    }).length;
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());

    final result = await _chatApiService.getAllConversations();

    result.fold(
      (conversations) {
        final unreadCount = _calculateUnreadCount(conversations);
        emit(
          ChatConversationsLoaded(
            conversations: conversations,
            unreadCount: unreadCount,
          ),
        );
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
        final unreadCount = _calculateUnreadCount(conversations);
        emit(
          ChatConversationsLoaded(
            conversations: conversations,
            unreadCount: unreadCount,
          ),
        );
      },
      (error) {
        emit(ChatError(message: error));
      },
    );
  }

  void _onStartAutoRefresh(
    StartAutoRefreshEvent event,
    Emitter<ChatState> emit,
  ) {
    // Cancel existing timer if any
    _autoRefreshTimer?.cancel();

    // Start a new timer that refreshes every 5 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      add(const RefreshConversationsEvent());
    });
  }

  void _onStopAutoRefresh(StopAutoRefreshEvent event, Emitter<ChatState> emit) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }
}
