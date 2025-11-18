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
  LiveSessionCubit(this._socketService, this._liveStreamRepository)
    : super(const LiveSessionState()) {
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
  int?
  _hostAgoraUid; // ✅ Track the host's Agora UID (first remote user is the host)
  bool _isProcessingAudioJoin = false;

  static const int _inactivityTimeoutSeconds = 60;

  Future<void> initializeSession({
    required bool isHost,
    required String? initialRoomId,
    required String userId,
  }) async {
    emit(
      state.copyWith(
        status: LiveSessionStatus.initializing,
        isHost: isHost,
        userId: userId,
        errorMessage: null,
        snackBar: null,
        forceExitReason: null,
      ),
    );

    final permissionsGranted =
        await PermissionHelper.hasLiveStreamPermissions();

    if (!permissionsGranted) {
      final granted = await PermissionHelper.requestLiveStreamPermissions();
      if (!granted) {
        emit(
          state.copyWith(
            status: LiveSessionStatus.permissionsDenied,
            errorMessage: 'Camera and microphone permissions required',
          ),
        );
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
      emit(
        state.copyWith(
          status: LiveSessionStatus.error,
          errorMessage: 'Failed to connect to live server',
        ),
      );
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
          emit(
            state.copyWith(
              status: LiveSessionStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
        (_) async {
          emit(state.copyWith(currentRoomId: resolvedRoomId));
        },
      );
    } else {
      if (resolvedRoomId == null || resolvedRoomId.isEmpty) {
        emit(
          state.copyWith(
            status: LiveSessionStatus.error,
            errorMessage: 'Invalid room',
          ),
        );
        return;
      }

      final joinResult = await _liveStreamRepository.joinRoom(
        roomId: resolvedRoomId,
        userId: userId,
      );

      await joinResult.fold(
        (failure) async {
          emit(
            state.copyWith(
              status: LiveSessionStatus.error,
              errorMessage: failure.message,
            ),
          );
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
      emit(
        state.copyWith(
          snackBar: LiveSessionSnackBar.error('Failed to toggle camera'),
        ),
      );
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
      emit(
        state.copyWith(
          snackBar: LiveSessionSnackBar.error('Failed to toggle microphone'),
        ),
      );
    }
  }

  Future<void> promoteToAudioCaller() async {
    debugPrint('🎤 [PROMOTE] Starting audio caller promotion...');
    debugPrint('🎤 [PROMOTE] Current isAudioCaller: ${state.isAudioCaller}');
    debugPrint('🎤 [PROMOTE] isProcessingAudioJoin: $_isProcessingAudioJoin');
    debugPrint(
      '🎤 [PROMOTE] Current audioCallerUids: $_audioCallerUids (length: ${_audioCallerUids.length})',
    );
    debugPrint(
      '🎤 [PROMOTE] maxAudioCallers: ${LiveSessionState.maxAudioCallers}',
    );

    if (state.isAudioCaller) {
      debugPrint('🎤 [PROMOTE] ❌ Already an audio caller, returning');
      return;
    }

    if (_isProcessingAudioJoin) {
      debugPrint('🎤 [PROMOTE] ❌ Already processing audio join, returning');
      return;
    }

    // ✅ IMPORTANT: Only non-hosts count against the audio caller limit
    // Exclude: local UID (0) and the host's Agora UID from the count
    final nonHostAudioCallers = _audioCallerUids
        .where((uid) => uid != 0 && uid != _hostAgoraUid)
        .length;

    debugPrint('🎤 [PROMOTE] Current audioCallerUids: $_audioCallerUids');
    debugPrint('🎤 [PROMOTE] Host Agora UID: $_hostAgoraUid');
    debugPrint(
      '🎤 [PROMOTE] Non-host audio callers: $nonHostAudioCallers / ${LiveSessionState.maxAudioCallers}',
    );

    if (!state.isHost &&
        nonHostAudioCallers >= LiveSessionState.maxAudioCallers) {
      debugPrint(
        '🎤 [PROMOTE] ❌ Audio call FULL! ($nonHostAudioCallers >= ${LiveSessionState.maxAudioCallers})',
      );
      emit(
        state.copyWith(
          snackBar: LiveSessionSnackBar.warning('Audio call is full'),
        ),
      );
      return;
    }

    if (state.isHost) {
      debugPrint(
        '🎤 [PROMOTE] ✅ User is host - allowing promotion regardless of caller count',
      );
    }

    _isProcessingAudioJoin = true;
    debugPrint(
      '🎤 [PROMOTE] ✅ Promotion allowed, setting _isProcessingAudioJoin = true',
    );

    if (!state.isJoiningAudioCaller) {
      emit(state.copyWith(isJoiningAudioCaller: true));
      debugPrint('🎤 [PROMOTE] 📤 Emitted isJoiningAudioCaller = true');
    }

    try {
      debugPrint('🎤 [PROMOTE] 🔄 Calling _switchToAudioCaller()...');
      await _switchToAudioCaller();
      debugPrint(
        '🎤 [PROMOTE] ✅ _switchToAudioCaller() completed successfully',
      );
      debugPrint(
        '🎤 [PROMOTE] 📋 audioCallerUids after switch: $_audioCallerUids (length: ${_audioCallerUids.length})',
      );

      emit(
        state.copyWith(
          isJoiningAudioCaller: false,
          isAudioCaller: true,
          snackBar: state.isHost
              ? null
              : LiveSessionSnackBar.success('Joined audio call'),
        ),
      );
      debugPrint('🎤 [PROMOTE] ✅ State emitted: isAudioCaller = true');
    } catch (e) {
      debugPrint('🎤 [PROMOTE] ❌ Error during promotion: $e');
      emit(
        state.copyWith(
          isJoiningAudioCaller: false,
          snackBar: LiveSessionSnackBar.error('Failed to join audio call'),
        ),
      );
    } finally {
      _isProcessingAudioJoin = false;
      debugPrint(
        '🎤 [PROMOTE] 🏁 Promotion complete, _isProcessingAudioJoin = false',
      );
    }
  }

  Future<void> leaveAudioCaller() async {
    if (!state.isAudioCaller) {
      return;
    }

    try {
      await _switchToAudience();
      emit(
        state.copyWith(
          isAudioCaller: false,
          snackBar: LiveSessionSnackBar.success('Left audio call'),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          snackBar: LiveSessionSnackBar.error('Failed to leave audio call'),
        ),
      );
    }
  }

  Future<void> endSession({bool notifyServer = true}) async {
    if (state.currentRoomId != null && notifyServer) {
      final roomId = state.currentRoomId!;
      final userId = state.userId ?? '';

      if (state.isHost) {
        await _liveStreamRepository.deleteRoom(roomId);
      } else {
        await _liveStreamRepository.leaveRoom(roomId: roomId, userId: userId);
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
    _connectionStatusSub = _socketService.connectionStatusStream.listen((
      isConnected,
    ) {
      emit(state.copyWith(isSocketConnected: isConnected));
    });

    _roomClosedSub = _socketService.roomClosedStream.listen((_) {
      emit(state.copyWith(forceExitReason: 'Live session ended by host.'));
    });

    _errorMessageSub = _socketService.errorMessageStream.listen((error) {
      final message = error['message']?.toString() ?? 'An error occurred';
      emit(state.copyWith(snackBar: LiveSessionSnackBar.error(message)));
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
        VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360),
          frameRate: 15,
          bitrate: 400,
          codecType: VideoCodecType.videoCodecGenericH264,
        ),
      );

      // ✅ CRITICAL FIX: Start preview for host BEFORE joining channel
      // This ensures video is ready to send when joining
      if (isHost) {
        debugPrint('🎬 [AGORA] Starting preview for host...');
        await _engine!.startPreview();
      }

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            debugPrint('✅ [AGORA] Successfully joined channel');
            emit(state.copyWith(localUserJoined: true));

            if (state.isHost) {
              // ✅ For hosts: apply camera preference and mark video ready
              Future.delayed(const Duration(milliseconds: 500), () async {
                await _applyCameraPreference();
                debugPrint('🎥 [AGORA] Host video ready');
                emit(
                  state.copyWith(
                    isLocalVideoReady: true,
                    isVideoReady: true,
                    isVideoConnecting: false,
                  ),
                );
              });
            } else {
              // ✅ For viewers: set isVideoReady=true immediately so video view is prepared
              // This prevents white screen while waiting for onUserJoined callbacks
              debugPrint('👁️ [AGORA] Viewer joined, preparing video view...');
              emit(state.copyWith(isVideoReady: true));
            }
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!_remoteUsers.contains(remoteUid)) {
              _remoteUsers.add(remoteUid);
            }

            // ✅ CRITICAL: Track the first remote UID as the host (for non-hosts)
            // Hosts already know they're hosts, so we capture the first remote user's UID
            if (!state.isHost && _hostAgoraUid == null) {
              _hostAgoraUid = remoteUid;
              debugPrint(
                '👥 [AGORA] First remote user (host) UID set: $_hostAgoraUid',
              );
            }

            debugPrint(
              '👥 [AGORA] User joined: $remoteUid, total remoteUsers=${_remoteUsers.length}',
            );

            // ✅ CRITICAL FIX: When a remote user joins, assume they have/may have video capability
            // Set isVideoReady=true so viewer can see the video stream if it arrives
            // This fixes the white screen issue when joining while caller is connected
            emit(
              state.copyWith(
                remoteUsers: List<int>.from(_remoteUsers),
                remoteUid: state.remoteUid ?? remoteUid,
                isVideoReady: true, // ✅ Enable video view for remote streams
              ),
            );

            _evaluateHostActivity();
          },
          onUserOffline: (connection, remoteUid, reason) {
            _remoteUsers.remove(remoteUid);
            _audioCallerUids.remove(remoteUid);
            _videoCallerUids.remove(remoteUid);

            emit(
              state.copyWith(
                remoteUsers: List<int>.from(_remoteUsers),
                audioCallerUids: List<int>.from(_audioCallerUids),
                videoCallerUids: List<int>.from(_videoCallerUids),
                remoteUid: _remoteUsers.isNotEmpty ? _remoteUsers.first : null,
              ),
            );

            _evaluateHostActivity();
          },
          onRemoteVideoStateChanged:
              (connection, remoteUid, state, reason, elapsed) {
                if (state == RemoteVideoState.remoteVideoStateDecoding) {
                  debugPrint(
                    '🎥 [AGORA] Remote video DECODING from $remoteUid',
                  );
                  if (!_videoCallerUids.contains(remoteUid)) {
                    _videoCallerUids.add(remoteUid);
                  }
                  // ✅ CRITICAL: Set video ready when remote video starts
                  emit(
                    this.state.copyWith(
                      videoCallerUids: List<int>.from(_videoCallerUids),
                      isVideoReady: true,
                      isVideoConnecting: false,
                    ),
                  );
                }

                if (state == RemoteVideoState.remoteVideoStateStopped) {
                  debugPrint('⏹️ [AGORA] Remote video STOPPED from $remoteUid');
                  _videoCallerUids.remove(remoteUid);
                  emit(
                    this.state.copyWith(
                      videoCallerUids: List<int>.from(_videoCallerUids),
                    ),
                  );
                }
                _evaluateHostActivity();
              },
          onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
            debugPrint(
              '🎤 [AUDIO_CALLBACK] Remote audio state changed for UID: $remoteUid',
            );
            debugPrint('🎤 [AUDIO_CALLBACK] State: $state, Reason: $reason');
            debugPrint(
              '🎤 [AUDIO_CALLBACK] Current audioCallerUids: $_audioCallerUids (length: ${_audioCallerUids.length})',
            );
            debugPrint(
              '🎤 [AUDIO_CALLBACK] maxAudioCallers: ${LiveSessionState.maxAudioCallers}',
            );

            if (state == RemoteAudioState.remoteAudioStateDecoding) {
              debugPrint(
                '🎤 [AUDIO_CALLBACK] 📥 Audio DECODING from $remoteUid',
              );
              debugPrint(
                '🎤 [AUDIO_CALLBACK] Already in list? ${_audioCallerUids.contains(remoteUid)}',
              );
              debugPrint('🎤 [AUDIO_CALLBACK] Current list: $_audioCallerUids');

              // ✅ IMPORTANT FIX: Count remote UIDs only (exclude local UID 0) for capacity check
              // Local UID (0) is just tracking, not a real remote caller
              final remoteUidCount = _audioCallerUids
                  .where((uid) => uid != 0)
                  .length;
              debugPrint(
                '🎤 [AUDIO_CALLBACK] Remote UID count (excluding local 0): $remoteUidCount / ${LiveSessionState.maxAudioCallers}',
              );
              debugPrint(
                '🎤 [AUDIO_CALLBACK] Can add more? $remoteUidCount < ${LiveSessionState.maxAudioCallers}',
              );

              if (!_audioCallerUids.contains(remoteUid) &&
                  remoteUidCount < LiveSessionState.maxAudioCallers) {
                debugPrint(
                  '🎤 [AUDIO_CALLBACK] ✅ Adding remote UID $remoteUid to audioCallerUids',
                );
                _audioCallerUids.add(remoteUid);
                debugPrint(
                  '🎤 [AUDIO_CALLBACK] audioCallerUids after add: $_audioCallerUids (length: ${_audioCallerUids.length})',
                );

                emit(
                  this.state.copyWith(
                    audioCallerUids: List<int>.from(_audioCallerUids),
                  ),
                );
              } else if (_audioCallerUids.contains(remoteUid)) {
                debugPrint(
                  '🎤 [AUDIO_CALLBACK] ⚠️ Remote UID already in list, skipping',
                );
              } else {
                debugPrint(
                  '🎤 [AUDIO_CALLBACK] ❌ Cannot add - remote UIDs FULL ($remoteUidCount >= ${LiveSessionState.maxAudioCallers})',
                );
              }
            }

            if (state == RemoteAudioState.remoteAudioStateStopped) {
              debugPrint(
                '🎤 [AUDIO_CALLBACK] ⏹️ Audio STOPPED from $remoteUid',
              );
              debugPrint(
                '🎤 [AUDIO_CALLBACK] Removing UID $remoteUid from audioCallerUids',
              );
              _audioCallerUids.remove(remoteUid);
              debugPrint(
                '🎤 [AUDIO_CALLBACK] audioCallerUids after remove: $_audioCallerUids (length: ${_audioCallerUids.length})',
              );

              emit(
                this.state.copyWith(
                  audioCallerUids: List<int>.from(_audioCallerUids),
                ),
              );
            }
          },
          onNetworkQuality: (connection, remoteUid, txQuality, rxQuality) {
            // rxQuality 0-1 means good, 6 means very bad
            if (rxQuality.value() >= 5) {
              // Show poor connection warning to user
              emit(
                state.copyWith(
                  snackBar: LiveSessionSnackBar.warning('Poor connection'),
                ),
              );
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
      emit(state.copyWith(errorMessage: 'Failed to initialize live session'));
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

      emit(
        state.copyWith(
          snackBar: LiveSessionSnackBar.warning('Using fallback token'),
        ),
      );
      await _joinChannelWithStaticToken(channelId: channelId);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('❌ Error generating token: $error');
        print(stackTrace);
      }
      emit(
        state.copyWith(
          snackBar: LiveSessionSnackBar.warning('Using fallback token'),
        ),
      );
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
    debugPrint('🎤 [SWITCH→BROADCASTER] Starting switch to audio caller...');
    debugPrint(
      '🎤 [SWITCH→BROADCASTER] state.localUserJoined: ${state.localUserJoined}',
    );
    debugPrint(
      '🎤 [SWITCH→BROADCASTER] audioCallerUids before: $_audioCallerUids (length: ${_audioCallerUids.length})',
    );

    try {
      debugPrint(
        '🎤 [SWITCH→BROADCASTER] 🔄 Setting client role to BROADCASTER...',
      );
      await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      debugPrint('🎤 [SWITCH→BROADCASTER] ✅ Client role set');

      debugPrint('🎤 [SWITCH→BROADCASTER] 🔄 Enabling local audio...');
      await _engine?.enableLocalAudio(true);
      debugPrint('🎤 [SWITCH→BROADCASTER] ✅ Local audio enabled');

      debugPrint('🎤 [SWITCH→BROADCASTER] 🔄 Disabling local video...');
      await _engine?.enableLocalVideo(false);
      debugPrint('🎤 [SWITCH→BROADCASTER] ✅ Local video disabled');

      debugPrint('🎤 [SWITCH→BROADCASTER] 🔄 Muting video stream...');
      await _engine?.muteLocalVideoStream(true);
      debugPrint('🎤 [SWITCH→BROADCASTER] ✅ Video stream muted');

      debugPrint('🎤 [SWITCH→BROADCASTER] 🔄 Unmuting audio stream...');
      await _engine?.muteLocalAudioStream(false);
      debugPrint('🎤 [SWITCH→BROADCASTER] ✅ Audio stream unmuted');

      // ✅ Add current user's UID to audioCallerUids so the count is correct
      final localUid = state.localUserJoined
          ? 0
          : null; // Local user UID is typically 0
      debugPrint(
        '🎤 [SWITCH→BROADCASTER] 🔄 Adding local UID ($localUid) to audioCallerUids...',
      );

      if (localUid != null && !_audioCallerUids.contains(localUid)) {
        _audioCallerUids.add(localUid);
        debugPrint('🎤 [SWITCH→BROADCASTER] ✅ Local UID added to list');
      } else if (localUid != null) {
        debugPrint('🎤 [SWITCH→BROADCASTER] ⚠️ Local UID already in list');
      } else {
        debugPrint(
          '🎤 [SWITCH→BROADCASTER] ⚠️ localUid is null (localUserJoined: ${state.localUserJoined})',
        );
      }

      debugPrint(
        '🎤 [SWITCH→BROADCASTER] audioCallerUids after: $_audioCallerUids (length: ${_audioCallerUids.length})',
      );

      emit(state.copyWith(isCameraEnabled: false, isMicEnabled: true));
      debugPrint(
        '🎤 [SWITCH→BROADCASTER] ✅ State emitted (isMicEnabled: true)',
      );
    } catch (e) {
      debugPrint('🎤 [SWITCH→BROADCASTER] ❌ Error: $e');
      rethrow;
    }
  }

  Future<void> _switchToAudience() async {
    debugPrint('🎤 [SWITCH→AUDIENCE] Starting switch to audience...');
    debugPrint(
      '🎤 [SWITCH→AUDIENCE] audioCallerUids before: $_audioCallerUids (length: ${_audioCallerUids.length})',
    );

    try {
      debugPrint('🎤 [SWITCH→AUDIENCE] 🔄 Setting client role to AUDIENCE...');
      await _engine?.setClientRole(role: ClientRoleType.clientRoleAudience);
      debugPrint('🎤 [SWITCH→AUDIENCE] ✅ Client role set');

      debugPrint('🎤 [SWITCH→AUDIENCE] 🔄 Disabling local audio...');
      await _engine?.enableLocalAudio(false);
      debugPrint('🎤 [SWITCH→AUDIENCE] ✅ Local audio disabled');

      debugPrint('🎤 [SWITCH→AUDIENCE] 🔄 Disabling local video...');
      await _engine?.enableLocalVideo(false);
      debugPrint('🎤 [SWITCH→AUDIENCE] ✅ Local video disabled');

      debugPrint('🎤 [SWITCH→AUDIENCE] 🔄 Muting audio stream...');
      await _engine?.muteLocalAudioStream(true);
      debugPrint('🎤 [SWITCH→AUDIENCE] ✅ Audio stream muted');

      // ✅ Remove current user's UID from audioCallerUids when leaving
      debugPrint(
        '🎤 [SWITCH→AUDIENCE] 🔄 Removing local UID (0) from audioCallerUids...',
      );
      _audioCallerUids.remove(0); // Local user UID is typically 0
      debugPrint(
        '🎤 [SWITCH→AUDIENCE] audioCallerUids after: $_audioCallerUids (length: ${_audioCallerUids.length})',
      );

      emit(state.copyWith(isCameraEnabled: false, isMicEnabled: false));
      debugPrint('🎤 [SWITCH→AUDIENCE] ✅ State emitted (isMicEnabled: false)');
    } catch (e) {
      debugPrint('🎤 [SWITCH→AUDIENCE] ❌ Error: $e');
      rethrow;
    }
  }

  Future<void> _applyCameraPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFrontCamera = prefs.getBool('is_front_camera') ?? true;

      if (kDebugMode) {
        print('🔍 [CAMERA PREFERENCE] Reading from SharedPreferences');
        print('📱 Stored value: is_front_camera = $isFrontCamera');
        print(
          '🔄 Action: ${isFrontCamera ? '✅ Using front camera (default)' : '🔄 Switching to rear camera'}',
        );
      }

      if (!isFrontCamera) {
        await _engine?.switchCamera();
        if (kDebugMode) {
          print('✅ [CAMERA PREFERENCE] Successfully switched to rear camera');
        }
      } else {
        if (kDebugMode) {
          print(
            '✅ [CAMERA PREFERENCE] Front camera confirmed (no switch needed)',
          );
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print(
          '⚠️ [CAMERA PREFERENCE] Error applying camera preference: $error',
        );
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
      _hostActivityTimer ??= Timer(
        const Duration(seconds: _inactivityTimeoutSeconds),
        () {
          emit(
            state.copyWith(
              forceExitReason: 'Host disconnected. Live session ended.',
            ),
          );
        },
      );
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
