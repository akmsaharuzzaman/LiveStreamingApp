import 'dart:async';
import 'package:dlstarlive/features/live_audio/data/models/audio_member_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/repositories/audio_room_repository.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/audio_room_details.dart';
import 'audio_room_event.dart';
import 'audio_room_state.dart';

/// BLoC for managing Audio Room state and socket operations
@injectable
class AudioRoomBloc extends Bloc<AudioRoomEvent, AudioRoomState> {
  final AudioRoomRepository _repository;

  // Stream subscriptions
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _roomDetailsSubscription;
  StreamSubscription? _createRoomSubscription;
  StreamSubscription? _joinRoomSubscription;
  StreamSubscription? _leaveRoomSubscription;
  StreamSubscription? _userLeftSubscription;
  StreamSubscription? _joinSeatSubscription;
  StreamSubscription? _leaveSeatSubscription;
  StreamSubscription? _sendMessageSubscription;
  StreamSubscription? _banUserSubscription;
  StreamSubscription? _muteUserSubscription;
  StreamSubscription? _closeRoomSubscription;
  StreamSubscription? _errorSubscription;

  // Timers
  Timer? _streamTimer;
  Timer? _hostActivityTimer;

  AudioRoomBloc(this._repository) : super(AudioRoomInitial()) {
    _setupEventHandlers();
  }

  void _setupEventHandlers() {
    // Connection events
    on<ConnectToSocket>(_onConnectToSocket);
    on<DisconnectFromSocket>(_onDisconnectFromSocket);
    on<ResetBlocState>(_onResetBlocState);

    // Room events
    on<CreateRoomEvent>(_onCreateRoom);
    on<InitializeWithRoomDataEvent>(_onInitializeWithRoomData);
    on<JoinRoomEvent>(_onJoinRoom);
    on<LeaveRoomEvent>(_onLeaveRoom);
    on<DeleteRoomEvent>(_onDeleteRoom);
    on<GetRoomDetailsEvent>(_onGetRoomDetails);
    on<GetAllRoomsEvent>(_onGetAllRooms);

    // Seat events
    on<JoinSeatEvent>(_onJoinSeat);
    on<LeaveSeatEvent>(_onLeaveSeat);
    on<RemoveFromSeatEvent>(_onRemoveFromSeat);

    // Chat events
    on<SendMessageEvent>(_onSendMessage);

    // User management events
    on<BanUserEvent>(_onBanUser);
    on<UnbanUserEvent>(_onUnbanUser);
    on<MuteUnmuteUserEvent>(_onMuteUnmuteUser);

    // Agora events
    on<InitializeAgoraEvent>(_onInitializeAgora);
    on<JoinAgoraChannelEvent>(_onJoinAgoraChannel);
    on<ToggleMuteEvent>(_onToggleMute);

    // UI events
    on<EndLiveStreamEvent>(_onEndLiveStream);
    on<UpdateStreamDurationEvent>(_onUpdateStreamDuration);
    on<PlayAnimationEvent>(_onPlayAnimation);

    // Error handling
    on<HandleSocketErrorEvent>(_onHandleSocketError);

    // Socket stream events
    on<UpdateConnectionStatusEvent>(_onUpdateConnectionStatus);
    on<UpdateRoomDataEvent>(_onUpdateRoomData);
    on<ClearRoomIdEvent>(_onClearRoomId);
    on<NewMessageReceivedEvent>(_onNewMessageReceived);
    on<UserBannedEvent>(_onUserBanned);
    on<UserMutedEvent>(_onUserMuted);
    on<RoomClosedEvent>(_onRoomClosed);

    // Helper method events
    on<UpdateListenersEvent>(_onUpdateListeners);
    on<SeatJoinedEvent>(_onSeatJoined);
    on<SeatLeftEvent>(_onSeatLeft);
    on<UpdateBannedUsersEvent>(_onUpdateBannedUsers);
    on<UpdateStreamTimeEvent>(_onUpdateStreamTime);
  }

