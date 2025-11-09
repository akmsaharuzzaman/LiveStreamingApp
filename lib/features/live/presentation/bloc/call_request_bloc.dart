import 'dart:async';
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
      emit(CallRequestLoaded(
        pendingRequests: List.from(_pendingRequests),
        activeBroadcasters: List.from(_activeBroadcasters),
      ));
    }
  }

  void _onLoadRequestList(
    LoadCallRequestList event,
    Emitter<CallRequestState> emit,
  ) {
    _pendingRequests.clear();
    _pendingRequests.addAll(event.requests);
    emit(CallRequestLoaded(
      pendingRequests: List.from(_pendingRequests),
      activeBroadcasters: List.from(_activeBroadcasters),
    ));
  }

  Future<void> _onAcceptRequest(
    AcceptCallRequest event,
    Emitter<CallRequestState> emit,
  ) async {
    try {
      emit(const CallRequestProcessing());

      final result = await _repository.acceptRequest(
        roomId: event.roomId,
        userId: event.userId,
      );

      result.fold(
        (failure) {
          emit(CallRequestError(failure.message));
          emit(CallRequestLoaded(
            pendingRequests: List.from(_pendingRequests),
            activeBroadcasters: List.from(_activeBroadcasters),
          ));
        },
        (_) {
          // Remove from pending
          _pendingRequests.removeWhere((r) => r.userId == event.userId);
          
          emit(CallRequestAccepted(event.userId));
          emit(CallRequestLoaded(
            pendingRequests: List.from(_pendingRequests),
            activeBroadcasters: List.from(_activeBroadcasters),
          ));
        },
      );
    } catch (e) {
      emit(CallRequestError('Failed to accept request: $e'));
      emit(CallRequestLoaded(
        pendingRequests: List.from(_pendingRequests),
        activeBroadcasters: List.from(_activeBroadcasters),
      ));
    }
  }

  Future<void> _onRejectRequest(
    RejectCallRequest event,
    Emitter<CallRequestState> emit,
  ) async {
    try {
      emit(const CallRequestProcessing());

      final result = await _repository.rejectRequest(
        roomId: event.roomId,
        userId: event.userId,
      );

      result.fold(
        (failure) {
          emit(CallRequestError(failure.message));
          emit(CallRequestLoaded(
            pendingRequests: List.from(_pendingRequests),
            activeBroadcasters: List.from(_activeBroadcasters),
          ));
        },
        (_) {
          // Remove from pending
          _pendingRequests.removeWhere((r) => r.userId == event.userId);
          
          emit(CallRequestRejected(event.userId));
          emit(CallRequestLoaded(
            pendingRequests: List.from(_pendingRequests),
            activeBroadcasters: List.from(_activeBroadcasters),
          ));
        },
      );
    } catch (e) {
      emit(CallRequestError('Failed to reject request: $e'));
      emit(CallRequestLoaded(
        pendingRequests: List.from(_pendingRequests),
        activeBroadcasters: List.from(_activeBroadcasters),
      ));
    }
  }

  Future<void> _onRemoveBroadcaster(
    RemoveBroadcaster event,
    Emitter<CallRequestState> emit,
  ) async {
    try {
      emit(const CallRequestProcessing());

      final result = await _repository.removeBroadcaster(
        roomId: event.roomId,
        userId: event.userId,
      );

      result.fold(
        (failure) {
          emit(CallRequestError(failure.message));
          emit(CallRequestLoaded(
            pendingRequests: List.from(_pendingRequests),
            activeBroadcasters: List.from(_activeBroadcasters),
          ));
        },
        (_) {
          // Remove from active broadcasters
          _activeBroadcasters.removeWhere((b) => b.id == event.userId);
          
          emit(BroadcasterRemoved(event.userId));
          emit(CallRequestLoaded(
            pendingRequests: List.from(_pendingRequests),
            activeBroadcasters: List.from(_activeBroadcasters),
          ));
        },
      );
    } catch (e) {
      emit(CallRequestError('Failed to remove broadcaster: $e'));
      emit(CallRequestLoaded(
        pendingRequests: List.from(_pendingRequests),
        activeBroadcasters: List.from(_activeBroadcasters),
      ));
    }
  }

  Future<void> _onSubmitJoinRequest(
    SubmitJoinCallRequest event,
    Emitter<CallRequestState> emit,
  ) async {
    try {
      emit(const CallRequestProcessing());

      final result = await _repository.joinCallRequest(
        roomId: event.roomId,
      );

      result.fold(
        (failure) {
          emit(CallRequestError(failure.message));
          emit(CallRequestLoaded(
            pendingRequests: List.from(_pendingRequests),
            activeBroadcasters: List.from(_activeBroadcasters),
          ));
        },
        (_) {
          emit(CallRequestJoinSubmitted(event.roomId));
          emit(CallRequestLoaded(
            pendingRequests: List.from(_pendingRequests),
            activeBroadcasters: List.from(_activeBroadcasters),
          ));
        },
      );
    } catch (e) {
      emit(CallRequestError('Failed to submit call request: $e'));
      emit(CallRequestLoaded(
        pendingRequests: List.from(_pendingRequests),
        activeBroadcasters: List.from(_activeBroadcasters),
      ));
    }
  }

  void _onAddBroadcaster(
    AddBroadcaster event,
    Emitter<CallRequestState> emit,
  ) {
    // Don't add duplicates
    if (!_activeBroadcasters.any((b) => b.id == event.broadcaster.id)) {
      _activeBroadcasters.add(event.broadcaster);
      emit(CallRequestLoaded(
        pendingRequests: List.from(_pendingRequests),
        activeBroadcasters: List.from(_activeBroadcasters),
      ));
    }
  }

  void _onLoadInitialBroadcasters(
    LoadInitialBroadcasters event,
    Emitter<CallRequestState> emit,
  ) {
    _activeBroadcasters.clear();
    _activeBroadcasters.addAll(event.broadcasters);
    emit(CallRequestLoaded(
      pendingRequests: List.from(_pendingRequests),
      activeBroadcasters: List.from(_activeBroadcasters),
    ));
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
      emit(CallRequestLoaded(
        pendingRequests: List.from(_pendingRequests),
        activeBroadcasters: List.from(_activeBroadcasters),
      ));
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
    _broadcastersSubscription =
        _repository.broadcasterListStream.listen((broadcasters) {
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
