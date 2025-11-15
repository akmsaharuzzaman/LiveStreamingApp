import 'package:equatable/equatable.dart';
import '../../../../core/network/models/joined_user_model.dart';

/// States for LiveStream feature
abstract class LiveStreamState extends Equatable {
  const LiveStreamState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class LiveStreamInitial extends LiveStreamState {
  const LiveStreamInitial();
}

/// Loading state
class LiveStreamLoading extends LiveStreamState {
  const LiveStreamLoading();
}

/// Streaming state (main state during live)
class LiveStreamStreaming extends LiveStreamState {
  final String roomId;
  final bool isHost;
  final String userId;
  final List<JoinedUserModel> viewers;
  final Duration duration;
  final bool isCameraEnabled;
  final bool isMicEnabled;
  final int totalBonusDiamonds;
  final List<String> bannedUsers;
  final int lastBonusMilestone; // Track last milestone for bonus API calls

  const LiveStreamStreaming({
    required this.roomId,
    required this.isHost,
    required this.userId,
    this.viewers = const [],
    this.duration = Duration.zero,
    this.isCameraEnabled = true,
    this.isMicEnabled = true,
    this.totalBonusDiamonds = 0,
    this.bannedUsers = const [],
    this.lastBonusMilestone = 0,
  });

  /// Copy with for immutable updates
  LiveStreamStreaming copyWith({
    String? roomId,
    bool? isHost,
    String? userId,
    List<JoinedUserModel>? viewers,
    Duration? duration,
    bool? isCameraEnabled,
    bool? isMicEnabled,
    int? totalBonusDiamonds,
    List<String>? bannedUsers,
    int? lastBonusMilestone,
  }) {
    return LiveStreamStreaming(
      roomId: roomId ?? this.roomId,
      isHost: isHost ?? this.isHost,
      userId: userId ?? this.userId,
      viewers: viewers ?? this.viewers,
      duration: duration ?? this.duration,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      totalBonusDiamonds: totalBonusDiamonds ?? this.totalBonusDiamonds,
      bannedUsers: bannedUsers ?? this.bannedUsers,
      lastBonusMilestone: lastBonusMilestone ?? this.lastBonusMilestone,
    );
  }

  @override
  List<Object?> get props => [
    roomId,
    isHost,
    userId,
    viewers,
    duration,
    isCameraEnabled,
    isMicEnabled,
    totalBonusDiamonds,
    bannedUsers,
    lastBonusMilestone,
  ];
}

/// Stream ended state
class LiveStreamEnded extends LiveStreamState {
  final String roomId;
  final Duration totalDuration;
  final int earnedDiamonds;
  final int totalViewers;

  const LiveStreamEnded({
    required this.roomId,
    required this.totalDuration,
    required this.earnedDiamonds,
    required this.totalViewers,
  });

  @override
  List<Object?> get props => [
    roomId,
    totalDuration,
    earnedDiamonds,
    totalViewers,
  ];
}

/// Error state
class LiveStreamError extends LiveStreamState {
  final String message;

  const LiveStreamError(this.message);

  @override
  List<Object?> get props => [message];
}
