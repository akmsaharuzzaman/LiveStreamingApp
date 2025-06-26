import '../entities/reel_entity.dart';
import '../repositories/reels_repository.dart';

class GetReelsUseCase {
  final ReelsRepository repository;

  GetReelsUseCase(this.repository);

  Future<List<ReelEntity>> call({int page = 1, int limit = 5}) async {
    return await repository.getReels(page: page, limit: limit);
  }
}

class LikeReelUseCase {
  final ReelsRepository repository;

  LikeReelUseCase(this.repository);

  Future<bool> call(String reelId) async {
    return await repository.likeReel(reelId);
  }
}

class ShareReelUseCase {
  final ReelsRepository repository;

  ShareReelUseCase(this.repository);

  Future<bool> call(String reelId) async {
    return await repository.shareReel(reelId);
  }
}

class AddCommentUseCase {
  final ReelsRepository repository;

  AddCommentUseCase(this.repository);

  Future<bool> call(String reelId, String comment) async {
    return await repository.addComment(reelId, comment);
  }
}
