import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/reels_usecases.dart';
import 'reels_event.dart';
import 'reels_state.dart';

class ReelsBloc extends Bloc<ReelsEvent, ReelsState> {
  final GetReelsUseCase getReelsUseCase;
  final LikeReelUseCase likeReelUseCase;
  final ShareReelUseCase shareReelUseCase;
  final AddCommentUseCase addCommentUseCase;

  static const int _limit = 5;

  ReelsBloc({
    required this.getReelsUseCase,
    required this.likeReelUseCase,
    required this.shareReelUseCase,
    required this.addCommentUseCase,
  }) : super(ReelsInitial()) {
    on<LoadReels>(_onLoadReels);
    on<LoadMoreReels>(_onLoadMoreReels);
    on<RefreshReels>(_onRefreshReels);
    on<LikeReel>(_onLikeReel);
    on<ShareReel>(_onShareReel);
    on<AddComment>(_onAddComment);
  }

  Future<void> _onLoadReels(LoadReels event, Emitter<ReelsState> emit) async {
    emit(ReelsLoading());
    try {
      final reels = await getReelsUseCase(page: 1, limit: _limit);
      emit(
        ReelsLoaded(
          reels: reels,
          hasReachedMax: reels.length < _limit,
          currentPage: 1,
        ),
      );
    } catch (e) {
      log('Error loading reels: $e');
      emit(ReelsError('Failed to load reels'));
    }
  }

  Future<void> _onLoadMoreReels(
    LoadMoreReels event,
    Emitter<ReelsState> emit,
  ) async {
    final currentState = state;
    if (currentState is ReelsLoaded && !currentState.hasReachedMax) {
      try {
        final nextPage = currentState.currentPage + 1;
        final newReels = await getReelsUseCase(page: nextPage, limit: _limit);

        emit(
          currentState.copyWith(
            reels: [...currentState.reels, ...newReels],
            hasReachedMax: newReels.length < _limit,
            currentPage: nextPage,
          ),
        );
      } catch (e) {
        log('Error loading more reels: $e');
        // Don't emit error for pagination failure, just log it
      }
    }
  }

  Future<void> _onRefreshReels(
    RefreshReels event,
    Emitter<ReelsState> emit,
  ) async {
    try {
      final reels = await getReelsUseCase(page: 1, limit: _limit);
      emit(
        ReelsLoaded(
          reels: reels,
          hasReachedMax: reels.length < _limit,
          currentPage: 1,
        ),
      );
    } catch (e) {
      log('Error refreshing reels: $e');
      emit(ReelsError('Failed to refresh reels'));
    }
  }

  Future<void> _onLikeReel(LikeReel event, Emitter<ReelsState> emit) async {
    try {
      final success = await likeReelUseCase(event.reelId);
      if (success) {
        log('Reel liked successfully: ${event.reelId}');
        // Optionally update the local state here
      }
    } catch (e) {
      log('Error liking reel: $e');
    }
  }

  Future<void> _onShareReel(ShareReel event, Emitter<ReelsState> emit) async {
    try {
      final success = await shareReelUseCase(event.reelId);
      if (success) {
        log('Reel shared successfully: ${event.reelId}');
      }
    } catch (e) {
      log('Error sharing reel: $e');
    }
  }

  Future<void> _onAddComment(AddComment event, Emitter<ReelsState> emit) async {
    try {
      final success = await addCommentUseCase(event.reelId, event.comment);
      if (success) {
        log('Comment added successfully: ${event.comment}');
      }
    } catch (e) {
      log('Error adding comment: $e');
    }
  }
}
