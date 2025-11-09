import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/repositories/live_stream_repository.dart';
import 'live_stream_event.dart';
import 'live_stream_state.dart';
import '../../../../core/network/models/joined_user_model.dart';
import '../../../../core/network/socket_service.dart';

@injectable
class LiveStreamBloc extends Bloc<LiveStreamEvent, LiveStreamState> {
  final LiveStreamRepository _repository;
  final SocketService _socketService;

  // Subscriptions for cleanup
  StreamSubscription? _userJoinedSubscription;
  StreamSubscription? _userLeftSubscription;

  // Timer for duration updates
  Timer? _durationTimer;
  DateTime? _streamStartTime;

  LiveStreamBloc(
    this._repository,
    this._socketService,
  ) : super(const LiveStreamInitial()) {
    on<InitializeLiveStream>(_onInitialize);
    on<CreateRoom>(_onCreateRoom);
    on<JoinRoom>(_onJoinRoom);
    on<LeaveRoom>(_onLeaveRoom);
    on<EndLiveStream>(_onEndLiveStream);
    on<UpdateStreamDuration>(_onUpdateDuration);
    on<UserJoined>(_onUserJoined);
    on<UserLeft>(_onUserLeft);
    on<ToggleCamera>(_onToggleCamera);
    on<ToggleMicrophone>(_onToggleMicrophone);
    on<CallDailyBonus>(_onCallDailyBonus);
    on<BanUser>(_onBanUser);
  }

  Future<void> _onInitialize(
    InitializeLiveStream event,
    Emitter<LiveStreamState> emit,
  ) async {
    emit(const LiveStreamLoading());

    try {
      // Setup socket listeners
      _setupSocketListeners();

      // Start duration timer
      _startDurationTimer();

      emit(LiveStreamStreaming(
        roomId: event.roomId ?? '',
        isHost: event.isHost,
        userId: event.hostUserId ?? '',
      ));
    } catch (e) {
      emit(LiveStreamError('Failed to initialize: $e'));
    }
  }

  Future<void> _onCreateRoom(
    CreateRoom event,
    Emitter<LiveStreamState> emit,
  ) async {
    try {
      final result = await _repository.createRoom(
        userId: event.userId,
        title: event.title,
        roomType: event.roomType,
      );

      result.fold(
        (failure) => emit(LiveStreamError(failure.message)),
        (_) {
          // Room created successfully
          // The actual room ID will come from socket response
        },
      );
    } catch (e) {
      emit(LiveStreamError('Failed to create room: $e'));
    }
  }

  Future<void> _onJoinRoom(
    JoinRoom event,
    Emitter<LiveStreamState> emit,
  ) async {
    try {
      final result = await _repository.joinRoom(
        roomId: event.roomId,
        userId: event.userId,
      );

      result.fold(
        (failure) => emit(LiveStreamError(failure.message)),
        (_) {
          // Joined successfully
        },
      );
    } catch (e) {
      emit(LiveStreamError('Failed to join room: $e'));
    }
  }

