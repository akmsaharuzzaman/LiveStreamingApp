class ReelApiModel {
  final String id;
  final String status;
  final int videoLength;
  final int videoMaximumLength;
  final String reelUrl;
  final int reactions;
  final int comments;
  final DateTime createdAt;
  final UserInfo userInfo;
  final List<ReactionInfo> latestReactions;

  ReelApiModel({
    required this.id,
    required this.status,
    required this.videoLength,
    required this.videoMaximumLength,
    required this.reelUrl,
    required this.reactions,
    required this.comments,
    required this.createdAt,
    required this.userInfo,
    required this.latestReactions,
  });

  factory ReelApiModel.fromJson(Map<String, dynamic> json) {
    return ReelApiModel(
      id: json['_id'] ?? '',
      status: json['status'] ?? 'active',
      videoLength: json['video_length'] ?? 0,
      videoMaximumLength: json['video_maximum_length'] ?? 60,
      reelUrl: json['reelUrl'] ?? '',
      reactions: json['reactions'] ?? 0,
      comments: json['comments'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      userInfo: UserInfo.fromJson(json['userInfo'] ?? {}),
      latestReactions:
          (json['latestReactions'] as List<dynamic>?)
              ?.map((e) => ReactionInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'status': status,
      'video_length': videoLength,
      'video_maximum_length': videoMaximumLength,
      'reelUrl': reelUrl,
      'reactions': reactions,
      'comments': comments,
      'createdAt': createdAt.toIso8601String(),
      'userInfo': userInfo.toJson(),
      'latestReactions': latestReactions.map((e) => e.toJson()).toList(),
    };
  }
}

class UserInfo {
  final String id;
  final String name;
  final Avatar? avatar;

  UserInfo({required this.id, required this.name, this.avatar});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown User',
      avatar: json['avatar'] != null
          ? Avatar.fromJson(json['avatar'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'avatar': avatar?.toJson()};
  }
}

class Avatar {
  final String name;
  final String url;

  Avatar({required this.name, required this.url});

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      name: json['name'] ?? 'default.jpg',
      url: json['url'] ?? 'https://thispersondoesnotexist.com/',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'url': url};
  }
}

class ReactionInfo {
  final String id;
  final String reactedBy;
  final String reactedTo;
  final String reactionType;
  final DateTime createdAt;
  final UserInfo? userInfo;

  ReactionInfo({
    required this.id,
    required this.reactedBy,
    required this.reactedTo,
    required this.reactionType,
    required this.createdAt,
    this.userInfo,
  });

  factory ReactionInfo.fromJson(Map<String, dynamic> json) {
    return ReactionInfo(
      id: json['_id'] ?? '',
      reactedBy: json['reactedBy'] ?? '',
      reactedTo: json['reactedTo'] ?? '',
      reactionType: json['reaction_type'] ?? 'like',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      userInfo: json['userInfo'] != null
          ? UserInfo.fromJson(json['userInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'reactedBy': reactedBy,
      'reactedTo': reactedTo,
      'reaction_type': reactionType,
      'createdAt': createdAt.toIso8601String(),
      'userInfo': userInfo?.toJson(),
    };
  }
}

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
}

class ReelsResult {
  final Pagination pagination;
  final List<ReelApiModel> data;

  ReelsResult({required this.pagination, required this.data});

  factory ReelsResult.fromJson(Map<String, dynamic> json) {
    return ReelsResult(
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => ReelApiModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Pagination {
  final int total;
  final int limit;
  final int page;
  final int totalPage;

  Pagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 5,
      page: json['page'] ?? 1,
      totalPage: json['totalPage'] ?? 1,
    );
  }
}
