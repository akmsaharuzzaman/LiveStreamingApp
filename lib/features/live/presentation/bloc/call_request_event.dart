import 'package:equatable/equatable.dart';
import '../../../../core/network/models/call_request_model.dart';
import '../../../../core/network/models/broadcaster_model.dart';

/// Events for Call Request feature
abstract class CallRequestEvent extends Equatable {
  const CallRequestEvent();

  @override
  List<Object?> get props => [];
}

/// Receive a call request
class ReceiveCallRequest extends CallRequestEvent {
  final CallRequestModel request;

  const ReceiveCallRequest(this.request);

  @override
  List<Object?> get props => [request];
}

/// Load call request list
class LoadCallRequestList extends CallRequestEvent {
  final List<CallRequestModel> requests;

  const LoadCallRequestList(this.requests);

  @override
  List<Object?> get props => [requests];
}

/// Accept call request
class AcceptCallRequest extends CallRequestEvent {
  final String userId;
  final String roomId;

  const AcceptCallRequest({
    required this.userId,
    required this.roomId,
  });

  @override
  List<Object?> get props => [userId, roomId];
}

/// Reject call request
class RejectCallRequest extends CallRequestEvent {
  final String userId;
  final String roomId;

  const RejectCallRequest({
    required this.userId,
    required this.roomId,
  });

  @override
  List<Object?> get props => [userId, roomId];
}

/// Remove broadcaster
class RemoveBroadcaster extends CallRequestEvent {
  final String userId;
  final String roomId;

  const RemoveBroadcaster({
    required this.userId,
    required this.roomId,
  });

  @override
  List<Object?> get props => [userId, roomId];
}

/// Submit join call request
class SubmitJoinCallRequest extends CallRequestEvent {
  final String roomId;

  const SubmitJoinCallRequest({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

/// Add broadcaster (after accepting)
class AddBroadcaster extends CallRequestEvent {
  final BroadcasterModel broadcaster;

  const AddBroadcaster(this.broadcaster);

  @override
  List<Object?> get props => [broadcaster];
}

/// Load initial broadcasters
class LoadInitialBroadcasters extends CallRequestEvent {
  final List<BroadcasterModel> broadcasters;

  const LoadInitialBroadcasters(this.broadcasters);

  @override
  List<Object?> get props => [broadcasters];
}

/// Clear all call requests
class ClearCallRequests extends CallRequestEvent {
  const ClearCallRequests();
}