  void _setupSocketSubscriptions() {
    // Cancel existing subscriptions
    _cancelSubscriptions();

    // Connection status
    _connectionSubscription = _repository.connectionStatusStream.listen((isConnected) {
      if (state is AudioRoomLoaded) {
        add(UpdateConnectionStatusEvent(isConnected: isConnected));
      }
    });

    // Room details updates
    _roomDetailsSubscription = _repository.audioRoomDetailsStream.listen((roomData) {
      if (state is AudioRoomLoaded && roomData != null) {
        add(UpdateRoomDataEvent(roomData: roomData));
      }
    });

    // Room creation
    _createRoomSubscription = _repository.createRoomStream.listen(
      (roomData) {
        // Validate roomId before emitting state
        if (roomData.roomId.isEmpty) {
          debugPrint("⚠️ Socket: Received empty roomId in room creation response, ignoring update");
          return; // Don't emit state with empty roomId
        }

        debugPrint("🔌 Socket: Room created - Host: ${roomData.hostDetails.name}, RoomId: '${roomData.roomId}'");

        // IMPORTANT: Always update state regardless of current state type
        // Get current roomId if available
        String effectiveRoomId = roomData.roomId;
        if (state is AudioRoomLoaded) {
          final currentState = state as AudioRoomLoaded;
          // Don't overwrite existing roomId if new one is empty
          effectiveRoomId = roomData.roomId.isNotEmpty ? roomData.roomId : currentState.currentRoomId ?? '';
        }

        add(InitializeWithRoomDataEvent(roomData: roomData, isHost: true));
        debugPrint("✅ Socket: Emitted AudioRoomLoaded for created room with roomId: '$effectiveRoomId'");
      },
      onError: (error) {
        debugPrint("❌ Socket: Room creation failed - $error");
      },
    );

    // Room joining
    _joinRoomSubscription = _repository.joinRoomStream.listen((roomData) {
      // Validate roomId before emitting state
      if (roomData.roomId.isEmpty) {
        debugPrint("⚠️ Socket: Received empty roomId in join room response, ignoring update");
        return; // Don't emit state with empty roomId
      }

      debugPrint("🔌 Socket: Room joined - Host: ${roomData.hostDetails.name}, RoomId: '${roomData.roomId}'");

      // Get current roomId if available
      String effectiveRoomId = roomData.roomId;
      if (state is AudioRoomLoaded) {
        final currentState = state as AudioRoomLoaded;
        effectiveRoomId = roomData.roomId.isNotEmpty ? roomData.roomId : currentState.currentRoomId ?? '';
      }

      add(InitializeWithRoomDataEvent(roomData: roomData, isHost: false));
      debugPrint("✅ Socket: Emitted AudioRoomLoaded for joined room with roomId: '$effectiveRoomId'");
    });

    // Room leaving
    _leaveRoomSubscription = _repository.leaveRoomStream.listen((roomData) {
      if (state is AudioRoomLoaded) {
        add(const ClearRoomIdEvent());
      }
    });

    // User left
    _userLeftSubscription = _repository.userLeftStream.listen((data) {
      // Handle user leaving the room
      _handleUserLeft(data);
    });

    // Seat operations
    _joinSeatSubscription = _repository.joinSeatStream.listen((data) {
      _handleSeatJoined(data);
    });

    _leaveSeatSubscription = _repository.leaveSeatStream.listen((data) {
      _handleSeatLeft(data);
    });

    // Chat messages
    _sendMessageSubscription = _repository.sendMessageStream.listen((message) {
      add(NewMessageReceivedEvent(message: message));
    });

    // User management
    _banUserSubscription = _repository.banUserStream.listen((data) {
      add(UserBannedEvent(targetId: data.targetId));
    });

    _muteUserSubscription = _repository.muteUnmuteUserStream.listen((data) {
      add(UserMutedEvent(targetId: data.targetId));
    });

    // Room closed
    _closeRoomSubscription = _repository.closeRoomStream.listen((roomIds) {
      add(const RoomClosedEvent(reason: 'Room has been closed'));
    });

    // Errors
    // _errorSubscription = _repository.errorMessageStream.listen((error) {
    //   add(HandleSocketErrorEvent(error: error));
    // });

    // Error handling
    _errorSubscription = _repository.errorMessageStream.listen((error) {
      debugPrint("❌ Socket: Error received - ${error['message']}");

      // Special handling for "Room Already Exists" error
      if (error['message'] == 'Room Already Exists' && state is AudioRoomLoaded) {
        debugPrint("⚠️ Socket: Room already exists, will continue with current state");
        // Don't emit error state, we're already in a valid state
        return;
      }

      add(HandleSocketErrorEvent(error: error));
    });
  }

