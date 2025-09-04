import '../entities/reel_entity.dart';

abstract class ReelsRepository {
  Future<List<ReelEntity>> getReels({int page = 1, int limit = 5});
  Future<List<ReelEntity>> getUserReels(
    String userId, {
    int page = 1,
    int limit = 5,
  });
  Future<bool> likeReel(String reelId);
  Future<bool> reactToReel(String reelId, String reactionType);
  Future<bool> shareReel(String reelId);
  Future<bool> addComment(String reelId, String comment);
  Future<bool> uploadReel(
    String videoPath,
    String videoLength, {
    String? reelCaption,
  });

  // Comment management
  Future<List<ReelCommentEntity>?> getReelComments(
    String reelId, {
    int page = 1,
    int limit = 10,
  });
  Future<bool> editComment(String commentId, String newComment);
  Future<bool> deleteComment(String reelId, String commentId);
  Future<bool> reactToComment(String commentId, String reactionType);
  Future<bool> replyToComment(
    String commentId,
    String reelId,
    String commentText,
  );
}
