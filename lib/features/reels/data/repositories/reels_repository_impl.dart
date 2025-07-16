import 'dart:developer';

import '../../domain/entities/reel_entity.dart';
import '../../domain/repositories/reels_repository.dart';
import '../services/reels_api_service.dart';
import '../../presentation/utils/reel_mapper.dart';

class ReelsRepositoryImpl implements ReelsRepository {
  final ReelsApiService apiService;

  ReelsRepositoryImpl(this.apiService);

  @override
  Future<List<ReelEntity>> getReels({int page = 1, int limit = 5}) async {
    try {
      log('Fetching reels from API (page: $page, limit: $limit)');
      final apiResponse = await apiService.getReels(page: page, limit: limit);
      final entities = ReelMapper.apiModelsToEntities(apiResponse.result.data);
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
  Future<List<ReelEntity>> getUserReels(
    String userId, {
    int page = 1,
    int limit = 5,
  }) async {
    try {
      log(
        'Fetching user reels from API (userId: $userId, page: $page, limit: $limit)',
      );
      final apiResponse = await apiService.getUserReels(
        userId: userId,
        page: page,
        limit: limit,
      );
      final entities = ReelMapper.apiModelsToEntities(apiResponse.result.data);
      log('Successfully fetched ${entities.length} user reels from API');
      return entities;
    } catch (e) {
      log('Error fetching user reels from API: $e');
      log('Falling back to dummy data');
      // Return dummy data as fallback
      return _getDummyReels()
          .where((reel) => reel.userInfo.id == userId)
          .toList();
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
  Future<List<ReelCommentEntity>?> getReelComments(
    String reelId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final apiResponse = await apiService.getReelComments(
        reelId: reelId,
        page: page,
        limit: limit,
      );

      if (apiResponse != null) {
        return apiResponse.result.data
            .map((comment) => ReelMapper.commentApiModelToEntity(comment))
            .toList();
      }
      return null;
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

  @override
  Future<bool> uploadReel(
    String videoPath,
    String videoLength, {
    String? reelCaption,
  }) async {
    try {
      return await apiService.uploadReel(
        videoPath: videoPath,
        videoLength: videoLength,
        reelCaption: reelCaption,
      );
    } catch (e) {
      log('Error uploading reel: $e');
      return false;
    }
  }

  List<ReelEntity> _getDummyReels() {
    return [
      ReelEntity(
        id: 'dummy1',
        reelCaption: 'Beautiful nature video',
        status: 'published',
        videoLength: 30,
        videoMaximumLength: 60,
        videoUrl:
            'https://assets.mixkit.co/videos/preview/mixkit-tree-with-yellow-flowers-1173-large.mp4',
        reactions: 2000,
        comments: 3,
        createdAt: DateTime.now().toIso8601String(),
        userInfo: ReelUserEntity(
          id: 'user1',
          name: 'Darshan Patil',
          avatar:
              'https://opt.toiimg.com/recuperator/img/toi/m-69257289/69257289.jpg',
        ),
        latestReactions: [],
        myReaction: ReelReactionEntity(
          id: 'reaction1',
          reactedBy: 'currentUser',
          reactedTo: 'dummy1',
          reactionType: 'like',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ),
      ReelEntity(
        id: 'dummy2',
        reelCaption: 'Family time with marshmallows',
        status: 'published',
        videoLength: 45,
        videoMaximumLength: 60,
        videoUrl:
            'https://assets.mixkit.co/videos/preview/mixkit-father-and-his-little-daughter-eating-marshmallows-in-nature-39765-large.mp4',
        reactions: 1500,
        comments: 5,
        createdAt: DateTime.now().toIso8601String(),
        userInfo: ReelUserEntity(
          id: 'user2',
          name: 'Rahul',
          avatar:
              'https://opt.toiimg.com/recuperator/img/toi/m-69257289/69257289.jpg',
        ),
        latestReactions: [],
      ),
      ReelEntity(
        id: 'dummy3',
        reelCaption: 'Sweet moments in nature',
        status: 'published',
        videoLength: 35,
        videoMaximumLength: 60,
        videoUrl:
            'https://assets.mixkit.co/videos/preview/mixkit-mother-with-her-little-daughter-eating-a-marshmallow-in-nature-39764-large.mp4',
        reactions: 800,
        comments: 2,
        createdAt: DateTime.now().toIso8601String(),
        userInfo: ReelUserEntity(
          id: 'user3',
          name: 'Rahul',
          avatar:
              'https://opt.toiimg.com/recuperator/img/toi/m-69257289/69257289.jpg',
        ),
        latestReactions: [],
      ),
    ];
  }
}
