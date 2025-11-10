import 'package:dlstarlive/core/network/models/gift_model.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/audio_room_details.dart';
import '../../data/models/audio_member_model.dart';

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
  final String userId;

  const InitializeWithRoomDataEvent({required this.roomData, required this.isHost, required this.userId});

  @override
  List<Object?> get props => [roomData, isHost, userId];
}

class JoinRoomEvent extends AudioRoomEvent {
  final String roomId;
  final String memberID;

  const JoinRoomEvent({required this.roomId, required this.memberID});

  @override
  List<Object?> get props => [roomId, memberID];
}

class LeaveRoomEvent extends AudioRoomEvent {
  final String roomId;

  const LeaveRoomEvent({required this.roomId});

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

  const JoinSeatEvent({required this.roomId, required this.seatKey, required this.targetId});

  @override
  List<Object?> get props => [roomId, seatKey, targetId];
}

class LeaveSeatEvent extends AudioRoomEvent {
  final String roomId;
  final String seatKey;
  final String targetId;

  const LeaveSeatEvent({required this.roomId, required this.seatKey, required this.targetId});

  @override
  List<Object?> get props => [roomId, seatKey, targetId];
}

class RemoveFromSeatEvent extends AudioRoomEvent {
  final String roomId;
  final String seatKey;
  final String targetId;

  const RemoveFromSeatEvent({required this.roomId, required this.seatKey, required this.targetId});

  @override
  List<Object?> get props => [roomId, seatKey, targetId];
}

class MuteUserFromSeatEvent extends AudioRoomEvent {
  final String roomId;
  final String seatKey;
  final String targetId;

  const MuteUserFromSeatEvent({required this.roomId, required this.seatKey, required this.targetId});

  @override
  List<Object?> get props => [roomId, seatKey, targetId];
}

/// Chat Events
class SendMessageEvent extends AudioRoomEvent {
  final String roomId;
  final String message;

  const SendMessageEvent({required this.roomId, required this.message});

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

class UpdateBroadcasterStatusEvent extends AudioRoomEvent {
  final bool isBroadcaster;

  const UpdateBroadcasterStatusEvent({required this.isBroadcaster});

  @override
  List<Object?> get props => [isBroadcaster];
}

class EndLiveStreamEvent extends AudioRoomEvent {}

/// UI Events
class PlayAnimationEvent extends AudioRoomEvent {
  final GiftModel giftDetails;

  const PlayAnimationEvent({required this.giftDetails});

  @override
  List<Object?> get props => [giftDetails];
}

/// Error Handling
class HandleSocketErrorEvent extends AudioRoomEvent {
  final Map<String, dynamic> error;

  const HandleSocketErrorEvent({required this.error});

  @override
  List<Object?> get props => [error];
}

/// Socket Stream Events
class UpdateConnectionStatusEvent extends AudioRoomEvent {
  final bool isConnected;

  const UpdateConnectionStatusEvent({required this.isConnected});

  @override
  List<Object?> get props => [isConnected];
}

class UpdateRoomDataEvent extends AudioRoomEvent {
  final AudioRoomDetails roomData;

  const UpdateRoomDataEvent({required this.roomData});

  @override
  List<Object?> get props => [roomData];
}

class ClearRoomIdEvent extends AudioRoomEvent {
  const ClearRoomIdEvent();
}

class NewMessageReceivedEvent extends AudioRoomEvent {
  final dynamic message;

  const NewMessageReceivedEvent({required this.message});

  @override
  List<Object?> get props => [message];
}

class UserBannedEvent extends AudioRoomEvent {
  final String targetId;

  const UserBannedEvent({required this.targetId});

  @override
  List<Object?> get props => [targetId];
}

class UserMutedEvent extends AudioRoomEvent {
  final String targetId;

  const UserMutedEvent({required this.targetId});

  @override
  List<Object?> get props => [targetId];
}

class RoomClosedEvent extends AudioRoomEvent {
  final String reason;

  const RoomClosedEvent({required this.reason});

  @override
  List<Object?> get props => [reason];
}

class UserJoinedEvent extends AudioRoomEvent {
  final AudioMember member;

  const UserJoinedEvent({required this.member});

  @override
  List<Object?> get props => [member];
}

/// Helper method events
class UpdateListenersEvent extends AudioRoomEvent {
  final String userId;

  const UpdateListenersEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class SeatJoinedEvent extends AudioRoomEvent {
  final String seatKey;
  final AudioMember? member;

  const SeatJoinedEvent({required this.seatKey, this.member});

  @override
  List<Object?> get props => [seatKey, member];
}

class SeatLeftEvent extends AudioRoomEvent {
  final String seatKey;

  const SeatLeftEvent({required this.seatKey});

  @override
  List<Object?> get props => [seatKey];
}

class UpdateBannedUsersEvent extends AudioRoomEvent {
  final String targetId;

  const UpdateBannedUsersEvent({required this.targetId});

  @override
  List<Object?> get props => [targetId];
}

class UpdateStreamTimeEvent extends AudioRoomEvent {
  final DateTime startTime;

  const UpdateStreamTimeEvent({required this.startTime});

  @override
  List<Object?> get props => [startTime];
}
