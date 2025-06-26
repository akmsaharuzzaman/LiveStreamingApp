import '../entities/reel_entity.dart';

abstract class ReelsRepository {
  Future<List<ReelEntity>> getReels({int page = 1, int limit = 5});
  Future<bool> likeReel(String reelId);
  Future<bool> shareReel(String reelId);
  Future<bool> addComment(String reelId, String comment);
}
