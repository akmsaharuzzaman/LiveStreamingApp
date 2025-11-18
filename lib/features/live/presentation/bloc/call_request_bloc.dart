import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/repositories/call_request_repository.dart';
import 'call_request_event.dart';
import 'call_request_state.dart';
import '../../../../core/network/models/call_request_model.dart';
import '../../../../core/network/models/broadcaster_model.dart';

@injectable
class CallRequestBloc extends Bloc<CallRequestEvent, CallRequestState> {
  final CallRequestRepository _repository;

  // Subscriptions for cleanup
  StreamSubscription? _requestsSubscription;
  StreamSubscription? _requestListSubscription;
  StreamSubscription? _broadcastersSubscription;

  // Store data in memory
  final List<CallRequestModel> _pendingRequests = [];
  final List<BroadcasterModel> _activeBroadcasters = [];

  CallRequestBloc(this._repository) : super(const CallRequestInitial()) {
    on<ReceiveCallRequest>(_onReceiveRequest);
    on<LoadCallRequestList>(_onLoadRequestList);
    on<AcceptCallRequest>(_onAcceptRequest);
    on<RejectCallRequest>(_onRejectRequest);
    on<RemoveBroadcaster>(_onRemoveBroadcaster);
    on<SubmitJoinCallRequest>(_onSubmitJoinRequest);
    on<AddBroadcaster>(_onAddBroadcaster);
    on<LoadInitialBroadcasters>(_onLoadInitialBroadcasters);
    on<ClearCallRequests>(_onClearRequests);
    on<ResolvePendingRequest>(_onResolvePendingRequest);
    on<UserDisconnected>(
      _onUserDisconnected,
    ); // ✅ Handle user disconnect from stream

    // Setup stream listeners
    _setupListeners();
  }

  void _onReceiveRequest(
    ReceiveCallRequest event,
    Emitter<CallRequestState> emit,
  ) {
    // Don't add duplicates
    if (!_pendingRequests.any((r) => r.userId == event.request.userId)) {
      _pendingRequests.add(event.request);
      emit(
        CallRequestLoaded(
          pendingRequests: List.from(_pendingRequests),
          activeBroadcasters: List.from(_activeBroadcasters),
        ),
      );
    }
  }

  void _onLoadRequestList(
    LoadCallRequestList event,
    Emitter<CallRequestState> emit,
  ) {
    _pendingRequests.clear();
    _pendingRequests.addAll(event.requests);
    emit(
      CallRequestLoaded(
        pendingRequests: List.from(_pendingRequests),
        activeBroadcasters: List.from(_activeBroadcasters),
      ),
    );
  }