  void _cancelSubscriptions() {
    _connectionSubscription?.cancel();
    _roomDetailsSubscription?.cancel();
    _createRoomSubscription?.cancel();
    _joinRoomSubscription?.cancel();
    _leaveRoomSubscription?.cancel();
    _userLeftSubscription?.cancel();
    _joinSeatSubscription?.cancel();
    _leaveSeatSubscription?.cancel();
    _sendMessageSubscription?.cancel();
    _banUserSubscription?.cancel();
    _muteUserSubscription?.cancel();
    _closeRoomSubscription?.cancel();
    _errorSubscription?.cancel();
  }

  // Event handlers
  Future<void> _onConnectToSocket(ConnectToSocket event, Emitter<AudioRoomState> emit) async {
    emit(AudioRoomLoading());
    final success = await _repository.connect(event.userId);
    if (success) {
      _setupSocketSubscriptions();
      emit(AudioRoomConnected(userId: event.userId, isConnected: true));
    } else {
      emit(const AudioRoomError(message: 'Failed to connect to socket'));
    }
  }

  Future<void> _onDisconnectFromSocket(DisconnectFromSocket event, Emitter<AudioRoomState> emit) async {
    await _repository.disconnect();
    _cancelSubscriptions();
    emit(AudioRoomInitial());
  }

  void _onResetBlocState(ResetBlocState event, Emitter<AudioRoomState> emit) {
    // Cancel subscriptions and reset to initial state
    _cancelSubscriptions();
    emit(AudioRoomInitial());
  }

  Future<void> _onCreateRoom(CreateRoomEvent event, Emitter<AudioRoomState> emit) async {
    debugPrint(
      "🎯 Bloc: Creating room - roomId: ${event.roomId}, title: ${event.roomTitle}, seats: ${event.numberOfSeats}",
    );

    // Now make the async API call - UI already shows room
    try {
      final success = await _repository.createRoom(
        event.roomId,
        event.roomTitle ?? 'Audio Room',
        numberOfSeats: event.numberOfSeats,
      );
      debugPrint("🎯 Bloc: Room creation result - success: $success");

      // If creation failed, try to join the room instead
      if (!success) {
        debugPrint("⚠️ Bloc: Room creation failed, attempting to join room instead");
        final joinSuccess = await _repository.joinRoom(event.roomId);
        debugPrint("🎯 Bloc: Room join result after failed creation - success: $joinSuccess");
        emit(const AudioRoomError(message: 'Failed to create room state'));
      }
      // emit AudioRoomLoaded
      try {
        // Emit AudioRoomLoaded IMMEDIATELY with the roomId
        // This ensures UI shows room instantly with the correct roomId
        debugPrint("✅ Bloc: Emitting immediate AudioRoomLoaded for room creation");
        final roomLoadedState = AudioRoomLoaded(
          roomData: AudioRoomDetails(
            roomId: event.roomId,
            title: event.roomTitle ?? 'Audio Room',
            numberOfSeats: event.numberOfSeats,
            hostGifts: 0,
            hostBonus: 0,
            hostDetails: AudioMember(
              name: 'Host',
              avatar: '',
              uid: '',
              id: event.roomId, // Use roomId as host id for now
              currentLevel: 0,
              equipedStoreItems: null,
              totalGiftSent: 0,
              isMuted: false,
            ),
            premiumSeat: PremiumSeat(member: null, available: true),
            seatsData: SeatsData(seats: {}),
            messages: [],
            createdAt: DateTime.now().toIso8601String(),
            bannedUsers: [],
            members: [],
            membersDetails: [],
            mutedUsers: [],
            ranking: [],
            duration: 0,
          ),
          currentRoomId: event.roomId, // CRITICAL: roomId available immediately
          isHost: true,
          isConnected: true,
          streamStartTime: DateTime.now(),
          listeners: [],
          chatMessages: [],
        );
        debugPrint("✅ Bloc: Created AudioRoomLoaded state, emitting...");
        emit(roomLoadedState);
        debugPrint("✅ Bloc: Successfully emitted AudioRoomLoaded for room creation");
      } catch (e, stackTrace) {
        debugPrint("❌ Bloc: Failed to emit AudioRoomLoaded: $e");
        debugPrint("❌ Bloc: Stack trace: $stackTrace");
        emit(const AudioRoomError(message: 'Failed to create room state'));
        return;
      }
    } catch (e) {
      debugPrint("❌ Bloc: Room creation/join error: $e");
      emit(const AudioRoomError(message: 'Failed to create room state'));
    }
  }

