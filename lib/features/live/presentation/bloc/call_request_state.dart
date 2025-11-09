import 'package:equatable/equatable.dart';
import '../../../../core/network/models/call_request_model.dart';
import '../../../../core/network/models/broadcaster_model.dart';

/// States for Call Request feature
abstract class CallRequestState extends Equatable {
  const CallRequestState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CallRequestInitial extends CallRequestState {
  const CallRequestInitial();
}

/// Call requests loaded
class CallRequestLoaded extends CallRequestState {
  final List<CallRequestModel> pendingRequests;
  final List<BroadcasterModel> activeBroadcasters;

  const CallRequestLoaded({
    this.pendingRequests = const [],
    this.activeBroadcasters = const [],
  });

  CallRequestLoaded copyWith({
    List<CallRequestModel>? pendingRequests,
    List<BroadcasterModel>? activeBroadcasters,
  }) {
    return CallRequestLoaded(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      activeBroadcasters: activeBroadcasters ?? this.activeBroadcasters,
    );
  }

  @override
  List<Object?> get props => [pendingRequests, activeBroadcasters];
}

/// Processing call request action
class CallRequestProcessing extends CallRequestState {
  const CallRequestProcessing();
}

/// Call request accepted
class CallRequestAccepted extends CallRequestState {
  final String userId;

  const CallRequestAccepted(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Call request rejected
class CallRequestRejected extends CallRequestState {
  final String userId;

  const CallRequestRejected(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Broadcaster removed
class BroadcasterRemoved extends CallRequestState {
  final String userId;

  const BroadcasterRemoved(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Error state
class CallRequestError extends CallRequestState {
  final String message;

  const CallRequestError(this.message);

  @override
  List<Object?> get props => [message];
}
