part of 'live_session_cubit.dart';

enum LiveSessionStatus {
  idle,
  initializing,
  permissionsDenied,
  initializingAgora,
  connectingSocket,
  ready,
  error,
  ended,
}

enum LiveSessionSnackBarType { success, error, warning, info }

class LiveSessionSnackBar extends Equatable {
  const LiveSessionSnackBar._(this.message, this.type);

  factory LiveSessionSnackBar.success(String message) =>
      LiveSessionSnackBar._(message, LiveSessionSnackBarType.success);
  factory LiveSessionSnackBar.error(String message) =>
      LiveSessionSnackBar._(message, LiveSessionSnackBarType.error);
  factory LiveSessionSnackBar.warning(String message) =>
      LiveSessionSnackBar._(message, LiveSessionSnackBarType.warning);
  factory LiveSessionSnackBar.info(String message) =>
      LiveSessionSnackBar._(message, LiveSessionSnackBarType.info);

  final String message;
  final LiveSessionSnackBarType type;

  @override
  List<Object?> get props => [message, type];
}

class LiveSessionState extends Equatable {
  const LiveSessionState({
    this.status = LiveSessionStatus.idle,
    this.isHost = true,
    this.userId,
    this.currentRoomId,
    this.engine,
    this.isSocketConnected = false,
    this.localUserJoined = false,
    this.isVideoReady = false,
    this.isVideoConnecting = false,
    this.isLocalVideoReady = false,
    this.isCameraEnabled = false,
    this.isMicEnabled = false,
    this.isAudioCaller = false,
    this.isJoiningAudioCaller = false,
    this.remoteUid,
    this.remoteUsers = const [],
    this.audioCallerUids = const [],
    this.videoCallerUids = const [],
    this.snackBar,
    this.errorMessage,
    this.forceExitReason,
  });

  static const int maxAudioCallers = 3;

  final LiveSessionStatus status;
  final bool isHost;
  final String? userId;
  final String? currentRoomId;
  final RtcEngine? engine;
  final bool isSocketConnected;
  final bool localUserJoined;
  final bool isVideoReady;
  final bool isVideoConnecting;
  final bool isLocalVideoReady;
  final bool isCameraEnabled;
  final bool isMicEnabled;
  final bool isAudioCaller;
  final bool isJoiningAudioCaller;
  final int? remoteUid;
  final List<int> remoteUsers;
  final List<int> audioCallerUids;
  final List<int> videoCallerUids;
  final LiveSessionSnackBar? snackBar;
  final String? errorMessage;
  final String? forceExitReason;

  LiveSessionState copyWith({
    LiveSessionStatus? status,
    bool? isHost,
    String? userId,
    String? currentRoomId,
    RtcEngine? engine,
    bool? isSocketConnected,
    bool? localUserJoined,
    bool? isVideoReady,
    bool? isVideoConnecting,
    bool? isLocalVideoReady,
    bool? isCameraEnabled,
    bool? isMicEnabled,
    bool? isAudioCaller,
    bool? isJoiningAudioCaller,
    int? remoteUid,
    List<int>? remoteUsers,
    List<int>? audioCallerUids,
    List<int>? videoCallerUids,
    LiveSessionSnackBar? snackBar,
    String? errorMessage,
    String? forceExitReason,
    bool clearSnackBar = false,
    bool clearForceExitReason = false,
  }) {
    return LiveSessionState(
      status: status ?? this.status,
      isHost: isHost ?? this.isHost,
      userId: userId ?? this.userId,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      engine: engine ?? this.engine,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      localUserJoined: localUserJoined ?? this.localUserJoined,
      isVideoReady: isVideoReady ?? this.isVideoReady,
      isVideoConnecting: isVideoConnecting ?? this.isVideoConnecting,
      isLocalVideoReady: isLocalVideoReady ?? this.isLocalVideoReady,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      isAudioCaller: isAudioCaller ?? this.isAudioCaller,
      isJoiningAudioCaller:
          isJoiningAudioCaller ?? this.isJoiningAudioCaller,
      remoteUid: remoteUid ?? this.remoteUid,
      remoteUsers: remoteUsers ?? this.remoteUsers,
      audioCallerUids: audioCallerUids ?? this.audioCallerUids,
      videoCallerUids: videoCallerUids ?? this.videoCallerUids,
      snackBar: clearSnackBar ? null : (snackBar ?? this.snackBar),
      errorMessage: errorMessage ?? this.errorMessage,
      forceExitReason:
          clearForceExitReason ? null : (forceExitReason ?? this.forceExitReason),
    );
  }

  @override
  List<Object?> get props => [
        status,
        isHost,
        userId,
        currentRoomId,
        engine,
        isSocketConnected,
        localUserJoined,
        isVideoReady,
        isVideoConnecting,
        isLocalVideoReady,
        isCameraEnabled,
        isMicEnabled,
        isAudioCaller,
        isJoiningAudioCaller,
        remoteUid,
        remoteUsers,
        audioCallerUids,
        videoCallerUids,
        snackBar,
        errorMessage,
        forceExitReason,
      ];
}
