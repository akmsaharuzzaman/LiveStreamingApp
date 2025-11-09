import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/socket_service.dart';
import '../../../../core/utils/permission_helper.dart';
import '../../data/repositories/live_stream_repository.dart';
import '../../presentation/component/agora_token_service.dart';

part 'live_session_state.dart';

@injectable
class LiveSessionCubit extends Cubit<LiveSessionState> {
  LiveSessionCubit(
    this._socketService,
    this._liveStreamRepository,
  ) : super(const LiveSessionState()) {
    _remoteUsers = <int>[];
    _audioCallerUids = <int>[];
    _videoCallerUids = <int>[];
  }

  final SocketService _socketService;
  final LiveStreamRepository _liveStreamRepository;

  RtcEngine? _engine;
  Timer? _hostActivityTimer;
  Timer? _audioJoinDebounceTimer;
  DateTime? _lastHostActivity;

  StreamSubscription<bool>? _connectionStatusSub;
  StreamSubscription<List<String>>? _roomClosedSub;
  StreamSubscription<Map<String, dynamic>>? _errorMessageSub;

  late final List<int> _remoteUsers;
  late final List<int> _audioCallerUids;
  late final List<int> _videoCallerUids;
  bool _isProcessingAudioJoin = false;

  static const int _inactivityTimeoutSeconds = 60;

  Future<void> initializeSession({
    required bool isHost,
    required String? initialRoomId,
    required String userId,
  }) async {
    emit(state.copyWith(
      status: LiveSessionStatus.initializing,
      isHost: isHost,
      userId: userId,
      errorMessage: null,
      snackBar: null,
      forceExitReason: null,
    ));

    final permissionsGranted =
        await PermissionHelper.hasLiveStreamPermissions();

    if (!permissionsGranted) {
      final granted = await PermissionHelper.requestLiveStreamPermissions();
      if (!granted) {
        emit(state.copyWith(
          status: LiveSessionStatus.permissionsDenied,
          errorMessage: 'Camera and microphone permissions required',
        ));
        return;
      }
    }

    emit(state.copyWith(status: LiveSessionStatus.initializingAgora));

    final initialized = await _initializeAgoraEngine(isHost: isHost);
    if (!initialized) {
      emit(state.copyWith(status: LiveSessionStatus.error));
      return;
    }

    emit(state.copyWith(status: LiveSessionStatus.connectingSocket));

    final connected = await _socketService.connect(userId);
    if (!connected) {
      emit(state.copyWith(
        status: LiveSessionStatus.error,
        errorMessage: 'Failed to connect to live server',
      ));
      return;
    }

    _subscribeToSocketEvents();
    emit(state.copyWith(isSocketConnected: true));

    String? resolvedRoomId = initialRoomId;

    if (isHost) {
      resolvedRoomId = userId;
      final createResult = await _liveStreamRepository.createRoom(
        userId: userId,
        title: 'Live Session',
        roomType: RoomType.live,
      );

      await createResult.fold(
        (failure) async {
          emit(state.copyWith(
            status: LiveSessionStatus.error,
            errorMessage: failure.message,
          ));
        },
        (_) async {
          emit(state.copyWith(currentRoomId: resolvedRoomId));
        },
      );
    } else {
      if (resolvedRoomId == null || resolvedRoomId.isEmpty) {
        emit(state.copyWith(
          status: LiveSessionStatus.error,
          errorMessage: 'Invalid room',
        ));
        return;
      }

      final joinResult = await _liveStreamRepository.joinRoom(
        roomId: resolvedRoomId,
        userId: userId,
      );

      await joinResult.fold(
        (failure) async {
          emit(state.copyWith(
            status: LiveSessionStatus.error,
            errorMessage: failure.message,
          ));
        },
        (_) async {
          emit(state.copyWith(currentRoomId: resolvedRoomId));
        },
      );
    }

    if (state.status == LiveSessionStatus.error) {
      return;
    }

    await _joinChannelWithDynamicToken(
      channelId: resolvedRoomId,
      isHost: isHost,
    );

    emit(state.copyWith(status: LiveSessionStatus.ready));
  }

