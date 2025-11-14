import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../../../core/network/models/chat_model.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;

  // Subscription for cleanup
  StreamSubscription? _messagesSubscription;

  // Store messages in memory
  final List<ChatModel> _messages = [];

  ChatBloc(this._repository) : super(const ChatInitial()) {
    on<SendChatMessage>(_onSendMessage);
    on<ReceiveChatMessage>(_onReceiveMessage);
    on<LoadInitialMessages>(_onLoadInitialMessages);
    on<ClearChatMessages>(_onClearMessages);

    // Setup stream listener
    _setupMessageListener();
  }

  Future<void> _onSendMessage(
    SendChatMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatSending());

      _repository.sendMessage(
        roomId: event.roomId,
        userId: event.userId,
        userName: event.userName,
        message: event.message,
        avatar: event.avatar,
      );

      emit(const ChatMessageSent());
      
      // Return to loaded state
      emit(ChatLoaded(_messages));
    } catch (e) {
      emit(ChatError('Failed to send message: $e'));
      emit(ChatLoaded(_messages)); // Return to loaded state
    }
  }

  void _onReceiveMessage(
    ReceiveChatMessage event,
    Emitter<ChatState> emit,
  ) {
    _messages.add(event.message);
    emit(ChatLoaded(List.from(_messages)));
  }

  void _onLoadInitialMessages(
    LoadInitialMessages event,
    Emitter<ChatState> emit,
  ) {
    _messages.clear();
    _messages.addAll(event.messages);
    emit(ChatLoaded(List.from(_messages)));
  }

  void _onClearMessages(
    ClearChatMessages event,
    Emitter<ChatState> emit,
  ) {
    _messages.clear();
    emit(const ChatInitial());
  }

  void _setupMessageListener() {
    _messagesSubscription = _repository.messagesStream.listen((message) {
      add(ReceiveChatMessage(message));
    });
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