  Future<void> _onAcceptRequest(
    AcceptCallRequest event,
    Emitter<CallRequestState> emit,
  ) async {
    try {
      debugPrint('🎤 [CALL_BLOC] _onAcceptRequest called');
      debugPrint(
        '🎤 [CALL_BLOC] Accepting user: ${event.userId} for room: ${event.roomId}',
      );

      emit(const CallRequestProcessing());

      final result = await _repository.acceptRequest(
        roomId: event.roomId,
        userId: event.userId,
      );

      result.fold(
        (failure) {
          debugPrint(
            '🎤 [CALL_BLOC] ❌ Error accepting request: ${failure.message}',
          );
          emit(CallRequestError(failure.message));
          emit(
            CallRequestLoaded(
              pendingRequests: List.from(_pendingRequests),
              activeBroadcasters: List.from(_activeBroadcasters),
            ),
          );
        },
        (_) {
          debugPrint('🎤 [CALL_BLOC] ✅ Request accepted successfully');
          // Remove from pending
          _pendingRequests.removeWhere((r) => r.userId == event.userId);
          debugPrint(
            '🎤 [CALL_BLOC] Pending requests count after acceptance: ${_pendingRequests.length}',
          );

          emit(CallRequestAccepted(event.userId));
          emit(
            CallRequestLoaded(
              pendingRequests: List.from(_pendingRequests),
              activeBroadcasters: List.from(_activeBroadcasters),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('🎤 [CALL_BLOC] ❌ Exception in _onAcceptRequest: $e');
      emit(CallRequestError('Failed to accept request: $e'));
      emit(
        CallRequestLoaded(
          pendingRequests: List.from(_pendingRequests),
          activeBroadcasters: List.from(_activeBroadcasters),
        ),
      );
    }
  }

  Future<void> _onRejectRequest(
    RejectCallRequest event,
    Emitter<CallRequestState> emit,
  ) async {
    try {
      debugPrint('🎤 [CALL_BLOC] _onRejectRequest called');
      debugPrint(
        '🎤 [CALL_BLOC] Rejecting user: ${event.userId} for room: ${event.roomId}',
      );

      emit(const CallRequestProcessing());

      final result = await _repository.rejectRequest(
        roomId: event.roomId,
        userId: event.userId,
      );

      result.fold(
        (failure) {
          debugPrint(
            '🎤 [CALL_BLOC] ❌ Error rejecting request: ${failure.message}',
          );
          emit(CallRequestError(failure.message));
          emit(
            CallRequestLoaded(
              pendingRequests: List.from(_pendingRequests),
              activeBroadcasters: List.from(_activeBroadcasters),
            ),
          );
        },
        (_) {
          debugPrint('🎤 [CALL_BLOC] ✅ Request rejected successfully');
          // Remove from pending
          _pendingRequests.removeWhere((r) => r.userId == event.userId);
          debugPrint(
            '🎤 [CALL_BLOC] Pending requests count after rejection: ${_pendingRequests.length}',
          );

          emit(CallRequestRejected(event.userId));
          emit(
            CallRequestLoaded(
              pendingRequests: List.from(_pendingRequests),
              activeBroadcasters: List.from(_activeBroadcasters),
            ),
          );
        },
      );
    } catch (e) {
      emit(CallRequestError('Failed to reject request: $e'));
      emit(
        CallRequestLoaded(
          pendingRequests: List.from(_pendingRequests),
          activeBroadcasters: List.from(_activeBroadcasters),
        ),
      );
    }
  }

  Future<void> _onRemoveBroadcaster(
    RemoveBroadcaster event,
    Emitter<CallRequestState> emit,
  ) async {
    try {
      debugPrint('🎤 [CALL_BLOC] _onRemoveBroadcaster called');
      debugPrint(
        '🎤 [CALL_BLOC] Removing user: ${event.userId} from room: ${event.roomId}',
      );

      emit(const CallRequestProcessing());

      final result = await _repository.removeBroadcaster(
        roomId: event.roomId,
        userId: event.userId,
      );

      result.fold(
        (failure) {
          debugPrint(
            '🎤 [CALL_BLOC] ❌ Error removing broadcaster: ${failure.message}',
          );
          emit(CallRequestError(failure.message));
          emit(
            CallRequestLoaded(
              pendingRequests: List.from(_pendingRequests),
              activeBroadcasters: List.from(_activeBroadcasters),
            ),
          );
        },
        (_) {
          debugPrint('🎤 [CALL_BLOC] ✅ Broadcaster removed successfully');
          // Remove from active broadcasters
          _activeBroadcasters.removeWhere((b) => b.id == event.userId);
          debugPrint(
            '🎤 [CALL_BLOC] Active broadcasters count after removal: ${_activeBroadcasters.length}',
          );

          emit(BroadcasterRemoved(event.userId));
          emit(
            CallRequestLoaded(
              pendingRequests: List.from(_pendingRequests),
              activeBroadcasters: List.from(_activeBroadcasters),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('🎤 [CALL_BLOC] ❌ Exception in _onRemoveBroadcaster: $e');
      emit(CallRequestError('Failed to remove broadcaster: $e'));
      emit(
        CallRequestLoaded(
          pendingRequests: List.from(_pendingRequests),
          activeBroadcasters: List.from(_activeBroadcasters),
        ),
      );
    }
  }

  Future<void> _onSubmitJoinRequest(
    SubmitJoinCallRequest event,
    Emitter<CallRequestState> emit,
  ) async {
    try {
      debugPrint('🎤 [CALL_BLOC] _onSubmitJoinRequest called');
      debugPrint('🎤 [CALL_BLOC] Joining call for room: ${event.roomId}');

      emit(const CallRequestProcessing());

      final result = await _repository.joinCallRequest(roomId: event.roomId);

      result.fold(
        (failure) {
          debugPrint('🎤 [CALL_BLOC] ❌ Error joining call: ${failure.message}');
          emit(CallRequestError(failure.message));
          emit(
            CallRequestLoaded(
              pendingRequests: List.from(_pendingRequests),
              activeBroadcasters: List.from(_activeBroadcasters),
            ),
          );
        },
        (_) {
          debugPrint('🎤 [CALL_BLOC] ✅ Join request submitted successfully');
          emit(CallRequestJoinSubmitted(event.roomId));
          emit(
            CallRequestLoaded(
              pendingRequests: List.from(_pendingRequests),
              activeBroadcasters: List.from(_activeBroadcasters),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('🎤 [CALL_BLOC] ❌ Exception in _onSubmitJoinRequest: $e');
      emit(CallRequestError('Failed to submit call request: $e'));
      emit(
        CallRequestLoaded(
          pendingRequests: List.from(_pendingRequests),
          activeBroadcasters: List.from(_activeBroadcasters),
        ),
      );
    }
  }

  void _onAddBroadcaster(AddBroadcaster event, Emitter<CallRequestState> emit) {
    // Don't add duplicates
    if (!_activeBroadcasters.any((b) => b.id == event.broadcaster.id)) {
      _activeBroadcasters.add(event.broadcaster);
      emit(
        CallRequestLoaded(
          pendingRequests: List.from(_pendingRequests),
          activeBroadcasters: List.from(_activeBroadcasters),
        ),
      );
    }
  }

  void _onLoadInitialBroadcasters(
    LoadInitialBroadcasters event,
    Emitter<CallRequestState> emit,
  ) {
    _activeBroadcasters.clear();
    _activeBroadcasters.addAll(event.broadcasters);
    emit(
      CallRequestLoaded(
        pendingRequests: List.from(_pendingRequests),
        activeBroadcasters: List.from(_activeBroadcasters),
      ),
    );
  }

  void _onClearRequests(
    ClearCallRequests event,
    Emitter<CallRequestState> emit,
  ) {
    _pendingRequests.clear();
    _activeBroadcasters.clear();
    emit(const CallRequestInitial());
  }

  void _onResolvePendingRequest(
    ResolvePendingRequest event,
    Emitter<CallRequestState> emit,
  ) {
    final originalLength = _pendingRequests.length;
    _pendingRequests.removeWhere((request) => request.userId == event.userId);

    if (_pendingRequests.length != originalLength) {
      emit(
        CallRequestLoaded(
          pendingRequests: List.from(_pendingRequests),
          activeBroadcasters: List.from(_activeBroadcasters),
        ),
      );
    }
  }

  /// ✅ Handle user disconnect - remove from both pending requests and active broadcasters
  /// Called when userLeftStream fires (user disconnected from stream)
  void _onUserDisconnected(
    UserDisconnected event,
    Emitter<CallRequestState> emit,
  ) {
    bool wasPending = false;
    bool wasActive = false;

    // Remove from pending call requests
    final initialPendingLength = _pendingRequests.length;
    _pendingRequests.removeWhere((r) => r.userId == event.userId);
    wasPending = _pendingRequests.length != initialPendingLength;

    // Remove from active broadcasters in call
    final initialBroadcasterLength = _activeBroadcasters.length;
    _activeBroadcasters.removeWhere((b) => b.id == event.userId);
    wasActive = _activeBroadcasters.length != initialBroadcasterLength;

    // Only emit state if something actually changed
    if (wasPending || wasActive) {
      debugPrint(
        "🚪 [CALL REQUEST] User ${event.userId} disconnected (was pending: $wasPending, was active: $wasActive)",
      );
      emit(
        CallRequestLoaded(
          pendingRequests: List.from(_pendingRequests),
          activeBroadcasters: List.from(_activeBroadcasters),
        ),
      );
    }
  }

  void _setupListeners() {
    // Listen for individual requests
    _requestsSubscription = _repository.requestsStream.listen((request) {
      add(ReceiveCallRequest(request));
    });

    // Listen for request list
    _requestListSubscription = _repository.requestListStream.listen((list) {
      // Convert CallRequestListModel to CallRequestModel
      final requests = list.map((item) {
        return CallRequestModel(
          userId: item.id,
          userDetails: UserDetails(
            id: item.id,
            avatar: item.avatar,
            name: item.name,
            uid: item.uid,
          ),
          roomId: '', // Will be set by the UI
        );
      }).toList();

      add(LoadCallRequestList(requests));
    });

    // Listen for active broadcasters
    _broadcastersSubscription = _repository.broadcasterListStream.listen((
      broadcasters,
    ) {
      add(LoadInitialBroadcasters(broadcasters));
    });
  }

  @override
  Future<void> close() {
    _requestsSubscription?.cancel();
    _requestListSubscription?.cancel();
    _broadcastersSubscription?.cancel();
    return super.close();
  }
}