  void _onInitializeWithRoomData(InitializeWithRoomDataEvent event, Emitter<AudioRoomState> emit) {
    debugPrint(
      "🎯 Bloc: Initializing with room data - Host: ${event.roomData.hostDetails.name}, Members: ${event.roomData.membersDetails.length}, RoomId: ${event.roomData.roomId}, isHost: ${event.isHost}",
    );
    emit(
      AudioRoomLoaded(
        roomData: event.roomData,
        currentRoomId: event.roomData.roomId,
        isHost: event.isHost,
        isConnected: true,
        listeners: event.roomData.membersDetails,
        chatMessages: event.roomData.messages,
      ),
    );
    debugPrint(
      "✅ Bloc: Emitted AudioRoomLoaded with room data, listeners: ${event.roomData.membersDetails.length}, messages: ${event.roomData.messages.length}",
    );
  }

  Future<void> _onJoinRoom(JoinRoomEvent event, Emitter<AudioRoomState> emit) async {
    final success = await _repository.joinRoom(event.roomId);
    if (!success) {
      emit(const AudioRoomError(message: 'Failed to join room'));
    }
  }

  Future<void> _onLeaveRoom(LeaveRoomEvent event, Emitter<AudioRoomState> emit) async {
    final success = await _repository.leaveRoom(event.roomId);
    if (success && state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      emit(currentState.copyWith(currentRoomId: null));
    }
  }

  Future<void> _onDeleteRoom(DeleteRoomEvent event, Emitter<AudioRoomState> emit) async {
    final success = await _repository.deleteRoom(event.roomId);
    if (success) {
      emit(const AudioRoomClosed(reason: 'Room deleted'));
    }
  }

  Future<void> _onGetRoomDetails(GetRoomDetailsEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.getRoomDetails(event.roomId);
  }

  Future<void> _onGetAllRooms(GetAllRoomsEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.getRooms();
  }

  Future<void> _onJoinSeat(JoinSeatEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.joinSeat(roomId: event.roomId, seatKey: event.seatKey, targetId: event.targetId);
  }

  Future<void> _onLeaveSeat(LeaveSeatEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.leaveSeat(roomId: event.roomId, seatKey: event.seatKey, targetId: event.targetId);
  }

  Future<void> _onRemoveFromSeat(RemoveFromSeatEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.removeFromSeat(roomId: event.roomId, seatKey: event.seatKey, targetId: event.targetId);
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<AudioRoomState> emit) async {
    debugPrint("🔌 Socket: Sending message to room: '${event.roomId}'");

    if (event.roomId.isEmpty) {
      debugPrint("❌ Socket: Cannot send message to empty roomId");
      emit(const AudioRoomError(message: 'Cannot send message - room ID is missing'));
      return;
    }

    await _repository.sendMessage(event.roomId, event.message);
  }

  Future<void> _onBanUser(BanUserEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.banUser(event.userId);
  }

  Future<void> _onUnbanUser(UnbanUserEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.unbanUser(event.userId);
  }

  Future<void> _onMuteUnmuteUser(MuteUnmuteUserEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.muteUnmuteUser(event.userId);
  }

  void _onInitializeAgora(InitializeAgoraEvent event, Emitter<AudioRoomState> emit) {
    // Initialize Agora SDK
    emit(AgoraInitialized());
  }

  void _onJoinAgoraChannel(JoinAgoraChannelEvent event, Emitter<AudioRoomState> emit) {
    // Join Agora channel
    emit(AgoraChannelJoined());
  }

