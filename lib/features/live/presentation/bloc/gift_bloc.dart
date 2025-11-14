import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/repositories/gift_repository.dart';
import 'gift_event.dart';
import 'gift_state.dart';
import '../../../../core/network/models/gift_model.dart';

@injectable
class GiftBloc extends Bloc<GiftEvent, GiftState> {
  final GiftRepository _repository;

  // Subscription for cleanup
  StreamSubscription? _giftsSubscription;

  // Store gifts in memory
  final List<GiftModel> _gifts = [];

  GiftBloc(this._repository) : super(const GiftInitial()) {
    on<SendGift>(_onSendGift);
    on<ReceiveGift>(_onReceiveGift);
    on<LoadInitialGifts>(_onLoadInitialGifts);
    on<ClearGifts>(_onClearGifts);

    // Setup stream listener
    _setupGiftListener();
  }

  Future<void> _onSendGift(
    SendGift event,
    Emitter<GiftState> emit,
  ) async {
    try {
      emit(const GiftSending());

      final result = await _repository.sendGift(
        roomId: event.roomId,
        senderId: event.senderId,
        receiverId: event.receiverId,
        giftId: event.giftId,
        giftName: event.giftName,
        giftValue: event.giftValue,
        giftImage: event.giftImage,
      );

      result.fold(
        (failure) {
          emit(GiftError(failure.message));
          // Return to loaded state
          final totalDiamonds = GiftModel.totalDiamondsForHost(_gifts, event.receiverId);
          emit(GiftLoaded(gifts: List.from(_gifts), totalEarnedDiamonds: totalDiamonds));
        },
        (_) {
          emit(const GiftSent());
          // Return to loaded state
          final totalDiamonds = GiftModel.totalDiamondsForHost(_gifts, event.receiverId);
          emit(GiftLoaded(gifts: List.from(_gifts), totalEarnedDiamonds: totalDiamonds));
        },
      );
    } catch (e) {
      emit(GiftError('Failed to send gift: $e'));
      final currentState = state;
      if (currentState is GiftLoaded) {
        emit(currentState);
      }
    }
  }

  void _onReceiveGift(
    ReceiveGift event,
    Emitter<GiftState> emit,
  ) {
    _gifts.add(event.gift);
    
    // Calculate total for all receivers
    final totalDiamonds = GiftModel.totalDiamonds(_gifts);
    emit(GiftLoaded(gifts: List.from(_gifts), totalEarnedDiamonds: totalDiamonds));
  }

  void _onLoadInitialGifts(
    LoadInitialGifts event,
    Emitter<GiftState> emit,
  ) {
    _gifts.clear();
    _gifts.addAll(event.gifts);
    
    final totalDiamonds = GiftModel.totalDiamonds(_gifts);
    emit(GiftLoaded(gifts: List.from(_gifts), totalEarnedDiamonds: totalDiamonds));
  }

  void _onClearGifts(
    ClearGifts event,
    Emitter<GiftState> emit,
  ) {
    _gifts.clear();
    emit(const GiftInitial());
  }

  void _setupGiftListener() {
    _giftsSubscription = _repository.giftsStream.listen((gift) {
      add(ReceiveGift(gift));
    });
  }

  @override
  Future<void> close() {
    _giftsSubscription?.cancel();
    return super.close();
  }
}
