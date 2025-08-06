import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/reels_usecases.dart';
import '../../domain/entities/reel_entity.dart';
import 'reels_event.dart';
import 'reels_state.dart';

class ReelsBloc extends Bloc<ReelsEvent, ReelsState> {
  final GetReelsUseCase getReelsUseCase;
  final LikeReelUseCase likeReelUseCase;
  final ReactToReelUseCase reactToReelUseCase;
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
    required this.reactToReelUseCase,
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
    on<ReactToReel>(_onReactToReel);
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
        // Update the local state
        _updateReelReaction(event.reelId, 'like', emit);
      }
    } catch (e) {
      log('Error liking reel: $e');
    }
  }

  Future<void> _onReactToReel(
    ReactToReel event,
    Emitter<ReelsState> emit,
  ) async {
    try {
      final success = await reactToReelUseCase(
        event.reelId,
        event.reactionType,
      );
      if (success) {
        log(
          'Reel reacted successfully: ${event.reelId} with ${event.reactionType}',
        );
        // Update the local state
        _updateReelReaction(event.reelId, event.reactionType, emit);
      }
    } catch (e) {
      log('Error reacting to reel: $e');
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
        // Update comment count in local state
        _updateCommentCount(event.reelId, emit);
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

  /// Helper method to update reel reaction in local state
  void _updateReelReaction(
    String reelId,
    String reactionType,
    Emitter<ReelsState> emit,
  ) {
    final currentState = state;
    if (currentState is ReelsLoaded) {
      final updatedReels = currentState.reels.map((reel) {
        if (reel.id == reelId) {
          // Check if user already reacted
          final hadPreviousReaction = reel.hasUserReacted;
          final previousReactionType = reel.userReactionType;

          if (hadPreviousReaction && previousReactionType == reactionType) {
            // User is removing their reaction (toggle off)
            return ReelEntity(
              id: reel.id,
              reelCaption: reel.reelCaption,
              status: reel.status,
              videoLength: reel.videoLength,
              videoMaximumLength: reel.videoMaximumLength,
              videoUrl: reel.videoUrl,
              reactions: reel.reactions - 1, // Decrease reaction count
              comments: reel.comments,
              createdAt: reel.createdAt,
              userInfo: reel.userInfo,
              latestReactions: reel.latestReactions,
              myReaction: null, // Remove user's reaction
            );
          } else {
            // User is adding a new reaction or changing reaction type
            int newReactionCount = reel.reactions;
            if (hadPreviousReaction) {
              // Changing reaction type (count stays same)
              newReactionCount = reel.reactions;
            } else {
              // Adding new reaction
              newReactionCount = reel.reactions + 1;
            }

            return ReelEntity(
              id: reel.id,
              reelCaption: reel.reelCaption,
              status: reel.status,
              videoLength: reel.videoLength,
              videoMaximumLength: reel.videoMaximumLength,
              videoUrl: reel.videoUrl,
              reactions: newReactionCount,
              comments: reel.comments,
              createdAt: reel.createdAt,
              userInfo: reel.userInfo,
              latestReactions: reel.latestReactions,
              myReaction: ReelReactionEntity(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                reactedBy:
                    'currentUser', // You might want to get actual user ID
                reactedTo: reelId,
                reactionType: reactionType,
                createdAt: DateTime.now().toIso8601String(),
              ),
            );
          }
        }
        return reel;
      }).toList();

      emit(currentState.copyWith(reels: updatedReels));
    }
  }

  /// Helper method to update comment count in local state
  void _updateCommentCount(String reelId, Emitter<ReelsState> emit) {
    final currentState = state;
    if (currentState is ReelsLoaded) {
      final updatedReels = currentState.reels.map((reel) {
        if (reel.id == reelId) {
          return ReelEntity(
            id: reel.id,
            reelCaption: reel.reelCaption,
            status: reel.status,
            videoLength: reel.videoLength,
            videoMaximumLength: reel.videoMaximumLength,
            videoUrl: reel.videoUrl,
            reactions: reel.reactions,
            comments: reel.comments + 1, // Increment comment count
            createdAt: reel.createdAt,
            userInfo: reel.userInfo,
            latestReactions: reel.latestReactions,
            myReaction: reel.myReaction,
          );
        }
        return reel;
      }).toList();

      emit(currentState.copyWith(reels: updatedReels));
    }
  }
}
