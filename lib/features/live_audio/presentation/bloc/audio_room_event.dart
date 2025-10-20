import 'package:equatable/equatable.dart';
import '../../data/models/audio_room_details.dart';

/// Base event class for AudioRoomBloc
abstract class AudioRoomEvent extends Equatable {
  const AudioRoomEvent();

  @override
  List<Object?> get props => [];
}

/// Socket Connection Events
class ConnectToSocket extends AudioRoomEvent {
  final String userId;

  const ConnectToSocket({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class DisconnectFromSocket extends AudioRoomEvent {}

/// Reset Bloc to initial state
class ResetBlocState extends AudioRoomEvent {}

/// Room Management Events
class CreateRoomEvent extends AudioRoomEvent {
  final String roomId; // User's ID becomes the room ID
  final String? roomTitle; // Optional room title
  final int numberOfSeats;

  const CreateRoomEvent({
    required this.roomId,
    this.roomTitle, // Optional parameter
    required this.numberOfSeats,
  });

  @override
  List<Object?> get props => [roomId, roomTitle, numberOfSeats];
}

class InitializeWithRoomDataEvent extends AudioRoomEvent {
  final AudioRoomDetails roomData;
  final bool isHost;

  const InitializeWithRoomDataEvent({
    required this.roomData,
    required this.isHost,
  });

  @override
  List<Object?> get props => [roomData, isHost];
}

class JoinRoomEvent extends AudioRoomEvent {
  final String roomId;

  const JoinRoomEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class LeaveRoomEvent extends AudioRoomEvent {
  final String roomId;

  const LeaveRoomEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class DeleteRoomEvent extends AudioRoomEvent {
  final String roomId;

  const DeleteRoomEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class GetRoomDetailsEvent extends AudioRoomEvent {
  final String roomId;

  const GetRoomDetailsEvent({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class GetAllRoomsEvent extends AudioRoomEvent {}

/// Seat Management Events
class JoinSeatEvent extends AudioRoomEvent {
  final String roomId;
  final String seatKey;
  final String targetId;

  const JoinSeatEvent({
    required this.roomId,
    required this.seatKey,
    required this.targetId,
  });

  @override
  List<Object?> get props => [roomId, seatKey, targetId];
}

class LeaveSeatEvent extends AudioRoomEvent {
  final String roomId;
  final String seatKey;
  final String targetId;

  const LeaveSeatEvent({
    required this.roomId,
    required this.seatKey,
    required this.targetId,
  });

  @override
  List<Object?> get props => [roomId, seatKey, targetId];
}

class RemoveFromSeatEvent extends AudioRoomEvent {
  final String roomId;
  final String seatKey;
  final String targetId;

  const RemoveFromSeatEvent({
    required this.roomId,
    required this.seatKey,
    required this.targetId,
  });

  @override
  List<Object?> get props => [roomId, seatKey, targetId];
}

/// Chat Events
class SendMessageEvent extends AudioRoomEvent {
  final String roomId;
  final String message;

  const SendMessageEvent({
    required this.roomId,
    required this.message,
  });

  @override
  List<Object?> get props => [roomId, message];
}

/// User Management Events
class BanUserEvent extends AudioRoomEvent {
  final String userId;

  const BanUserEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UnbanUserEvent extends AudioRoomEvent {
  final String userId;

  const UnbanUserEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class MuteUnmuteUserEvent extends AudioRoomEvent {
  final String userId;

  const MuteUnmuteUserEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Agora/Stream Events
class InitializeAgoraEvent extends AudioRoomEvent {}

class JoinAgoraChannelEvent extends AudioRoomEvent {}

class ToggleMuteEvent extends AudioRoomEvent {}

class EndLiveStreamEvent extends AudioRoomEvent {}

/// UI Events
class UpdateStreamDurationEvent extends AudioRoomEvent {}

class PlayAnimationEvent extends AudioRoomEvent {
  final String? animationUrl;
  final String? title;
  final String? subtitle;

  const PlayAnimationEvent({
    this.animationUrl,
    this.title,
    this.subtitle,
  });

  @override
  List<Object?> get props => [animationUrl, title, subtitle];
}

/// Error Handling
class HandleSocketErrorEvent extends AudioRoomEvent {
  final Map<String, dynamic> error;

  const HandleSocketErrorEvent({required this.error});

  @override
  List<Object?> get props => [error];
}
