import 'dart:async';
import 'dart:convert';
import 'package:dlstarlive/features/live_audio/data/models/audio_member_model.dart';
import 'package:dlstarlive/features/live_audio/data/models/joined_seat.dart';
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
  // Room events
  StreamSubscription? _roomDetailsSubscription;
  StreamSubscription? _createRoomSubscription;
  StreamSubscription? _joinRoomSubscription;
  StreamSubscription? _leaveRoomSubscription;
  StreamSubscription? _userLeftSubscription;
  // Seat events
  StreamSubscription? _joinSeatSubscription;
  StreamSubscription? _leaveSeatSubscription;
  StreamSubscription? _removeFromSeatSubscription;
  // Chat events
  StreamSubscription? _sendMessageSubscription;
  // User management events
  StreamSubscription? _banUserSubscription;
  StreamSubscription? _muteUserSubscription;
  StreamSubscription? _closeRoomSubscription;
  // Host bonus events
  StreamSubscription? _updateHostBonusSubscription;
  // Sent audio gifts events
  StreamSubscription? _sentAudioGiftsSubscription;
  // Error handling
  StreamSubscription? _errorSubscription;

  // Timers
  Timer? _streamTimer;
  Timer? _hostActivityTimer;

  AudioRoomBloc(this._repository) : super(AudioRoomInitial()) {
    _setupEventHandlers();
  }

  AudioRoomRepository get repository => _repository;

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
    on<GetRoomDetailsEvent>(_onGetRoomDetails);
    on<GetAllRoomsEvent>(_onGetAllRooms);

    // Seat events
    on<JoinSeatEvent>(_onJoinSeat);
    on<LeaveSeatEvent>(_onLeaveSeat);
    on<RemoveFromSeatEvent>(_onRemoveFromSeat);
    on<MuteUserFromSeatEvent>(_onMuteUserFromSeat);

    // Chat events
    on<SendMessageEvent>(_onSendMessage);

    // User management events
    on<BanUserEvent>(_onBanUser);
    // on<UnbanUserEvent>(_onUnbanUser);
    on<MuteUnmuteUserEvent>(_onMuteUnmuteUser);

    // Agora events
    on<UpdateBroadcasterStatusEvent>(_onUpdateBroadcasterStatus);

    // UI events
    on<EndLiveStreamEvent>(_onEndLiveStream);
    on<PlayAnimationEvent>(_onPlayAnimation);
    on<AnimationCompletedEvent>(_onAnimationCompleted);

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
    on<UserJoinedEvent>(_onUserJoined);

    // Helper method events
    on<UpdateListenersEvent>(_onUpdateListeners);
    on<SeatJoinedEvent>(_onSeatJoined);
    on<SeatLeftEvent>(_onSeatLeft);
    on<UpdateActiveSpeakerEvent>(_onUpdateActiveSpeaker);
  }

  void _setupSocketSubscriptions() {
    // Cancel existing subscriptions
    _cancelSubscriptions();

    // Connection status
    _connectionSubscription = _repository.connectionStatusStream.listen((isConnected) {
      if (state is AudioRoomConnected) {
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

        final currentState = state;
        String? userId;
        if (currentState is AudioRoomConnected) {
          userId = currentState.userId;
        } else if (currentState is AudioRoomLoaded) {
          userId = currentState.userId;
        }

        if (userId != null) {
          add(InitializeWithRoomDataEvent(roomData: roomData, isHost: true, userId: userId));
        }
        debugPrint("✅ Socket: Emitted AudioRoomLoaded for created room with roomId: '$effectiveRoomId'");
      },
      onError: (error) {
        debugPrint("❌ Socket: Room creation failed - $error");
      },
    );

    // Room joining
    _joinRoomSubscription = _repository.joinRoomStream.listen((member) {
      debugPrint("🔌  Join Room: Room joined - User: ${member.name}");
      if (state is AudioRoomLoaded) {
        final currentState = state as AudioRoomLoaded;
        // Refresh room details to get the most up-to-date member list
        if (currentState.currentRoomId != null) {
          add(GetRoomDetailsEvent(roomId: currentState.currentRoomId!));
        }
      }
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
      _handleSeatLeft(data, isRemoval: false);
    });

    _removeFromSeatSubscription = _repository.removeFromSeatStream.listen((data) {
      _handleSeatLeft(data, isRemoval: true);
    });

    // Chat messages
    _sendMessageSubscription = _repository.sendMessageStream.listen((message) {
      add(NewMessageReceivedEvent(message: message));
    });

    // User management
    _banUserSubscription = _repository.banUserStream.listen((List<String> data) {
      add(UserBannedEvent(targetIdList: data));
    });

    _muteUserSubscription = _repository.muteUnmuteUserStream.listen((data) {
      add(UserMutedEvent(targetId: data.targetId));
    });

    // Host bonus updates
    _updateHostBonusSubscription = _repository.updateHostBonusStream.listen((hostBonus) {
      if (state is AudioRoomLoaded) {
        final currentState = state as AudioRoomLoaded;
        if (currentState.roomData != null) {
          // Update roomData with new hostBonus
          final updatedRoomData = currentState.roomData!.copyWith(hostBonus: hostBonus);
          add(UpdateRoomDataEvent(roomData: updatedRoomData));
          debugPrint('💰 Bloc: Updated host bonus to $hostBonus');
        }
      }
    });

    // Sent audio gifts
    _sentAudioGiftsSubscription = _repository.sentAudioGiftsStream.listen((gift) {
      add(PlayAnimationEvent(giftDetails: gift));
      debugPrint('💰 Bloc: Updated gift to $gift');
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
      debugPrint("❌ Socket: Error Event received - ${error['message']}");

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
    _removeFromSeatSubscription?.cancel();
    _sendMessageSubscription?.cancel();
    _banUserSubscription?.cancel();
    _muteUserSubscription?.cancel();
    _updateHostBonusSubscription?.cancel();
    _sentAudioGiftsSubscription?.cancel();
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

    emit(AudioRoomLoading());

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
      } else {
        debugPrint("🎯 Bloc: Room created successfully");
        // get room details
        final roomDetails = await _repository.getRoomDetails(event.roomId);
        debugPrint("🎯 Bloc: Room details: $roomDetails");
        if (roomDetails != null) {
          emit(
            AudioRoomLoaded(
              roomData: roomDetails,
              currentRoomId: event.roomId,
              isHost: true,
              isConnected: true,
              listeners: [],
              chatMessages: [],
            ),
          );
        }
        debugPrint("🎯 Bloc: Room loaded successfully");
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
    final isHost = event.roomData.hostDetails.id == event.userId;
    if (event.roomData.bannedUsers.contains(event.userId)) {
      emit(const AudioRoomError(message: 'You are banned from this room'));
    } else {
      emit(
        AudioRoomLoaded(
          roomData: event.roomData,
          currentRoomId: event.roomData.roomId,
          isHost: isHost,
          isConnected: true,
          listeners: event.roomData.membersDetails,
          chatMessages: event.roomData.messages,
          userId: event.userId,
        ),
      );
    }
    debugPrint(
      "✅ Bloc: Emitted AudioRoomLoaded with room data, listeners: ${event.roomData.membersDetails.length}, messages: ${event.roomData.messages.length}",
    );
  }

  Future<void> _onJoinRoom(JoinRoomEvent event, Emitter<AudioRoomState> emit) async {
    // Fire-and-forget: The UI is already optimistic.
    await _repository.joinRoom(event.roomId);
  }

  Future<void> _onLeaveRoom(LeaveRoomEvent event, Emitter<AudioRoomState> emit) async {
    final success = await _repository.leaveRoom(event.roomId);
    if (success && state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      emit(currentState.copyWith(currentRoomId: null));
    }
  }

  Future<void> _onGetRoomDetails(GetRoomDetailsEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.getRoomDetails(event.roomId);
  }

  Future<void> _onGetAllRooms(GetAllRoomsEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.getRooms();
  }

  void _onJoinSeat(JoinSeatEvent event, Emitter<AudioRoomState> emit) {
    _repository.joinSeat(roomId: event.roomId, seatKey: event.seatKey, targetId: event.targetId);
  }

  void _onLeaveSeat(LeaveSeatEvent event, Emitter<AudioRoomState> emit) {
    _repository.leaveSeat(roomId: event.roomId, seatKey: event.seatKey, targetId: event.targetId);
  }

  Future<void> _onRemoveFromSeat(RemoveFromSeatEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.removeFromSeat(roomId: event.roomId, seatKey: event.seatKey, targetId: event.targetId);
  }

  Future<void> _onMuteUserFromSeat(MuteUserFromSeatEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.muteUserFromSeat(roomId: event.roomId, seatKey: event.seatKey, targetId: event.targetId);
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
    await _repository.banUser(event.targetUserId);
  }

  // Future<void> _onUnbanUser(UnbanUserEvent event, Emitter<AudioRoomState> emit) async {
  //   await _repository.unbanUser(event.userId);
  // }

  Future<void> _onMuteUnmuteUser(MuteUnmuteUserEvent event, Emitter<AudioRoomState> emit) async {
    await _repository.muteUnmuteUser(event.targetUserId);
  }

  void _onUpdateBroadcasterStatus(UpdateBroadcasterStatusEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      emit(currentState.copyWith(isBroadcaster: event.isBroadcaster));
    }
  }

  void _onEndLiveStream(EndLiveStreamEvent event, Emitter<AudioRoomState> emit) {
    _stopStreamTimer();
    emit(const AudioRoomClosed(reason: 'Live stream ended'));
  }

  void _onPlayAnimation(PlayAnimationEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      emit(currentState.copyWith(playAnimation: true, giftDetails: event.giftDetails));
    }
  }

  void _onAnimationCompleted(AnimationCompletedEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      emit(currentState.copyWith(playAnimation: false, giftDetails: null));
    }
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
    final currentState = state;
    if (currentState is AudioRoomLoaded) {
      // Determine if the current user is a broadcaster
      final seats = event.roomData.seatsData.seats?.values ?? [];
      final isBroadcaster = seats.any((seat) => seat.member?.id == currentState.userId);

      // If already loaded, just update the data
      emit(
        currentState.copyWith(
          roomData: event.roomData,
          isBroadcaster: isBroadcaster,
          listeners: event.roomData.membersDetails,
        ),
      );
    } else if (currentState is AudioRoomConnected) {
      // If we are connected but not yet loaded, emit a new Loaded state
      final isHost = event.roomData.hostDetails.id == currentState.userId;
      emit(
        AudioRoomLoaded(
          roomData: event.roomData,
          currentRoomId: event.roomData.roomId,
          isHost: isHost,
          isConnected: currentState.isConnected,
          listeners: event.roomData.membersDetails,
          chatMessages: event.roomData.messages,
          userId: currentState.userId,
        ),
      );
    }
  }

  void _onClearRoomId(ClearRoomIdEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      emit(currentState.copyWith(currentRoomId: null));
    }
  }

  void _onNewMessageReceived(NewMessageReceivedEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      final updatedMessages = List<AudioChatModel>.from(currentState.chatMessages)..add(event.message);
      // Keep only last 20 messages
      if (updatedMessages.length > 20) {
        updatedMessages.removeAt(0);
      }

      // Handle entry animations
      final message = event.message;
      final String normalizedMessage = message.text.trim().toLowerCase();
      final dynamic entryAnimation = message.equipedStoreItems?['entry'];
      if (normalizedMessage == 'joined the room' && entryAnimation is String && entryAnimation.isNotEmpty) {
        emit(currentState.copyWith(chatMessages: updatedMessages));
      } else {
        emit(currentState.copyWith(chatMessages: updatedMessages));
      }
    }
  }

  void _onUserBanned(UserBannedEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      final updatedBannedUsers = event.targetIdList;
      final updatedListeners = List<AudioMember>.from(currentState.listeners)
        ..removeWhere((user) => event.targetIdList.contains(user.id));
      emit(currentState.copyWith(bannedUsers: updatedBannedUsers, listeners: updatedListeners));

      if (event.targetIdList.contains(currentState.userId)) {
        emit(AudioRoomError(message: "You have been kicked out from this room"));
      }
    }
  }

  void _onUserMuted(UserMutedEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      final newRoomData = currentState.roomData?.copyWith(
        mutedUsers: List<String>.from(currentState.roomData!.mutedUsers)..add(event.targetId),
      );
      emit(currentState.copyWith(roomData: newRoomData));
    }
  }

  void _onRoomClosed(RoomClosedEvent event, Emitter<AudioRoomState> emit) {
    emit(AudioRoomClosed(reason: event.reason));
  }

  void _onUserJoined(UserJoinedEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      final updatedListeners = List<AudioMember>.from(currentState.listeners)..add(event.member);
      emit(currentState.copyWith(listeners: updatedListeners));
    }
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
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      if (currentState.roomData?.seatsData == null) {
        debugPrint("❌ Socket: Received null seatsData in seat joined response, ignoring update");
        return;
      }
      final newSeats = Map<String, SeatInfo>.from(currentState.roomData!.seatsData.seats ?? {});
      newSeats[event.seatKey] = SeatInfo(member: event.member, available: false);
      final newRoomData = currentState.roomData!.copyWith(
        seatsData: currentState.roomData!.seatsData.copyWith(seats: newSeats),
      );
      emit(currentState.copyWith(roomData: newRoomData));
    }
  }

  void _onSeatLeft(SeatLeftEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      if (currentState.roomData?.seatsData == null) {
        debugPrint("❌ Socket: Received null seatsData in seat left response, ignoring update");
        return;
      }
      final newSeats = Map<String, SeatInfo>.from(currentState.roomData!.seatsData.seats ?? {});
      newSeats[event.seatKey] = SeatInfo(member: null, available: true);
      final newRoomData = currentState.roomData!.copyWith(
        seatsData: currentState.roomData!.seatsData.copyWith(seats: newSeats),
      );
      emit(currentState.copyWith(roomData: newRoomData));
    }
  }

  // Handle active speaker updates
  void _onUpdateActiveSpeaker(UpdateActiveSpeakerEvent event, Emitter<AudioRoomState> emit) {
    if (state is AudioRoomLoaded) {
      final currentState = state as AudioRoomLoaded;
      emit(currentState.copyWith(
        activeSpeakerUserId: event.userId,
        clearActiveSpeaker: event.userId == null,
      ));
    }
  }

  // Helper methods
  void _handleUserLeft(String userId) {
    // Update listeners list
    if (state is AudioRoomLoaded) {
      add(UpdateListenersEvent(userId: userId));
    }
  }

  void _handleSeatJoined(JoinedSeatModel seatData) {
    debugPrint('🪑 Join seat Bloc response: ${jsonEncode(seatData)}');
    // Update room data with new seat occupant
    final currentState = state;
    if (currentState is AudioRoomLoaded && seatData.member?.id == currentState.userId) {
      add(const UpdateBroadcasterStatusEvent(isBroadcaster: true));
    }
    if (seatData.seatKey != null) {
      add(SeatJoinedEvent(seatKey: seatData.seatKey!, member: seatData.member));
    }
  }

  void _handleSeatLeft(JoinedSeatModel seatData, {required bool isRemoval}) {
    debugPrint('🪑 Leave seat Bloc response: ${jsonEncode(seatData)}');
    // Update room data to remove seat occupant
    final currentState = state;
    if (currentState is AudioRoomLoaded) {
      final seatToUpdate = currentState.roomData?.seatsData.seats?[seatData.seatKey];
      if (seatToUpdate?.member?.id == currentState.userId) {
        add(const UpdateBroadcasterStatusEvent(isBroadcaster: false));
      }
    }
    if (seatData.seatKey != null) {
      add(SeatLeftEvent(seatKey: seatData.seatKey!));
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
