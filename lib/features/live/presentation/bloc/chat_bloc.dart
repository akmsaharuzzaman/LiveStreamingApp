import 'dart:async';
import 'package:flutter/foundation.dart';
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
      debugPrint(
        "📤 [CHAT] Sending message: '${event.message}' to room: ${event.roomId}",
      );
      emit(const ChatSending());

      _repository.sendMessage(
        roomId: event.roomId,
        userId: event.userId,
        userName: event.userName,
        message: event.message,
        avatar: event.avatar,
      );

      debugPrint("✅ [CHAT] Message sent to socket");
      emit(const ChatMessageSent());

      // Return to loaded state
      debugPrint(
        "📨 [CHAT] Emitting ChatLoaded state with ${_messages.length} messages",
      );
      emit(ChatLoaded(_messages));
    } catch (e) {
      debugPrint("❌ [CHAT] Error sending message: $e");
      emit(ChatError('Failed to send message: $e'));
      emit(ChatLoaded(_messages)); // Return to loaded state
    }
  }

  void _onReceiveMessage(ReceiveChatMessage event, Emitter<ChatState> emit) {
    debugPrint("✅ [CHAT] Received message event: ${event.message.text}");
    debugPrint("✅ [CHAT] From: ${event.message.name}");
    debugPrint("✅ [CHAT] Total messages now: ${_messages.length + 1}");

    _messages.add(event.message);

    debugPrint(
      "✅ [CHAT] Emitting ChatLoaded with ${_messages.length} messages",
    );
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

  void _onClearMessages(ClearChatMessages event, Emitter<ChatState> emit) {
    _messages.clear();
    emit(const ChatInitial());
  }

  void _setupMessageListener() {
    debugPrint("📌 [CHAT] Setting up message listener from repository...");
    _messagesSubscription = _repository.messagesStream.listen(
      (message) {
        debugPrint("📨 [CHAT] Socket sent message from: ${message.name}");
        debugPrint("📨 [CHAT] Message text: ${message.text}");
        debugPrint("📨 [CHAT] Adding ReceiveChatMessage event to BLoC");
        add(ReceiveChatMessage(message));
      },
      onError: (error) {
        debugPrint("❌ [CHAT] Error in message stream: $error");
      },
      onDone: () {
        debugPrint("⚠️ [CHAT] Message stream closed");
      },
    );
    debugPrint("✅ [CHAT] Message listener setup complete");
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
