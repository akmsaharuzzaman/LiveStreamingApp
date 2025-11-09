import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/network/api_service.dart' hide Failure;
import '../../../../core/network/models/gift_model.dart';
import '../../../../core/errors/failures.dart';

abstract class GiftRepository {
  // Send gift
  Future<Either<Failure, void>> sendGift({
    required String roomId,
    required String senderId,
    required String receiverId,
    required String giftId,
    required String giftName,
    required int giftValue,
    String? giftImage,
  });

  // Stream of incoming gifts
  Stream<GiftModel> get giftsStream;
}

@LazySingleton(as: GiftRepository)
class GiftRepositoryImpl implements GiftRepository {
  final SocketService _socketService;
  final ApiService _apiService;

  GiftRepositoryImpl(this._socketService, this._apiService);

  @override
  Future<Either<Failure, void>> sendGift({
    required String roomId,
    required String senderId,
    required String receiverId,
    required String giftId,
    required String giftName,
    required int giftValue,
    String? giftImage,
  }) async {
    try {
      // First, deduct diamonds via API
      final response = await _apiService.post(
        '/api/gifts/send',
        data: {
          'senderId': senderId,
          'receiverId': receiverId,
          'giftId': giftId,
          'giftValue': giftValue,
          'roomId': roomId,
        },
      );

      return response.fold(
        (success) {
          // Then emit via socket for real-time update
          _socketService.emit('send-gift', {
            'roomId': roomId,
            'senderId': senderId,
            'receiverId': receiverId,
            'giftId': giftId,
            'giftName': giftName,
            'giftValue': giftValue,
            'giftImage': giftImage,
            'timestamp': DateTime.now().toIso8601String(),
          });
          return const Right(null);
        },
        (error) => Left(ServerFailure(error)),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to send gift: $e'));
    }
  }

  @override
  Stream<GiftModel> get giftsStream => _socketService.sentGiftStream;
}
