class PostResponse {
  final bool success;
  final PostResult result;

  PostResponse({
    required this.success,
    required this.result,
  });

  factory PostResponse.fromJson(Map<String, dynamic> json) {
    return PostResponse(
      success: json['success'] ?? false,
      result: PostResult.fromJson(json['result'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'result': result.toJson(),
    };
  }
}

class PostResult {
  final PostPagination? pagination;
  final List<PostModel> data;

  PostResult({
    this.pagination,
    required this.data,
  });

  factory PostResult.fromJson(Map<String, dynamic> json) {
    return PostResult(
      pagination: json['pagination'] != null 
          ? PostPagination.fromJson(json['pagination'])
          : null,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => PostModel.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pagination': pagination?.toJson(),
      'data': data.map((post) => post.toJson()).toList(),
    };
  }
}

class PostPagination {
  final int total;
  final int limit;
  final int page;
  final int totalPage;

  PostPagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory PostPagination.fromJson(Map<String, dynamic> json) {
    return PostPagination(
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

class PostModel {
  final String id;
  final String ownerId;
  final String? postCaption;
  final String? mediaUrl;
  final String status;
  final int reactionCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserInfo userInfo;
  final PostReaction? myReaction;
  final List<PostReaction> latestReactions;

  PostModel({
    required this.id,
    required this.ownerId,
    this.postCaption,
    this.mediaUrl,
    required this.status,
    required this.reactionCount,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
    required this.userInfo,
    this.myReaction,
    required this.latestReactions,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['_id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      postCaption: json['postCaption'],
      mediaUrl: json['mediaUrl'],
      status: json['status'] ?? 'active',
      reactionCount: json['reactionCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      userInfo: UserInfo.fromJson(json['userInfo'] ?? {}),
      myReaction: json['myReaction'] != null 
          ? PostReaction.fromJson(json['myReaction'])
          : null,
      latestReactions: (json['latestReactions'] as List<dynamic>?)
          ?.map((item) => PostReaction.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ownerId': ownerId,
      'postCaption': postCaption,
      'mediaUrl': mediaUrl,
      'status': status,
      'reactionCount': reactionCount,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userInfo': userInfo.toJson(),
      'myReaction': myReaction?.toJson(),
      'latestReactions': latestReactions.map((reaction) => reaction.toJson()).toList(),
    };
  }
}

class UserInfo {
  final String id;
  final String name;
  final UserAvatar? avatar;

  UserInfo({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] != null 
          ? UserAvatar.fromJson(json['avatar'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'avatar': avatar?.toJson(),
    };
  }
}

class UserAvatar {
  final String name;
  final String url;

  UserAvatar({
    required this.name,
    required this.url,
  });

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    return UserAvatar(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }
}

class PostReaction {
  final String? id;
  final String? reactedBy;
  final String? reactedTo;
  final String reactionType;
  final DateTime? createdAt;
  final UserInfo? userInfo;

  PostReaction({
    this.id,
    this.reactedBy,
    this.reactedTo,
    required this.reactionType,
    this.createdAt,
    this.userInfo,
  });

  factory PostReaction.fromJson(Map<String, dynamic> json) {
    return PostReaction(
      id: json['_id'],
      reactedBy: json['reactedBy'],
      reactedTo: json['reactedTo'],
      reactionType: json['reaction_type'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : null,
      userInfo: json['userInfo'] != null 
          ? UserInfo.fromJson(json['userInfo'])
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
