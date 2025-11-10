import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/models/admin_details_model.dart';
import '../../../../core/network/models/ban_user_model.dart';
import '../../../../core/network/models/mute_user_model.dart';
import '../../../../core/network/socket_service.dart';

abstract class ModerationRepository {
  Future<Either<Failure, void>> banUser({
    required String roomId,
    required String userId,
  });

  Future<Either<Failure, void>> muteUser({
    required String roomId,
    required String userId,
  });

  Future<Either<Failure, void>> toggleAdmin({
    required String roomId,
    required String userId,
  });

  Stream<List<String>> get bannedUserIdsStream;
  Stream<BanUserModel> get bannedUserStream;
  Stream<MuteUserModel> get muteUserStream;
  Stream<AdminDetailsModel> get adminDetailsStream;
}

@LazySingleton(as: ModerationRepository)
class ModerationRepositoryImpl implements ModerationRepository {
  final SocketService _socketService;

  ModerationRepositoryImpl(this._socketService);

  @override
  Future<Either<Failure, void>> banUser({
    required String roomId,
    required String userId,
  }) async {
    try {
      final isSuccess = await _socketService.banUser(
        userId,
        roomId: roomId,
      );
      if (!isSuccess) {
        return Left(ServerFailure('Failed to ban user'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to ban user: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> muteUser({
    required String roomId,
    required String userId,
  }) async {
    try {
      final isSuccess = await _socketService.muteUser(
        userId,
        roomId: roomId,
      );
      if (!isSuccess) {
        return Left(ServerFailure('Failed to mute user'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to mute user: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleAdmin({
    required String roomId,
    required String userId,
  }) async {
    try {
      final isSuccess = await _socketService.makeAdmin(
        userId,
        roomId: roomId,
      );
      if (!isSuccess) {
        return Left(ServerFailure('Failed to update admin status'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to update admin status: $e'));
    }
  }

  @override
  Stream<List<String>> get bannedUserIdsStream =>
      _socketService.bannedListStream;

  @override
  Stream<BanUserModel> get bannedUserStream =>
      _socketService.bannedUserStream;

  @override
  Stream<MuteUserModel> get muteUserStream =>
      _socketService.muteUserStream;

  @override
  Stream<AdminDetailsModel> get adminDetailsStream =>
      _socketService.adminDetailsStream;
}
