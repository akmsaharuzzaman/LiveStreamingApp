import '../entities/reel_entity.dart';

abstract class ReelsRepository {
  Future<List<ReelEntity>> getReels({int page = 1, int limit = 5});
  Future<bool> likeReel(String reelId);
  Future<bool> shareReel(String reelId);
  Future<bool> addComment(String reelId, String comment);

  // Comment management
  Future<Map<String, dynamic>?> getReelComments(
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