  void _onToggleMute(ToggleMuteEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      emit(currentState.copyWith(isMuted: !currentState.isMuted));
    }
  }

  void _onEndLiveStream(EndLiveStreamEvent event, Emitter<AudioRoomState> emit) {
    _stopStreamTimer();
    emit(const AudioRoomClosed(reason: 'Live stream ended'));
  }

  void _onUpdateStreamDuration(UpdateStreamDurationEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      final newDuration = currentState.streamDuration + const Duration(seconds: 1);
      emit(currentState.copyWith(streamDuration: newDuration));
    }
  }

  void _onPlayAnimation(PlayAnimationEvent event, Emitter<AudioRoomState> emit) {
    emit(AnimationPlaying(animationUrl: event.animationUrl, title: event.title, subtitle: event.subtitle));

    // Auto-stop animation after 9 seconds
    Future.delayed(const Duration(seconds: 9), () {
      if (state is AudioRoomLoaded) {
        final currentState = state as AudioRoomLoaded;
        emit(currentState.copyWith(animationPlaying: false));
      }
    });
  }

  void _onHandleSocketError(HandleSocketErrorEvent event, Emitter<AudioRoomState> emit) {
    emit(AudioRoomError(message: event.error['message'] ?? 'Unknown socket error', errorCode: event.error['status']));
  }

  // Socket stream event handlers
  void _onUpdateConnectionStatus(UpdateConnectionStatusEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      emit(currentState.copyWith(isConnected: event.isConnected));
    }
  }

  void _onUpdateRoomData(UpdateRoomDataEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      emit(currentState.copyWith(roomData: event.roomData));
    }
  }

  void _onClearRoomId(ClearRoomIdEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      emit(currentState.copyWith(currentRoomId: null));
    }
  }

  void _onNewMessageReceived(NewMessageReceivedEvent event, Emitter<AudioRoomState> emit) {
    emit(MessageReceived(message: event.message));
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      final updatedMessages = List<AudioChatModel>.from(currentState.chatMessages)..add(event.message);
      // Keep only last 20 messages
      if (updatedMessages.length > 20) {
        updatedMessages.removeAt(0);
      }
      emit(currentState.copyWith(chatMessages: updatedMessages));
    }
  }

  void _onUserBanned(UserBannedEvent event, Emitter<AudioRoomState> emit) {
    emit(UserBanned(targetId: event.targetId));
    _handleUserBanned(event.targetId);
  }

  void _onUserMuted(UserMutedEvent event, Emitter<AudioRoomState> emit) {
    emit(UserMuted(targetId: event.targetId));
  }

  void _onRoomClosed(RoomClosedEvent event, Emitter<AudioRoomState> emit) {
    emit(AudioRoomClosed(reason: event.reason));
  }

  // Helper method event handlers
  void _onUpdateListeners(UpdateListenersEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      final updatedListeners = List<AudioMember>.from(currentState.listeners)
        ..removeWhere((user) => user.id == event.userId);
      emit(currentState.copyWith(listeners: updatedListeners));
    }
  }

  void _onSeatJoined(SeatJoinedEvent event, Emitter<AudioRoomState> emit) {
    emit(SeatJoined(seatKey: event.seatKey, member: event.member));
  }

  void _onSeatLeft(SeatLeftEvent event, Emitter<AudioRoomState> emit) {
    emit(SeatLeft(seatKey: event.seatKey));
  }

  void _onUpdateBannedUsers(UpdateBannedUsersEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      final updatedBannedUsers = List<String>.from(currentState.bannedUsers)..add(event.targetId);
      final updatedListeners = List<AudioMember>.from(currentState.listeners)
        ..removeWhere((user) => user.id == event.targetId);
      emit(currentState.copyWith(bannedUsers: updatedBannedUsers, listeners: updatedListeners));
    }
  }

  void _onUpdateStreamTime(UpdateStreamTimeEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      emit(currentState.copyWith(streamStartTime: event.startTime));
    }
  }

  // Helper methods
  void _handleUserLeft(dynamic data) {
    // Update listeners list
    if (state is AudioRoomLoaded && data is Map<String, dynamic>) {
      add(UpdateListenersEvent(userId: data['id']));
    }
  }

  void _handleSeatJoined(dynamic data) {
    // Update room data with new seat occupant
    if (state is AudioRoomLoaded && data is Map<String, dynamic>) {
      final seatData = data['data'];
      if (seatData != null && seatData['seatKey'] != null) {
        add(
          SeatJoinedEvent(
            seatKey: seatData['seatKey'],
            member: seatData['member'] != null ? AudioMember.fromJson(seatData['member']) : null,
          ),
        );
      }
    }
  }

  void _handleSeatLeft(dynamic data) {
    // Update room data to remove seat occupant
    if (data is Map<String, dynamic> && data['data'] != null) {
      final seatData = data['data'];
      if (seatData['seatKey'] != null) {
        add(SeatLeftEvent(seatKey: seatData['seatKey']));
      }
    }
  }

  void _handleUserBanned(String targetId) {
    if (state is AudioRoomLoaded) {
      add(UpdateBannedUsersEvent(targetId: targetId));
    }
  }

  // void _startStreamTimer() {
  //   if (state is AudioRoomLoaded) {
  //     final startTime = DateTime.now();
  //     add(UpdateStreamTimeEvent(startTime: startTime));

  //     _streamTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //       add(UpdateStreamDurationEvent());
  //     });
  //   }
  // }

  void _stopStreamTimer() {
    _streamTimer?.cancel();
    _streamTimer = null;
    _hostActivityTimer?.cancel();
    _hostActivityTimer = null;
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    _stopStreamTimer();
    _repository.dispose();
    return super.close();
  }
}
