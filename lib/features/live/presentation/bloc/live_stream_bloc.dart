import 'dart:async';
import 'package:flutter/foundation.dart';
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
  StreamSubscription? _bannedUserSubscription;

  List<JoinedUserModel>? _initialViewersBuffer;

  // Timer for duration updates
  Timer? _durationTimer;
  DateTime? _streamStartTime;

  // Flag to prevent multiple bonus API calls
  bool _isCallingBonusAPI = false;

  LiveStreamBloc(this._repository, this._socketService)
    : super(const LiveStreamInitial()) {
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
    on<UserBannedNotification>(_onUserBannedNotification);
    on<UpdateActiveRoom>(_onUpdateActiveRoom);
    on<SeedInitialViewers>(_onSeedInitialViewers);
  }

  Future<void> _onInitialize(
    InitializeLiveStream event,
    Emitter<LiveStreamState> emit,
  ) async {
    emit(const LiveStreamLoading());

    try {
      // Setup socket listeners
      _setupSocketListeners();

      // ✅ Start duration timer with initial duration from room data
      // If joining existing room, use the elapsed time; if host, start from 0
      _startDurationTimer(event.initialDurationSeconds ?? 0);

      emit(
        LiveStreamStreaming(
          roomId: event.roomId ?? '',
          isHost: event.isHost,
          userId: event.hostUserId ?? '',
          duration: Duration(seconds: event.initialDurationSeconds ?? 0),
        ),
      );

      if (_initialViewersBuffer != null && _initialViewersBuffer!.isNotEmpty) {
        final currentState = state;
        if (currentState is LiveStreamStreaming) {
          final existingIds = currentState.viewers
              .map((viewer) => viewer.id)
              .toSet();
          final additions = _initialViewersBuffer!
              .where(
                (viewer) =>
                    viewer.id != currentState.userId &&
                    !existingIds.contains(viewer.id),
              )
              .toList();

          if (additions.isNotEmpty) {
            emit(
              currentState.copyWith(
                viewers: List<JoinedUserModel>.from(currentState.viewers)
                  ..addAll(additions),
              ),
            );
          }
        }
        _initialViewersBuffer = null;
      }
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

      result.fold((failure) => emit(LiveStreamError(failure.message)), (_) {
        // Room created successfully
        // The actual room ID will come from socket response
      });
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

      result.fold((failure) => emit(LiveStreamError(failure.message)), (_) {
        // Joined successfully
      });
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
      debugPrint(' \n \n Current state: $currentState \n \n');
      if (currentState is LiveStreamStreaming) {
        debugPrint(' \n \n Current state: $currentState \n \n');
        debugPrint(' \n \n Current state isHost: ${currentState.isHost} \n \n');
        // Stop timer
        _durationTimer?.cancel();

        // Delete room (host only)
        // if (currentState.isHost) {
          debugPrint(' \n \n Deleting room: ${currentState.roomId} \n \n');
          await _repository.deleteRoom(currentState.roomId);
        // }

        emit(
          LiveStreamEnded(
            roomId: currentState.roomId,
            totalDuration: currentState.duration,
            earnedDiamonds: currentState.totalBonusDiamonds,
            totalViewers: currentState.viewers.length,
          ),
        );
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
      final newDuration = event.duration;

      // Check for bonus milestone (every 50 minutes by default)
      const bonusIntervalMinutes = 50;
      if (currentState.isHost &&
          newDuration.inMinutes >= bonusIntervalMinutes) {
        final currentMilestone =
            (newDuration.inMinutes ~/ bonusIntervalMinutes) *
            bonusIntervalMinutes;

        // Call bonus API if we've reached a new milestone
        if (currentMilestone > currentState.lastBonusMilestone) {
          add(CallDailyBonus(isStreamEnd: false));
          emit(
            currentState.copyWith(
              duration: newDuration,
              lastBonusMilestone: currentMilestone,
            ),
          );
          return;
        }
      }

      emit(currentState.copyWith(duration: newDuration));
    }
  }

  void _onUserJoined(UserJoined event, Emitter<LiveStreamState> emit) {
    final currentState = state;
    if (currentState is LiveStreamStreaming) {
      final viewers = List<JoinedUserModel>.from(currentState.viewers);

      // Don't add if already exists
      if (!viewers.any((v) => v.id == event.userId)) {
        viewers.add(
          JoinedUserModel(
            id: event.userId,
            name: event.userName,
            avatar: event.avatar ?? '',
            uid: event.uid ?? '',
            diamonds: 0,
          ),
        );

        emit(currentState.copyWith(viewers: viewers));
      }
    }
  }

  void _onUserLeft(UserLeft event, Emitter<LiveStreamState> emit) {
    final currentState = state;
    if (currentState is LiveStreamStreaming) {
      final viewers = List<JoinedUserModel>.from(currentState.viewers);
      viewers.removeWhere((v) => v.id == event.userId);

      emit(currentState.copyWith(viewers: viewers));
    }
  }

  void _onToggleCamera(ToggleCamera event, Emitter<LiveStreamState> emit) {
    final currentState = state;
    if (currentState is LiveStreamStreaming) {
      // ✅ SECURITY: Only hosts can toggle camera
      // Viewers/audio callers cannot turn on their own camera
      if (currentState.isHost) {
        emit(
          currentState.copyWith(isCameraEnabled: !currentState.isCameraEnabled),
        );
      } else {
        // ⚠️ Non-host attempted to toggle camera - silently ignore
        // This prevents camera access for viewers/callers
      }
    }
  }

  void _onToggleMicrophone(
    ToggleMicrophone event,
    Emitter<LiveStreamState> emit,
  ) {
    final currentState = state;
    if (currentState is LiveStreamStreaming) {
      // ✅ SECURITY: Hosts can always toggle microphone
      // Audio callers can also toggle (already in call)
      // Viewers cannot toggle microphone
      emit(currentState.copyWith(isMicEnabled: !currentState.isMicEnabled));
    }
  }

  Future<void> _onCallDailyBonus(
    CallDailyBonus event,
    Emitter<LiveStreamState> emit,
  ) async {
    // Prevent multiple simultaneous API calls (except for stream end)
    if (!event.isStreamEnd && _isCallingBonusAPI) {
      return;
    }

    try {
      final currentState = state;
      if (currentState is LiveStreamStreaming && currentState.isHost) {
        _isCallingBonusAPI = true;

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
              emit(
                currentState.copyWith(
                  totalBonusDiamonds:
                      currentState.totalBonusDiamonds + bonusDiamonds,
                ),
              );
            }
          },
        );
      }
    } finally {
      _isCallingBonusAPI = false;
    }
  }

  Future<void> _onBanUser(BanUser event, Emitter<LiveStreamState> emit) async {
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

        emit(currentState.copyWith(bannedUsers: bannedUsers, viewers: viewers));
      }
    }
  }

  void _onUserBannedNotification(
    UserBannedNotification event,
    Emitter<LiveStreamState> emit,
  ) {
    final currentState = state;
    if (currentState is LiveStreamStreaming) {
      final bannedUsers = List<String>.from(currentState.bannedUsers);

      if (!bannedUsers.contains(event.userId)) {
        bannedUsers.add(event.userId);

        // Remove from viewers
        final viewers = List<JoinedUserModel>.from(currentState.viewers);
        viewers.removeWhere((v) => v.id == event.userId);

        emit(currentState.copyWith(bannedUsers: bannedUsers, viewers: viewers));
      }
    }
  }

  void _onUpdateActiveRoom(
    UpdateActiveRoom event,
    Emitter<LiveStreamState> emit,
  ) {
    final currentState = state;
    if (currentState is LiveStreamStreaming &&
        currentState.roomId != event.roomId) {
      emit(currentState.copyWith(roomId: event.roomId));
    }
  }

  void _onSeedInitialViewers(
    SeedInitialViewers event,
    Emitter<LiveStreamState> emit,
  ) {
    if (event.viewers.isEmpty) {
      return;
    }

    final currentState = state;
    final sanitized = event.viewers;

    if (currentState is LiveStreamStreaming) {
      final existingIds = currentState.viewers
          .map((viewer) => viewer.id)
          .toSet();
      final additions = sanitized
          .where(
            (viewer) =>
                viewer.id != currentState.userId &&
                !existingIds.contains(viewer.id),
          )
          .toList();

      if (additions.isEmpty) {
        return;
      }

      emit(
        currentState.copyWith(
          viewers: List<JoinedUserModel>.from(currentState.viewers)
            ..addAll(additions),
        ),
      );
      return;
    }

    final buffer = _initialViewersBuffer ?? <JoinedUserModel>[];
    final bufferIds = buffer.map((viewer) => viewer.id).toSet();
    final additions = sanitized
        .where((viewer) => !bufferIds.contains(viewer.id))
        .toList();

    if (additions.isEmpty) {
      return;
    }

    buffer.addAll(additions);
    _initialViewersBuffer = buffer;
  }

  void _setupSocketListeners() {
    _userJoinedSubscription = _socketService.userJoinedStream.listen((data) {
      add(
        UserJoined(
          userId: data.id,
          userName: data.name,
          avatar: data.avatar,
          uid: data.uid,
        ),
      );
    });

    _userLeftSubscription = _socketService.userLeftStream.listen((data) {
      add(UserLeft(data.id));
    });

    _bannedUserSubscription = _socketService.bannedUserStream.listen((data) {
      add(UserBannedNotification(userId: data.targetId, message: data.message));
    });
  }

  void _startDurationTimer(int initialDurationSeconds) {
    // ✅ Initialize with existing elapsed time (for viewers joining mid-stream)
    // This ensures duration counter continues from where it was, not from zero
    int elapsedSeconds = initialDurationSeconds;
    _streamStartTime = DateTime.now().subtract(
      Duration(seconds: elapsedSeconds),
    );

    print(
      '⏱️ [DURATION] Starting timer with initial offset: ${elapsedSeconds}s (${elapsedSeconds ~/ 60}m ${elapsedSeconds % 60}s)',
    );

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
    _bannedUserSubscription?.cancel();
    return super.close();
  }
}
