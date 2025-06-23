class CommentResponse {
  final bool success;
  final CommentResult result;

  CommentResponse({required this.success, required this.result});

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    return CommentResponse(
      success: json['success'] ?? false,
      result: CommentResult.fromJson(json['result'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'result': result.toJson()};
  }
}

class CommentResult {
  final CommentPagination? pagination;
  final List<CommentModel> data;

  CommentResult({this.pagination, required this.data});

  factory CommentResult.fromJson(Map<String, dynamic> json) {
    return CommentResult(
      pagination: json['pagination'] != null
          ? CommentPagination.fromJson(json['pagination'])
          : null,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => CommentModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pagination': pagination?.toJson(),
      'data': data.map((comment) => comment.toJson()).toList(),
    };
  }
}

class CommentPagination {
  final int total;
  final int limit;
  final int page;
  final int totalPage;

  CommentPagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory CommentPagination.fromJson(Map<String, dynamic> json) {
    return CommentPagination(
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 10,
      page: json['page'] ?? 1,
      totalPage: json['totalPage'] ?? 1,
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

class CommentModel {
  final String id;
  final String article; // This is the comment text according to API
  final String commentedBy;
  final String commentedTo; // This is the post ID
  final String? parentComment;
  final int reactionsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CommentUserInfo? userInfo;
  final CommentReaction? myReaction;
  final List<CommentReaction> latestReactions;
  final List<CommentModel> replies;

  CommentModel({
    required this.id,
    required this.article,
    required this.commentedBy,
    required this.commentedTo,
    this.parentComment,
    required this.reactionsCount,
    this.createdAt,
    this.updatedAt,
    this.userInfo,
    this.myReaction,
    required this.latestReactions,
    required this.replies,
  });

  // Getter for backward compatibility
  String get commentText => article;
  String get postId => commentedTo;
  int get reactionCount => reactionsCount;
  int get replyCount => replies.length;

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['_id'] ?? '',
      article: json['article'] ?? '',
      commentedBy: json['commentedBy'] ?? '',
      commentedTo: json['commentedTo'] ?? '',
      parentComment: json['parentComment'],
      reactionsCount: json['reactionsCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      userInfo: json['userInfo'] != null
          ? CommentUserInfo.fromJson(json['userInfo'])
          : null,
      myReaction: json['myReaction'] != null
          ? CommentReaction.fromJson(json['myReaction'])
          : null,
      latestReactions:
          (json['latestReactions'] as List<dynamic>?)
              ?.map((item) => CommentReaction.fromJson(item))
              .toList() ??
          [],
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map((item) => CommentModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'article': article,
      'commentedBy': commentedBy,
      'commentedTo': commentedTo,
      'parentComment': parentComment,
      'reactionsCount': reactionsCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'userInfo': userInfo?.toJson(),
      'myReaction': myReaction?.toJson(),
      'latestReactions': latestReactions
          .map((reaction) => reaction.toJson())
          .toList(),
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }
}

class CommentUserInfo {
  final String id;
  final String name;
  final CommentUserAvatar? avatar;

  CommentUserInfo({required this.id, required this.name, this.avatar});

  factory CommentUserInfo.fromJson(Map<String, dynamic> json) {
    return CommentUserInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown User',
      avatar: json['avatar'] != null
          ? CommentUserAvatar.fromJson(json['avatar'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'avatar': avatar?.toJson()};
  }
}

class CommentUserAvatar {
  final String name;
  final String url;

  CommentUserAvatar({required this.name, required this.url});

  factory CommentUserAvatar.fromJson(Map<String, dynamic> json) {
    return CommentUserAvatar(name: json['name'] ?? '', url: json['url'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'url': url};
  }
}

class CommentReaction {
  final String? id;
  final String? reactedBy;
  final String? reactedTo;
  final String reactionType;
  final DateTime? createdAt;
  final CommentUserInfo? userInfo;

  CommentReaction({
    this.id,
    this.reactedBy,
    this.reactedTo,
    required this.reactionType,
    this.createdAt,
    this.userInfo,
  });

  factory CommentReaction.fromJson(Map<String, dynamic> json) {
    return CommentReaction(
      id: json['_id'],
      reactedBy: json['reactedBy'],
      reactedTo: json['reactedTo'],
      reactionType: json['reaction_type'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      userInfo: json['userInfo'] != null
          ? CommentUserInfo.fromJson(json['userInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'reactedBy': reactedBy,
      'reactedTo': reactedTo,
      'reaction_type': reactionType,
      'createdAt': createdAt?.toIso8601String(),
      'userInfo': userInfo?.toJson(),
    };
  }
}
