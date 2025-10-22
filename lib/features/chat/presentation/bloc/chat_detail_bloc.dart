import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/models/user_model.dart';
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
  final String? currentUserId; // Optional: pass current user ID from UI

  const SendMessageEvent({
    required this.receiverId,
    required this.text,
    this.file,
    this.currentUserId,
  });

  @override
  List<Object?> get props => [receiverId, text, file, currentUserId];
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

class ChatDetailSendingMessage extends ChatDetailState {
  const ChatDetailSendingMessage();
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
  final AuthBloc _authBloc;

  ChatDetailBloc(this._chatApiService, this._authBloc)
    : super(const ChatDetailInitial()) {
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
    // Get the current messages from state
    List<ChatMessage> currentMessages = [];
    String currentOtherUserId = event.receiverId;

    if (state is ChatDetailMessagesLoaded) {
      final loadedState = state as ChatDetailMessagesLoaded;
      currentMessages = List.from(loadedState.messages);
      currentOtherUserId = loadedState.otherUserId;
    }
    // If messages haven't been loaded yet, use the receiverId as otherUserId
    // This ensures we still have proper otherUserId even if list is empty

    // Get current user info from AuthBloc - try multiple approaches
    ChatUser? currentUser;
    final authState = _authBloc.state;
    UserModel? authUser;

    if (kDebugMode) {
      debugPrint('Auth State Type: ${authState.runtimeType}');
      debugPrint('Auth BLoC current user: ${_authBloc.currentUser}');
      debugPrint('Passed currentUserId from event: ${event.currentUserId}');
    }

    // If currentUserId was passed from UI, we can extract user from messages directly
    if (event.currentUserId != null && currentMessages.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('Using currentUserId from UI: ${event.currentUserId}');
      }
      final firstMessage = currentMessages.firstWhere(
        (msg) => msg.sender?.id == event.currentUserId,
        orElse: () => currentMessages.first,
      );
      if (firstMessage.sender != null) {
        currentUser = firstMessage.sender;
      }
    }
    
    // If still no user, try AuthBloc approaches
    if (currentUser == null) {
      // Approach 1: Try to get user from state
      if (authState is AuthAuthenticated) {
        authUser = authState.user;
      } else if (authState is AuthProfileIncomplete) {
        authUser = authState.user;
      } else {
        // Approach 2: Fallback to getter which might have cached user
        authUser = _authBloc.currentUser;
      }

      if (authUser != null) {
        currentUser = ChatUser(
          id: authUser.id,
          name: authUser.name,
          email: authUser.email,
          avatar: authUser.profilePictureUrl ?? authUser.avatar ?? '',
          isOnline: true,
        );
      }
      
      // Approach 3: Last resort - if we have messages and no user, use sender from messages
      if (currentUser == null && currentMessages.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('Using sender from existing messages as fallback');
        }
        // The first message should have sender info
        final firstMessageSender = currentMessages.first.sender;
        if (firstMessageSender != null) {
          currentUser = firstMessageSender;
        }
      }
    }

    // If currentUser is null, we cannot send the message
    if (currentUser == null) {
      if (kDebugMode) {
        debugPrint(
          'ERROR: User not authenticated. Auth State: ${authState.runtimeType}, User: $authUser, Messages: ${currentMessages.length}',
        );
      }
      emit(ChatDetailError(message: 'User not authenticated'));
      return;
    }

    if (kDebugMode) {
      debugPrint('Sending message as: ${currentUser.id} (${currentUser.name})');
    }

    // Create a temporary optimistic message to show immediately
    final optimisticMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
      text: event.text,
      sender: currentUser, // Current user info
      receiver: null,
      timestamp: DateTime.now(),
      time: _formatTime(DateTime.now()),
      seen: false,
      roomId: null,
      fileUrl: event.file?.path,
      type: event.file != null ? MessageType.image : MessageType.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add the optimistic message to the list (at the beginning since messages are reversed)
    currentMessages.insert(0, optimisticMessage);

    // Emit the updated state with the optimistic message immediately
    emit(
      ChatDetailMessagesLoaded(
        messages: currentMessages,
        otherUserId: currentOtherUserId,
      ),
    );

    // Now send the actual message in the background
    final result = await _chatApiService.sendMessage(
      receiverId: event.receiverId,
      text: event.text,
      file: event.file,
    );

    result.fold(
      (message) {
        // Replace the optimistic message with the real one
        if (kDebugMode) {
          debugPrint(
            'Received message from server - ID: ${message.id}, Sender ID: ${message.sender?.id}, Sender Name: ${message.sender?.name}',
          );
          debugPrint(
            'Looking for temp message to replace: ${optimisticMessage.id}',
          );
        }

        final updatedMessages = currentMessages.map((msg) {
          if (msg.id == optimisticMessage.id) {
            if (kDebugMode) {
              debugPrint('Replaced optimistic message with real message');
            }
            return message; // Replace with real message from server
          }
          return msg;
        }).toList();

        emit(
          ChatDetailMessagesLoaded(
            messages: updatedMessages,
            otherUserId: currentOtherUserId,
          ),
        );

        // Emit success state for UI feedback (like clearing input)
        emit(ChatDetailMessageSent(message: message));

        // Restore the messages state
        emit(
          ChatDetailMessagesLoaded(
            messages: updatedMessages,
            otherUserId: currentOtherUserId,
          ),
        );
      },
      (error) {
        // On error, remove the optimistic message and show error
        currentMessages.removeWhere((msg) => msg.id == optimisticMessage.id);

        emit(
          ChatDetailMessagesLoaded(
            messages: currentMessages,
            otherUserId: currentOtherUserId,
          ),
        );

        emit(ChatDetailError(message: error));

        // Restore the messages state
        emit(
          ChatDetailMessagesLoaded(
            messages: currentMessages,
            otherUserId: currentOtherUserId,
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