  Future<void> _onLeaveRoom(
    LeaveRoom event,
    Emitter<LiveStreamState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is LiveStreamStreaming) {
        await _repository.leaveRoom(
          roomId: currentState.roomId,
          userId: currentState.userId,
        );
      }
    } catch (e) {
      emit(LiveStreamError('Failed to leave room: $e'));
    }
  }

  Future<void> _onEndLiveStream(
    EndLiveStream event,
    Emitter<LiveStreamState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is LiveStreamStreaming) {
        // Stop timer
        _durationTimer?.cancel();

        // Delete room (host only)
        if (currentState.isHost) {
          await _repository.deleteRoom(currentState.roomId);
        }

        emit(LiveStreamEnded(
          roomId: currentState.roomId,
          totalDuration: currentState.duration,
          earnedDiamonds: currentState.totalBonusDiamonds,
          totalViewers: currentState.viewers.length,
        ));
      }
    } catch (e) {
      emit(LiveStreamError('Failed to end stream: $e'));
    }
  }

  void _onUpdateDuration(
    UpdateStreamDuration event,
    Emitter<LiveStreamState> emit,
  ) {
    final currentState = state;
    if (currentState is LiveStreamStreaming) {
      emit(currentState.copyWith(duration: event.duration));
    }
  }

  void _onUserJoined(
    UserJoined event,
    Emitter<LiveStreamState> emit,
  ) {
    final currentState = state;
    if (currentState is LiveStreamStreaming) {
      final viewers = List<JoinedUserModel>.from(currentState.viewers);
      
      // Don't add if already exists
      if (!viewers.any((v) => v.id == event.userId)) {
        viewers.add(JoinedUserModel(
          id: event.userId,
          name: event.userName,
          avatar: event.avatar ?? '',
          uid: event.uid ?? '',
          diamonds: 0,
        ));
        
        emit(currentState.copyWith(viewers: viewers));
      }
    }
  }

  void _onUserLeft(
    UserLeft event,
    Emitter<LiveStreamState> emit,
  ) {
    final currentState = state;
    if (currentState is LiveStreamStreaming) {
      final viewers = List<JoinedUserModel>.from(currentState.viewers);
      viewers.removeWhere((v) => v.id == event.userId);
      
      emit(currentState.copyWith(viewers: viewers));
    }
  }

  void _onToggleCamera(
    ToggleCamera event,
    Emitter<LiveStreamState> emit,
  ) {
    final currentState = state;
    if (currentState is LiveStreamStreaming) {
      emit(currentState.copyWith(
        isCameraEnabled: !currentState.isCameraEnabled,
      ));
    }
  }

  void _onToggleMicrophone(
    ToggleMicrophone event,
    Emitter<LiveStreamState> emit,
  ) {
    final currentState = state;
    if (currentState is LiveStreamStreaming) {
      emit(currentState.copyWith(
        isMicEnabled: !currentState.isMicEnabled,
      ));
    }
  }

  Future<void> _onCallDailyBonus(
    CallDailyBonus event,
    Emitter<LiveStreamState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is LiveStreamStreaming && currentState.isHost) {
        final totalMinutes = currentState.duration.inMinutes;
        
        final result = await _repository.callDailyBonus(
          totalMinutes: totalMinutes,
          type: 'video',
        );

        result.fold(
          (failure) {
            // Silent fail for bonus
          },
          (bonusDiamonds) {
            if (bonusDiamonds > 0) {
              emit(currentState.copyWith(
                totalBonusDiamonds: currentState.totalBonusDiamonds + bonusDiamonds,
              ));
            }
          },
        );
      }
    } catch (e) {
      // Silent fail for bonus
    }
  }

  Future<void> _onBanUser(
    BanUser event,
    Emitter<LiveStreamState> emit,
  ) async {
    final currentState = state;
    if (currentState is LiveStreamStreaming) {
      final bannedUsers = List<String>.from(currentState.bannedUsers);
      
      if (!bannedUsers.contains(event.userId)) {
        bannedUsers.add(event.userId);
        
        // Remove from viewers
        final viewers = List<JoinedUserModel>.from(currentState.viewers);
        viewers.removeWhere((v) => v.id == event.userId);

        // Emit ban via repository
        await _repository.banUser(
          roomId: currentState.roomId,
          userId: event.userId,
        );
        
        emit(currentState.copyWith(
          bannedUsers: bannedUsers,
          viewers: viewers,
        ));
      }
    }
  }

  void _setupSocketListeners() {
    _userJoinedSubscription = _socketService.userJoinedStream.listen((data) {
      add(UserJoined(
        userId: data.id,
        userName: data.name,
        avatar: data.avatar,
        uid: data.uid,
      ));
    });

    _userLeftSubscription = _socketService.userLeftStream.listen((data) {
      add(UserLeft(data.id));
    });
  }

  void _startDurationTimer() {
    _streamStartTime = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_streamStartTime != null) {
        final duration = DateTime.now().difference(_streamStartTime!);
        add(UpdateStreamDuration(duration));
      }
    });
  }

  @override
  Future<void> close() {
    _durationTimer?.cancel();
    _userJoinedSubscription?.cancel();
    _userLeftSubscription?.cancel();
    return super.close();
  }
}
