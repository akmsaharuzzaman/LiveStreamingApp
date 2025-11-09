import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/network/api_service.dart' hide Failure;
import '../../../../core/errors/failures.dart';

abstract class LiveStreamRepository {
  // Room operations
  Future<Either<Failure, void>> createRoom({
    required String userId,
    required String title,
    required RoomType roomType,
  });
  
  Future<Either<Failure, void>> deleteRoom(String roomId);
  
  Future<Either<Failure, void>> joinRoom({
    required String roomId,
    required String userId,
  });
  
  Future<Either<Failure, void>> leaveRoom({
    required String roomId,
    required String userId,
  });
  
  // Bonus operations
  Future<Either<Failure, int>> callDailyBonus({
    required int totalMinutes,
    required String type,
  });
  
  // User management
  Future<Either<Failure, void>> banUser({
    required String roomId,
    required String userId,
  });
  
  Future<Either<Failure, void>> muteUser({
    required String roomId,
    required String userId,
  });
}

@LazySingleton(as: LiveStreamRepository)
class LiveStreamRepositoryImpl implements LiveStreamRepository {
  final SocketService _socketService;
  final ApiService _apiService;

  LiveStreamRepositoryImpl(this._socketService, this._apiService);

  @override
  Future<Either<Failure, void>> createRoom({
    required String userId,
    required String title,
    required RoomType roomType,
  }) async {
    try {
      // Use SocketService's createRoom method instead of emit
      final success = await _socketService.createRoom(userId, title, roomType);
      if (success) {
        return const Right(null);
      } else {
        return Left(ServerFailure('Failed to create room'));
      }
    } catch (e) {
      return Left(ServerFailure('Failed to create room: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRoom(String roomId) async {
    try {
      final response = await _apiService.delete('/api/room/$roomId');
      return response.fold(
        (data) => const Right(null),
        (error) => Left(ServerFailure(error)),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to delete room: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> joinRoom({
    required String roomId,
    required String userId,
  }) async {
    try {
      _socketService.emit('join-room', {
        'roomId': roomId,
        'userId': userId,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to join room: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    try {
      _socketService.emit('leave-room', {
        'roomId': roomId,
        'userId': userId,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to leave room: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> callDailyBonus({
    required int totalMinutes,
    required String type,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/auth/daily-bonus',
        data: {'totalTime': totalMinutes, 'type': type},
      );

      return response.fold(
        (data) {
          if (data['success'] == true && data['result'] != null) {
            final result = data['result'] as Map<String, dynamic>;
            final int bonusDiamonds = result['bonus'] ?? 0;
            return Right(bonusDiamonds);
          }
          return const Right(0);
        },
        (error) => Left(ServerFailure(error)),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to call daily bonus: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> banUser({
    required String roomId,
    required String userId,
  }) async {
    try {
      _socketService.emit('ban-user', {
        'roomId': roomId,
        'userId': userId,
      });
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
      _socketService.emit('mute-user', {
        'roomId': roomId,
        'userId': userId,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to mute user: $e'));
    }
  }
}
