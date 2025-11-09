import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/network/api_service.dart' hide Failure;
import '../../../../core/network/models/call_request_model.dart';
import '../../../../core/network/models/call_request_list_model.dart';
import '../../../../core/network/models/broadcaster_model.dart';
import '../../../../core/errors/failures.dart';

abstract class CallRequestRepository {
  // Accept call request
  Future<Either<Failure, void>> acceptRequest({
    required String roomId,
    required String userId,
  });

  // Reject call request
  Future<Either<Failure, void>> rejectRequest({
    required String roomId,
    required String userId,
  });

  // Remove broadcaster
  Future<Either<Failure, void>> removeBroadcaster({
    required String roomId,
    required String userId,
  });

  // Streams
  Stream<CallRequestModel> get requestsStream;
  Stream<List<CallRequestListModel>> get requestListStream;
  Stream<List<BroadcasterModel>> get broadcasterListStream;
}

@LazySingleton(as: CallRequestRepository)
class CallRequestRepositoryImpl implements CallRequestRepository {
  final SocketService _socketService;
  // ignore: unused_field
  final ApiService _apiService;

  CallRequestRepositoryImpl(this._socketService, this._apiService);

  @override
  Future<Either<Failure, void>> acceptRequest({
    required String roomId,
    required String userId,
  }) async {
    try {
      _socketService.emit('accept-call-request', {
        'roomId': roomId,
        'userId': userId,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to accept request: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> rejectRequest({
    required String roomId,
    required String userId,
  }) async {
    try {
      _socketService.emit('reject-call-request', {
        'roomId': roomId,
        'userId': userId,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to reject request: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeBroadcaster({
    required String roomId,
    required String userId,
  }) async {
    try {
      _socketService.emit('remove-broadcaster', {
        'roomId': roomId,
        'userId': userId,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to remove broadcaster: $e'));
    }
  }

  @override
  Stream<CallRequestModel> get requestsStream =>
      _socketService.joinCallRequestStream;

  @override
  Stream<List<CallRequestListModel>> get requestListStream =>
      _socketService.joinCallRequestListStream;

  @override
  Stream<List<BroadcasterModel>> get broadcasterListStream =>
    _socketService.broadcasterListStream;
}
