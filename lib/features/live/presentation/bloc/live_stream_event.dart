import 'package:equatable/equatable.dart';
import '../../../../core/network/socket_service.dart';

/// Events for LiveStream feature
abstract class LiveStreamEvent extends Equatable {
  const LiveStreamEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize live stream (as host or viewer)
class InitializeLiveStream extends LiveStreamEvent {
  final String? roomId;
  final String? hostUserId;
  final bool isHost;

  const InitializeLiveStream({
    this.roomId,
    this.hostUserId,
    required this.isHost,
  });

  @override
  List<Object?> get props => [roomId, hostUserId, isHost];
}

/// Create a new room (host)
class CreateRoom extends LiveStreamEvent {
  final String title;
  final String userId;
  final RoomType roomType;

  const CreateRoom({
    required this.title,
    required this.userId,
    this.roomType = RoomType.live,
  });

  @override
  List<Object?> get props => [title, userId, roomType];
}

/// Join existing room (viewer)
class JoinRoom extends LiveStreamEvent {
  final String roomId;
  final String userId;

  const JoinRoom({required this.roomId, required this.userId});

  @override
  List<Object?> get props => [roomId, userId];
}

/// Leave room
class LeaveRoom extends LiveStreamEvent {
  const LeaveRoom();
}

/// End live stream (host)
class EndLiveStream extends LiveStreamEvent {
  const EndLiveStream();
}

/// Update stream duration
class UpdateStreamDuration extends LiveStreamEvent {
  final Duration duration;

  const UpdateStreamDuration(this.duration);

  @override
  List<Object?> get props => [duration];
}

/// User joined the stream
class UserJoined extends LiveStreamEvent {
  final String userId;
  final String userName;
  final String? avatar;
  final String? uid;

  const UserJoined({
    required this.userId,
    required this.userName,
    this.avatar,
    this.uid,
  });

  @override
  List<Object?> get props => [userId, userName, avatar, uid];
}

/// User left the stream
class UserLeft extends LiveStreamEvent {
  final String userId;

  const UserLeft(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Toggle camera
class ToggleCamera extends LiveStreamEvent {
  const ToggleCamera();
}

/// Toggle microphone
class ToggleMicrophone extends LiveStreamEvent {
  const ToggleMicrophone();
}

/// Switch camera (front/back)
class SwitchCamera extends LiveStreamEvent {
  const SwitchCamera();
}

/// Call daily bonus API
class CallDailyBonus extends LiveStreamEvent {
  final bool isStreamEnd;

  const CallDailyBonus({this.isStreamEnd = false});

  @override
  List<Object?> get props => [isStreamEnd];
}

/// Ban user
class BanUser extends LiveStreamEvent {
  final String userId;

  const BanUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Receive ban notification from socket (when another admin bans someone)
class UserBannedNotification extends LiveStreamEvent {
  final String userId;
  final String message;

  const UserBannedNotification({
    required this.userId,
    required this.message,
  });

  @override
  List<Object?> get props => [userId, message];
}

/// Mute user
class MuteUser extends LiveStreamEvent {
  final String userId;

  const MuteUser(this.userId);

  @override
  List<Object?> get props => [userId];
}
