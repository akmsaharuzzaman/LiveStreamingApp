import 'package:dlstarlive/features/reels/custom_package/src/models/reel_model.dart';
import '../../domain/entities/reel_entity.dart';
import '../../data/models/reel_api_response_model.dart';

class ReelMapper {
  /// Convert API model to entity
  static ReelEntity apiModelToEntity(ReelApiModel apiModel) {
    return ReelEntity(
      id: apiModel.id,
      reelCaption: apiModel.reelCaption,
      status: apiModel.status,
      videoLength: apiModel.videoLength,
      videoMaximumLength: apiModel.videoMaximumLength,
      videoUrl: apiModel.reelUrl,
      reactions: apiModel.reactions,
      comments: apiModel.comments,
      createdAt: apiModel.createdAt,
      userInfo: ReelUserEntity(
        id: apiModel.userInfo.id,
        name: apiModel.userInfo.name,
        avatar: apiModel.userInfo.avatar,
      ),
      latestReactions: apiModel.latestReactions
          .map(
            (reaction) => ReelReactionEntity(
              id: reaction.id,
              reactedBy: reaction.reactedBy,
              reactedTo: reaction.reactedTo,
              reactionType: reaction.reactionType,
              createdAt: reaction.createdAt,
              userInfo: reaction.userInfo != null
                  ? ReelUserEntity(
                      id: reaction.userInfo!.id,
                      name: reaction.userInfo!.name,
                      avatar: reaction.userInfo!.avatar,
                    )
                  : null,
            ),
          )
          .toList(),
      myReaction: apiModel.myReaction != null
          ? ReelReactionEntity(
              id: apiModel.myReaction!.id,
              reactedBy: apiModel.myReaction!.reactedBy,
              reactedTo: apiModel.myReaction!.reactedTo,
              reactionType: apiModel.myReaction!.reactionType,
              createdAt: apiModel.myReaction!.createdAt,
              userInfo: apiModel.myReaction!.userInfo != null
                  ? ReelUserEntity(
                      id: apiModel.myReaction!.userInfo!.id,
                      name: apiModel.myReaction!.userInfo!.name,
                      avatar: apiModel.myReaction!.userInfo!.avatar,
                    )
                  : null,
            )
          : null,
    );
  }

  /// Convert API comment to entity
  static ReelCommentEntity commentApiModelToEntity(ReelComment apiComment) {
    return ReelCommentEntity(
      id: apiComment.id,
      commentedBy: apiComment.commentedBy,
      commentedTo: apiComment.commentedTo,
      parentComment: apiComment.parentComment,
      article: apiComment.article,
      reactionsCount: apiComment.reactionsCount,
      createdAt: apiComment.createdAt,
      updatedAt: apiComment.updatedAt,
      commentedByInfo: ReelUserEntity(
        id: apiComment.commentedByInfo.id,
        name: apiComment.commentedByInfo.name,
        avatar: apiComment.commentedByInfo.avatar,
      ),
      replies: apiComment.replies
          .map((reply) => commentApiModelToEntity(reply))
          .toList(),
    );
  }

  /// Convert entity to ReelModel for UI (backward compatibility)
  static ReelModel entityToReelModel(ReelEntity entity) {
    return ReelModel(
      entity.videoUrl,
      entity.userName,
      likeCount: entity.likeCount,
      isLiked: entity.isLiked,
      musicName: entity.musicName,
      reelDescription: entity.description,
      profileUrl: entity.userAvatar,
      commentList: [], // Comments loaded separately via API
    );
  }

  static List<ReelModel> entitiesToReelModels(List<ReelEntity> entities) {
    return entities.map((entity) => entityToReelModel(entity)).toList();
  }

  static List<ReelEntity> apiModelsToEntities(List<ReelApiModel> apiModels) {
    return apiModels.map((apiModel) => apiModelToEntity(apiModel)).toList();
  }
}
