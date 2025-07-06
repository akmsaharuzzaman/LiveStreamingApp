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
  final GetReelCommentsUseCase getReelCommentsUseCase;
  final EditCommentUseCase editCommentUseCase;
  final DeleteCommentUseCase deleteCommentUseCase;
  final ReactToCommentUseCase reactToCommentUseCase;
  final ReplyToCommentUseCase replyToCommentUseCase;

  static const int _limit = 5;

  ReelsBloc({
    required this.getReelsUseCase,
    required this.likeReelUseCase,
    required this.shareReelUseCase,
    required this.addCommentUseCase,
    required this.getReelCommentsUseCase,
    required this.editCommentUseCase,
    required this.deleteCommentUseCase,
    required this.reactToCommentUseCase,
    required this.replyToCommentUseCase,
  }) : super(ReelsInitial()) {
    on<LoadReels>(_onLoadReels);
    on<LoadMoreReels>(_onLoadMoreReels);
    on<RefreshReels>(_onRefreshReels);
    on<LikeReel>(_onLikeReel);
    on<ShareReel>(_onShareReel);
    on<AddComment>(_onAddComment);
    on<GetReelComments>(_onGetReelComments);
    on<EditComment>(_onEditComment);
    on<DeleteComment>(_onDeleteComment);
    on<ReactToComment>(_onReactToComment);
    on<ReplyToComment>(_onReplyToComment);
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

  Future<void> _onGetReelComments(
    GetReelComments event,
    Emitter<ReelsState> emit,
  ) async {
    try {
      final comments = await getReelCommentsUseCase(
        event.reelId,
        page: event.page,
        limit: event.limit,
      );
      if (comments != null) {
        log('Successfully got comments for reel: ${event.reelId}');
        // You could emit a specific state for comments here if needed
      }
    } catch (e) {
      log('Error getting reel comments: $e');
    }
  }

  Future<void> _onEditComment(
    EditComment event,
    Emitter<ReelsState> emit,
  ) async {
    try {
      final success = await editCommentUseCase(
        event.commentId,
        event.newComment,
      );
      if (success) {
        log('Comment edited successfully: ${event.commentId}');
      }
    } catch (e) {
      log('Error editing comment: $e');
    }
  }

  Future<void> _onDeleteComment(
    DeleteComment event,
    Emitter<ReelsState> emit,
  ) async {
    try {
      final success = await deleteCommentUseCase(event.reelId, event.commentId);
      if (success) {
        log('Comment deleted successfully: ${event.commentId}');
      }
    } catch (e) {
      log('Error deleting comment: $e');
    }
  }

  Future<void> _onReactToComment(
    ReactToComment event,
    Emitter<ReelsState> emit,
  ) async {
    try {
      final success = await reactToCommentUseCase(
        event.commentId,
        event.reactionType,
      );
      if (success) {
        log('Reacted to comment successfully: ${event.commentId}');
      }
    } catch (e) {
      log('Error reacting to comment: $e');
    }
  }

  Future<void> _onReplyToComment(
    ReplyToComment event,
    Emitter<ReelsState> emit,
  ) async {
    try {
      final success = await replyToCommentUseCase(
        event.commentId,
        event.reelId,
        event.commentText,
      );
      if (success) {
        log('Replied to comment successfully: ${event.commentId}');
      }
    } catch (e) {
      log('Error replying to comment: $e');
    }
  }
}
