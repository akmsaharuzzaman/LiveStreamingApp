import 'dart:developer';

import '../../domain/entities/reel_entity.dart';
import '../../domain/repositories/reels_repository.dart';
import '../models/reel_model.dart';
import '../services/reels_api_service.dart';

class ReelsRepositoryImpl implements ReelsRepository {
  final ReelsApiService apiService;

  ReelsRepositoryImpl(this.apiService);

  @override
  Future<List<ReelEntity>> getReels({int page = 1, int limit = 5}) async {
    try {
      log('Fetching reels from API (page: $page, limit: $limit)');
      final apiResponse = await apiService.getReels(page: page, limit: limit);
      final entities = apiResponse.result.data
          .map((apiReel) => _mapToEntity(apiReel))
          .toList();
      log('Successfully fetched ${entities.length} reels from API');
      return entities;
    } catch (e) {
      log('Error fetching reels from API: $e');
      log('Falling back to dummy data');
      // Return dummy data as fallback
      return _getDummyReels();
    }
  }

  @override
  Future<bool> likeReel(String reelId) async {
    try {
      return await apiService.reactToReel(reelId: reelId, reactionType: 'like');
    } catch (e) {
      log('Error liking reel: $e');
      return false;
    }
  }

  @override
  Future<bool> shareReel(String reelId) async {
    try {
      return await apiService.shareReel(reelId: reelId);
    } catch (e) {
      log('Error sharing reel: $e');
      return false;
    }
  }

  @override
  Future<bool> addComment(String reelId, String comment) async {
    try {
      return await apiService.commentOnReel(reelId: reelId, comment: comment);
    } catch (e) {
      log('Error adding comment: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getReelComments(
    String reelId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      return await apiService.getReelComments(
        reelId: reelId,
        page: page,
        limit: limit,
      );
    } catch (e) {
      log('Error getting reel comments: $e');
      return null;
    }
  }

  @override
  Future<bool> editComment(String commentId, String newComment) async {
    try {
      return await apiService.editReelComment(
        commentId: commentId,
        newComment: newComment,
      );
    } catch (e) {
      log('Error editing comment: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteComment(String reelId, String commentId) async {
    try {
      return await apiService.deleteReelComment(
        reelId: reelId,
        commentId: commentId,
      );
    } catch (e) {
      log('Error deleting comment: $e');
      return false;
    }
  }

  @override
  Future<bool> reactToComment(String commentId, String reactionType) async {
    try {
      return await apiService.reactToReelComment(
        commentId: commentId,
        reactionType: reactionType,
      );
    } catch (e) {
      log('Error reacting to comment: $e');
      return false;
    }
  }

  @override
  Future<bool> replyToComment(
    String commentId,
    String reelId,
    String commentText,
  ) async {
    try {
      return await apiService.replyToReelComment(
        commentId: commentId,
        reelId: reelId,
        commentText: commentText,
      );
    } catch (e) {
      log('Error replying to comment: $e');
      return false;
    }
  }

  ReelEntity _mapToEntity(ReelApiModel apiReel) {
    return ReelEntity(
      id: apiReel.id,
      videoUrl: apiReel.reelUrl.isNotEmpty
          ? apiReel.reelUrl
          : 'https://parsefiles.back4app.com/SM60vnNNpjvoH6PA6ljZAa6IyAYVb1oWVVid8G4A/825ccd06d87e4f707cf54d746a9f017c_lv_7263925596898610433_20230818030011_1738902212119.mp4',
      userName: apiReel.userInfo.name,
      userAvatar:
          apiReel.userInfo.avatar?.url ??
          'https://opt.toiimg.com/recuperator/img/toi/m-69257289/69257289.jpg',
      description:
          'Amazing reel content!', // API doesn't provide description, using dummy
      musicName: 'Unknown Music', // API doesn't provide music, using dummy
      likeCount: apiReel.reactions,
      commentCount: apiReel.comments,
      shareCount: 0, // API doesn't provide share count, using dummy
      isLiked: _checkIfLiked(apiReel.latestReactions),
      isFollowing: false, // This field doesn't exist in API, using dummy
      comments: _mapComments(apiReel.latestReactions),
    );
  }

  bool _checkIfLiked(List<ReactionInfo> reactions) {
    // This is a simplified check - in real implementation,
    // you'd check if current user has liked
    return reactions.any((reaction) => reaction.reactionType == 'like');
  }

  List<CommentEntity> _mapComments(List<ReactionInfo> reactions) {
    // For now, we'll treat reactions as comments for demo purposes
    // In real implementation, you'd have separate comments API
    return reactions
        .take(3)
        .map(
          (reaction) => CommentEntity(
            id: reaction.id,
            comment: 'Nice ${reaction.reactionType}!',
            userName: reaction.userInfo?.name ?? 'Anonymous',
            userProfilePic:
                reaction.userInfo?.avatar?.url ??
                'https://opt.toiimg.com/recuperator/img/toi/m-69257289/69257289.jpg',
            commentTime: reaction.createdAt,
          ),
        )
        .toList();
  }

  List<ReelEntity> _getDummyReels() {
    return [
      ReelEntity(
        id: 'dummy1',
        videoUrl:
            'https://parsefiles.back4app.com/SM60vnNNpjvoH6PA6ljZAa6IyAYVb1oWVVid8G4A/825ccd06d87e4f707cf54d746a9f017c_lv_7263925596898610433_20230818030011_1738902212119.mp4',
        userName: 'Darshan Patil',
        userAvatar:
            'https://opt.toiimg.com/recuperator/img/toi/m-69257289/69257289.jpg',
        description: "Life is better when you're laughing.",
        musicName: 'In the name of Love',
        likeCount: 2000,
        commentCount: 3,
        shareCount: 100,
        isLiked: true,
        isFollowing: false,
        comments: [],
      ),
      ReelEntity(
        id: 'dummy2',
        videoUrl:
            'https://parsefiles.back4app.com/SM60vnNNpjvoH6PA6ljZAa6IyAYVb1oWVVid8G4A/fd1764f362cf3b5530bd48aef7aa05f5_VID-20250209-WA0027_1739109909693.mp4',
        userName: 'Rahul',
        userAvatar:
            'https://opt.toiimg.com/recuperator/img/toi/m-69257289/69257289.jpg',
        description: "Amazing content!",
        musicName: 'In the name of Love',
        likeCount: 1500,
        commentCount: 5,
        shareCount: 80,
        isLiked: false,
        isFollowing: false,
        comments: [],
      ),
    ];
  }
}
