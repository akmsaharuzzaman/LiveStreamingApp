import 'package:equatable/equatable.dart';
import '../../../../core/network/models/gift_model.dart';

/// Events for Gift feature
abstract class GiftEvent extends Equatable {
  const GiftEvent();

  @override
  List<Object?> get props => [];
}

/// Send a gift
class SendGift extends GiftEvent {
  final String roomId;
  final String senderId;
  final String receiverId;
  final String giftId;
  final String giftName;
  final int giftValue;
  final String? giftImage;

  const SendGift({
    required this.roomId,
    required this.senderId,
    required this.receiverId,
    required this.giftId,
    required this.giftName,
    required this.giftValue,
    this.giftImage,
  });

  @override
  List<Object?> get props => [
        roomId,
        senderId,
        receiverId,
        giftId,
        giftName,
        giftValue,
        giftImage,
      ];
}

/// Receive a gift
class ReceiveGift extends GiftEvent {
  final GiftModel gift;

  const ReceiveGift(this.gift);

  @override
  List<Object?> get props => [gift];
}

/// Load initial gifts
class LoadInitialGifts extends GiftEvent {
  final List<GiftModel> gifts;

  const LoadInitialGifts(this.gifts);

  @override
  List<Object?> get props => [gifts];
}

/// Clear all gifts
class ClearGifts extends GiftEvent {
  const ClearGifts();
}
