/// Reels API Response Models
/// This file contains data models for reels API responses matching the new backend structure

class ReelsApiResponse {
  final bool success;
  final ReelsResult result;

  ReelsApiResponse({required this.success, required this.result});

  factory ReelsApiResponse.fromJson(Map<String, dynamic> json) {
    return ReelsApiResponse(
      success: json['success'] ?? false,
      result: ReelsResult.fromJson(json['result'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'result': result.toJson()};
  }
}

class ReelsResult {
  final ReelsPagination pagination;
  final List<ReelApiModel> data;

  ReelsResult({required this.pagination, required this.data});

  factory ReelsResult.fromJson(Map<String, dynamic> json) {
    return ReelsResult(
      pagination: ReelsPagination.fromJson(json['pagination'] ?? {}),
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => ReelApiModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pagination': pagination.toJson(),
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class ReelsPagination {
  final int total;
  final int limit;
  final int page;
  final int totalPage;

  ReelsPagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory ReelsPagination.fromJson(Map<String, dynamic> json) {
    return ReelsPagination(
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 0,
      page: json['page'] ?? 0,
      totalPage: json['totalPage'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'limit': limit,
      'page': page,
      'totalPage': totalPage,
    };
  }
}

class ReelApiModel {
  final String id;
  final String? reelCaption;
  final String status;
  final int videoLength;
  final int videoMaximumLength;
  final String reelUrl;
  final int reactions;
  final int comments;
  final String createdAt;
  final ReelUserInfo userInfo;
  final List<ReelReaction> latestReactions;
  final ReelReaction? myReaction; // User's reaction if any

  ReelApiModel({
    required this.id,
    this.reelCaption,
    required this.status,
    required this.videoLength,
    required this.videoMaximumLength,
    required this.reelUrl,
    required this.reactions,
    required this.comments,
    required this.createdAt,
    required this.userInfo,
    required this.latestReactions,
    this.myReaction,
  });

  factory ReelApiModel.fromJson(Map<String, dynamic> json) {
    return ReelApiModel(
      id: json['_id'] ?? '',
      reelCaption: json['reelCaption'],
      status: json['status'] ?? '',
      videoLength: json['videoLength'] ?? 0,
      videoMaximumLength: json['videoMaximumLength'] ?? 0,
      reelUrl: json['reelUrl'] ?? '',
      reactions: json['reactions'] ?? 0,
      comments: json['comments'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      userInfo: ReelUserInfo.fromJson(json['userInfo'] ?? {}),
      latestReactions:
          (json['latestReactions'] as List<dynamic>?)
              ?.map((item) => ReelReaction.fromJson(item))
              .toList() ??
          [],
      myReaction: json['myReaction'] != null
          ? ReelReaction.fromJson(json['myReaction'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'reelCaption': reelCaption,
      'status': status,
      'videoLength': videoLength,
      'videoMaximumLength': videoMaximumLength,
      'reelUrl': reelUrl,
      'reactions': reactions,
      'comments': comments,
      'createdAt': createdAt,
      'userInfo': userInfo.toJson(),
      'latestReactions': latestReactions.map((item) => item.toJson()).toList(),
      'myReaction': myReaction?.toJson(),
    };
  }

  // Helper method to check if user has reacted
  bool get hasUserReacted => myReaction != null;

  // Helper method to get user's reaction type
  String? get userReactionType => myReaction?.reactionType;
}

class ReelUserInfo {
  final String id;
  final String name;
  final String? avatar; // Changed to direct string to match new API

  ReelUserInfo({required this.id, required this.name, this.avatar});

  factory ReelUserInfo.fromJson(Map<String, dynamic> json) {
    return ReelUserInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'], // Direct string from API
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'avatar': avatar};
  }
}

class ReelReaction {
  final String id;
  final String reactedBy;
  final String reactedTo;
  final String reactionType;
  final String createdAt;
  final ReelUserInfo? userInfo;

  ReelReaction({
    required this.id,
    required this.reactedBy,
    required this.reactedTo,
    required this.reactionType,
    required this.createdAt,
    this.userInfo,
  });

  factory ReelReaction.fromJson(Map<String, dynamic> json) {
    return ReelReaction(
      id: json['_id'] ?? '',
      reactedBy: json['reactedBy'] ?? '',
      reactedTo: json['reactedTo'] ?? '',
      reactionType: json['reaction_type'] ?? '',
      createdAt: json['createdAt'] ?? '',
      userInfo: json['userInfo'] != null
          ? ReelUserInfo.fromJson(json['userInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'reactedBy': reactedBy,
      'reactedTo': reactedTo,
      'reaction_type': reactionType,
      'createdAt': createdAt,
      'userInfo': userInfo?.toJson(),
    };
  }
}

/// Comments API Response Models
class ReelCommentsApiResponse {
  final bool success;
  final ReelCommentsResult result;

  ReelCommentsApiResponse({required this.success, required this.result});

  factory ReelCommentsApiResponse.fromJson(Map<String, dynamic> json) {
    return ReelCommentsApiResponse(
      success: json['success'] ?? false,
      result: ReelCommentsResult.fromJson(json['result'] ?? {}),
    );
  }
}

class ReelCommentsResult {
  final ReelsPagination pagination;
  final List<ReelComment> data;

  ReelCommentsResult({required this.pagination, required this.data});

  factory ReelCommentsResult.fromJson(Map<String, dynamic> json) {
    return ReelCommentsResult(
      pagination: ReelsPagination.fromJson(json['pagination'] ?? {}),
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => ReelComment.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class ReelComment {
  final String id;
  final String commentedBy;
  final String commentedTo;
  final String? parentComment;
  final String article;
  final int reactionsCount;
  final String createdAt;
  final String updatedAt;
  final ReelUserInfo commentedByInfo;
  final List<ReelComment> replies;

  ReelComment({
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

  factory ReelComment.fromJson(Map<String, dynamic> json) {
    return ReelComment(
      id: json['_id'] ?? '',
      commentedBy: json['commentedBy'] ?? '',
      commentedTo: json['commentedTo'] ?? '',
      parentComment: json['parentComment'],
      article: json['article'] ?? '',
      reactionsCount: json['reactionsCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      commentedByInfo: ReelUserInfo.fromJson(json['commentedByInfo'] ?? {}),
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map((item) => ReelComment.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'commentedBy': commentedBy,
      'commentedTo': commentedTo,
      'parentComment': parentComment,
      'article': article,
      'reactionsCount': reactionsCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'commentedByInfo': commentedByInfo.toJson(),
      'replies': replies.map((item) => item.toJson()).toList(),
    };
  }
}
