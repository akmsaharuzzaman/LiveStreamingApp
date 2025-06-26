import 'package:reels_viewer/reels_viewer.dart';
import '../../domain/entities/reel_entity.dart';

class ReelMapper {
  static ReelModel entityToReelModel(ReelEntity entity) {
    return ReelModel(
      entity.videoUrl,
      entity.userName,
      likeCount: entity.likeCount,
      isLiked: entity.isLiked,
      musicName: entity.musicName,
      reelDescription: entity.description,
      profileUrl: entity.userAvatar,
      commentList: entity.comments
          .map(
            (comment) => ReelCommentModel(
              comment: comment.comment,
              userProfilePic: comment.userProfilePic,
              userName: comment.userName,
              commentTime: comment.commentTime,
            ),
          )
          .toList(),
    );
  }

  static List<ReelModel> entitiesToReelModels(List<ReelEntity> entities) {
    return entities.map((entity) => entityToReelModel(entity)).toList();
  }
}
