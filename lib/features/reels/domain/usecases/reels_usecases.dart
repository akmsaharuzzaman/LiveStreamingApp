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

class GetReelCommentsUseCase {
  final ReelsRepository repository;

  GetReelCommentsUseCase(this.repository);

  Future<List<ReelCommentEntity>?> call(
    String reelId, {
    int page = 1,
    int limit = 10,
  }) async {
    return await repository.getReelComments(reelId, page: page, limit: limit);
  }
}

class EditCommentUseCase {
  final ReelsRepository repository;

  EditCommentUseCase(this.repository);

  Future<bool> call(String commentId, String newComment) async {
    return await repository.editComment(commentId, newComment);
  }
}

class DeleteCommentUseCase {
  final ReelsRepository repository;

  DeleteCommentUseCase(this.repository);

  Future<bool> call(String reelId, String commentId) async {
    return await repository.deleteComment(reelId, commentId);
  }
}

class ReactToCommentUseCase {
  final ReelsRepository repository;

  ReactToCommentUseCase(this.repository);

  Future<bool> call(String commentId, String reactionType) async {
    return await repository.reactToComment(commentId, reactionType);
  }
}

class ReplyToCommentUseCase {
  final ReelsRepository repository;

  ReplyToCommentUseCase(this.repository);

  Future<bool> call(String commentId, String reelId, String commentText) async {
    return await repository.replyToComment(commentId, reelId, commentText);
  }
}
