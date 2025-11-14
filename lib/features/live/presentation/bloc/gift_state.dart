import 'package:equatable/equatable.dart';
import '../../../../core/network/models/gift_model.dart';

/// States for Gift feature
abstract class GiftState extends Equatable {
  const GiftState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class GiftInitial extends GiftState {
  const GiftInitial();
}

/// Gifts loaded
class GiftLoaded extends GiftState {
  final List<GiftModel> gifts;
  final int totalEarnedDiamonds;

  const GiftLoaded({
    required this.gifts,
    this.totalEarnedDiamonds = 0,
  });

  GiftLoaded copyWith({
    List<GiftModel>? gifts,
    int? totalEarnedDiamonds,
  }) {
    return GiftLoaded(
      gifts: gifts ?? this.gifts,
      totalEarnedDiamonds: totalEarnedDiamonds ?? this.totalEarnedDiamonds,
    );
  }

  @override
  List<Object?> get props => [gifts, totalEarnedDiamonds];
}

/// Sending gift
class GiftSending extends GiftState {
  const GiftSending();
}

/// Gift sent successfully
class GiftSent extends GiftState {
  const GiftSent();
}

/// Error sending gift
class GiftError extends GiftState {
  final String message;

  const GiftError(this.message);

  @override
  List<Object?> get props => [message];
}
