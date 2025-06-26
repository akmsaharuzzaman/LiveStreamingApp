class ReelEntity {
  final String id;
  final String videoUrl;
  final String userName;
  final String userAvatar;
  final String description;
  final String musicName;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final bool isFollowing;
  final List<CommentEntity> comments;

  ReelEntity({
    required this.id,
    required this.videoUrl,
    required this.userName,
    required this.userAvatar,
    required this.description,
    required this.musicName,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.isLiked,
    required this.isFollowing,
    required this.comments,
  });
}

class CommentEntity {
  final String id;
  final String comment;
  final String userName;
  final String userProfilePic;
  final DateTime commentTime;

  CommentEntity({
    required this.id,
    required this.comment,
    required this.userName,
    required this.userProfilePic,
    required this.commentTime,
  });
}