  Future<void> applyCameraState(bool isEnabled) async {
    final engine = _engine;
    if (engine == null) {
      return;
    }

    try {
      await engine.enableLocalVideo(isEnabled);
      await engine.muteLocalVideoStream(!isEnabled);
      emit(state.copyWith(isCameraEnabled: isEnabled));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('❌ Error applying camera state: $error');
        print(stackTrace);
      }
      emit(state.copyWith(
        snackBar: LiveSessionSnackBar.error('Failed to toggle camera'),
      ));
    }
  }

  Future<void> applyMicrophoneState(bool isEnabled) async {
    final engine = _engine;
    if (engine == null) {
      return;
    }

    try {
      await engine.muteLocalAudioStream(!isEnabled);
      emit(state.copyWith(isMicEnabled: isEnabled));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('❌ Error applying microphone state: $error');
        print(stackTrace);
      }
      emit(state.copyWith(
        snackBar: LiveSessionSnackBar.error('Failed to toggle microphone'),
      ));
    }
  }

  Future<void> promoteToAudioCaller() async {
    if (state.isAudioCaller) {
      return;
    }

    if (_isProcessingAudioJoin) {
      return;
    }

  if (_audioCallerUids.length >= LiveSessionState.maxAudioCallers) {
      emit(state.copyWith(
        snackBar: LiveSessionSnackBar.warning('Audio call is full'),
      ));
      return;
    }

    _isProcessingAudioJoin = true;

    if (!state.isJoiningAudioCaller) {
      emit(state.copyWith(isJoiningAudioCaller: true));
    }

    try {
      await _switchToAudioCaller();
      emit(state.copyWith(
        isJoiningAudioCaller: false,
        isAudioCaller: true,
        snackBar: state.isHost
            ? null
            : LiveSessionSnackBar.success('Joined audio call'),
      ));
    } catch (_) {
      emit(state.copyWith(
        isJoiningAudioCaller: false,
        snackBar: LiveSessionSnackBar.error('Failed to join audio call'),
      ));
    } finally {
      _isProcessingAudioJoin = false;
    }
  }

  Future<void> leaveAudioCaller() async {
    if (!state.isAudioCaller) {
      return;
    }

    try {
      await _switchToAudience();
      emit(state.copyWith(
        isAudioCaller: false,
        snackBar: LiveSessionSnackBar.success('Left audio call'),
      ));
    } catch (_) {
      emit(state.copyWith(
        snackBar: LiveSessionSnackBar.error('Failed to leave audio call'),
      ));
    }
  }

  Future<void> endSession({
    bool notifyServer = true,
  }) async {
    if (state.currentRoomId != null && notifyServer) {
      final roomId = state.currentRoomId!;
      final userId = state.userId ?? '';

      if (state.isHost) {
        await _liveStreamRepository.deleteRoom(roomId);
      } else {
        await _liveStreamRepository.leaveRoom(
          roomId: roomId,
          userId: userId,
        );
      }
    }

    await _disposeAgoraEngine();

    _connectionStatusSub?.cancel();
    _roomClosedSub?.cancel();
    _errorMessageSub?.cancel();
    _hostActivityTimer?.cancel();
    _audioJoinDebounceTimer?.cancel();

    emit(const LiveSessionState(status: LiveSessionStatus.ended));
  }

  void clearSnackBar() {
    if (state.snackBar != null) {
      emit(state.copyWith(clearSnackBar: true));
    }
  }

  void clearForceExitReason() {
    if (state.forceExitReason != null) {
      emit(state.copyWith(clearForceExitReason: true));
    }
  }

  void _subscribeToSocketEvents() {
    _connectionStatusSub =
        _socketService.connectionStatusStream.listen((isConnected) {
      emit(state.copyWith(isSocketConnected: isConnected));
    });

    _roomClosedSub =
        _socketService.roomClosedStream.listen((_) {
      emit(state.copyWith(
        forceExitReason: 'Live session ended by host.',
      ));
    });

    _errorMessageSub = _socketService.errorMessageStream.listen((error) {
      final message = error['message']?.toString() ?? 'An error occurred';
      emit(state.copyWith(
        snackBar: LiveSessionSnackBar.error(message),
      ));
    });
  }

  Future<bool> _initializeAgoraEngine({required bool isHost}) async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          logConfig: LogConfig(level: LogLevel.logLevelNone),
          appId: dotenv.env['AGORA_APP_ID'] ?? '',
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      await _engine!.setClientRole(
        role: isHost
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );

      await _engine!.enableVideo();
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360),
          frameRate: 15,
          bitrate: 400,
        ),
      );

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            emit(state.copyWith(
              localUserJoined: true,
              isVideoConnecting: true,
            ));

            if (state.isHost) {
              Future.delayed(const Duration(milliseconds: 500), () async {
                await _applyCameraPreference();
                emit(state.copyWith(
                  isLocalVideoReady: true,
                  isVideoReady: true,
                  isVideoConnecting: false,
                ));
              });
            }
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!_remoteUsers.contains(remoteUid)) {
              _remoteUsers.add(remoteUid);
            }

            emit(state.copyWith(
              remoteUsers: List<int>.from(_remoteUsers),
              remoteUid: state.remoteUid ?? remoteUid,
            ));

            _evaluateHostActivity();
          },
          onUserOffline: (connection, remoteUid, reason) {
            _remoteUsers.remove(remoteUid);
            _audioCallerUids.remove(remoteUid);
            _videoCallerUids.remove(remoteUid);

            emit(state.copyWith(
              remoteUsers: List<int>.from(_remoteUsers),
              audioCallerUids: List<int>.from(_audioCallerUids),
              videoCallerUids: List<int>.from(_videoCallerUids),
              remoteUid: _remoteUsers.isNotEmpty ? _remoteUsers.first : null,
            ));

            _evaluateHostActivity();
          },
          onRemoteVideoStateChanged:
              (connection, remoteUid, state, reason, elapsed) {
            if (state == RemoteVideoState.remoteVideoStateDecoding) {
              if (!_videoCallerUids.contains(remoteUid)) {
                _videoCallerUids.add(remoteUid);
              }
              emit(this.state.copyWith(
                    videoCallerUids: List<int>.from(_videoCallerUids),
                    isVideoReady: true,
                    isVideoConnecting: false,
                  ));
            }

            if (state == RemoteVideoState.remoteVideoStateStopped) {
              _videoCallerUids.remove(remoteUid);
              emit(this.state.copyWith(
                    videoCallerUids: List<int>.from(_videoCallerUids),
                  ));
            }
            _evaluateHostActivity();
          },
          onRemoteAudioStateChanged:
              (connection, remoteUid, state, reason, elapsed) {
            if (state == RemoteAudioState.remoteAudioStateDecoding &&
                !_audioCallerUids.contains(remoteUid) &&
                _audioCallerUids.length < LiveSessionState.maxAudioCallers) {
              _audioCallerUids.add(remoteUid);
              emit(this.state.copyWith(
                    audioCallerUids: List<int>.from(_audioCallerUids),
                  ));
            }

            if (state == RemoteAudioState.remoteAudioStateStopped) {
              _audioCallerUids.remove(remoteUid);
              emit(this.state.copyWith(
                    audioCallerUids: List<int>.from(_audioCallerUids),
                  ));
            }
          },
        ),
      );

      emit(state.copyWith(engine: _engine));
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('❌ Error initializing Agora engine: $error');
        print(stackTrace);
      }
      emit(state.copyWith(
        errorMessage: 'Failed to initialize live session',
      ));
      return false;
    }
  }

  Future<void> _joinChannelWithDynamicToken({
    required String channelId,
    required bool isHost,
  }) async {
    try {
      final result = await AgoraTokenService.getRtcToken(
        channelName: channelId,
        role: isHost ? 'publisher' : 'subscriber',
      );

      if (result.token.isNotEmpty) {
        await _engine?.joinChannel(
          token: result.token,
          channelId: channelId,
          uid: 0,
          options: const ChannelMediaOptions(),
        );
        return;
      }

      emit(state.copyWith(
        snackBar: LiveSessionSnackBar.warning('Using fallback token'),
      ));
      await _joinChannelWithStaticToken(channelId: channelId);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('❌ Error generating token: $error');
        print(stackTrace);
      }
      emit(state.copyWith(
        snackBar: LiveSessionSnackBar.warning('Using fallback token'),
      ));
      await _joinChannelWithStaticToken(channelId: channelId);
    }
  }

  Future<void> _joinChannelWithStaticToken({required String channelId}) async {
    await _engine?.joinChannel(
      token: dotenv.env['AGORA_TOKEN'] ?? '',
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> _switchToAudioCaller() async {
    await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine?.enableLocalAudio(true);
    await _engine?.enableLocalVideo(false);
    await _engine?.muteLocalVideoStream(true);
    await _engine?.muteLocalAudioStream(false);
    emit(state.copyWith(isCameraEnabled: false, isMicEnabled: true));
  }

  Future<void> _switchToAudience() async {
    await _engine?.setClientRole(role: ClientRoleType.clientRoleAudience);
    await _engine?.enableLocalAudio(false);
    await _engine?.enableLocalVideo(false);
    await _engine?.muteLocalAudioStream(true);
    emit(state.copyWith(isCameraEnabled: false, isMicEnabled: false));
  }

  Future<void> _applyCameraPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFrontCamera = prefs.getBool('is_front_camera') ?? true;

      if (!isFrontCamera) {
        await _engine?.switchCamera();
      }
    } catch (error) {
      if (kDebugMode) {
        print('⚠️ Error applying camera preference: $error');
      }
    }
  }

  void _evaluateHostActivity() {
    if (state.isHost) {
      return;
    }

    final hasVideoBroadcasters =
        _remoteUsers.isNotEmpty || _videoCallerUids.isNotEmpty;

    if (!hasVideoBroadcasters) {
      _hostActivityTimer ??=
          Timer(const Duration(seconds: _inactivityTimeoutSeconds), () {
        emit(state.copyWith(
          forceExitReason: 'Host disconnected. Live session ended.',
        ));
      });
    } else {
      _hostActivityTimer?.cancel();
      _hostActivityTimer = null;
      _lastHostActivity = DateTime.now();
    }
  }

  Future<void> _disposeAgoraEngine() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.stopPreview();
      await _engine?.release();
    } catch (error) {
      if (kDebugMode) {
        print('⚠️ Error disposing Agora engine: $error');
      }
    } finally {
      _engine = null;
    }
  }

  @override
  Future<void> close() {
    _connectionStatusSub?.cancel();
    _roomClosedSub?.cancel();
    _errorMessageSub?.cancel();
    _hostActivityTimer?.cancel();
    _audioJoinDebounceTimer?.cancel();
    return super.close();
  }
}
