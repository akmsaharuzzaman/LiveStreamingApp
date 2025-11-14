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

  // Join call request
  Future<Either<Failure, void>> joinCallRequest({
    required String roomId,
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
      final isSuccess = await _socketService.acceptCallRequest(
        userId,
        roomId: roomId,
      );
      if (!isSuccess) {
        return Left(ServerFailure('Failed to accept request'));
      }
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
      final isSuccess = await _socketService.rejectCallRequest(
        userId,
        roomId: roomId,
      );
      if (!isSuccess) {
        return Left(ServerFailure('Failed to reject request'));
      }
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
      final isSuccess = await _socketService.removeBroadcaster(
        userId,
        roomId: roomId,
      );
      if (!isSuccess) {
        return Left(ServerFailure('Failed to remove broadcaster'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to remove broadcaster: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> joinCallRequest({
    required String roomId,
  }) async {
    try {
      final isSuccess = await _socketService.joinCallRequest(roomId);
      if (!isSuccess) {
        return Left(ServerFailure('Failed to submit call request'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to submit call request: $e'));
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
