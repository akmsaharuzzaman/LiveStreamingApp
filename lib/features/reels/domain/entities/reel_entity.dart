class ReelEntity {
  final String id;
  final String status;
  final int videoLength;
  final int videoMaximumLength;
  final String videoUrl;
  final int reactions;
  final int comments;
  final String createdAt;
  final ReelUserEntity userInfo;
  final List<ReelReactionEntity> latestReactions;
  final ReelReactionEntity? myReaction;

  ReelEntity({
    required this.id,
    required this.status,
    required this.videoLength,
    required this.videoMaximumLength,
    required this.videoUrl,
    required this.reactions,
    required this.comments,
    required this.createdAt,
    required this.userInfo,
    required this.latestReactions,
    this.myReaction,
  });

  // Helper methods
  bool get hasUserReacted => myReaction != null;
  String? get userReactionType => myReaction?.reactionType;

  // For backwards compatibility with UI
  String get userName => userInfo.name;
  String get userAvatar => userInfo.avatar?.url ?? '';
  int get likeCount => reactions;
  int get commentCount => comments;
  bool get isLiked => hasUserReacted;
  String get description => ''; // Not available in new API
  String get musicName => ''; // Not available in new API
}

class ReelUserEntity {
  final String id;
  final String name;
  final ReelUserAvatarEntity? avatar;

  ReelUserEntity({required this.id, required this.name, this.avatar});
}

class ReelUserAvatarEntity {
  final String name;
  final String url;

  ReelUserAvatarEntity({required this.name, required this.url});
}

class ReelReactionEntity {
  final String id;
  final String reactedBy;
  final String reactedTo;
  final String reactionType;
  final String createdAt;
  final ReelUserEntity? userInfo;

  ReelReactionEntity({
    required this.id,
    required this.reactedBy,
    required this.reactedTo,
    required this.reactionType,
    required this.createdAt,
    this.userInfo,
  });
}

class ReelCommentEntity {
  final String id;
  final String commentedBy;
  final String commentedTo;
  final String? parentComment;
  final String article;
  final int reactionsCount;
  final String createdAt;
  final String updatedAt;
  final ReelUserEntity commentedByInfo;
  final List<ReelCommentEntity> replies;

  ReelCommentEntity({
    required this.id,
    required this.commentedBy,
    required this.commentedTo,
    this.parentComment,
    required this.article,
    required this.reactionsCount,
    required this.createdAt,
    required this.updatedAt,
    required this.commentedByInfo,
    required this.replies,
  });

  // For backwards compatibility with UI
  String get comment => article;
  String get userName => commentedByInfo.name;
  String get userProfilePic => commentedByInfo.avatar?.url ?? '';
  DateTime get commentTime => DateTime.tryParse(createdAt) ?? DateTime.now();
}
