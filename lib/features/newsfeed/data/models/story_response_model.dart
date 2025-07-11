
class StoryResponse {
  final bool success;
  final StoryResult result;

  StoryResponse({required this.success, required this.result});

  factory StoryResponse.fromJson(Map<String, dynamic> json) {
    return StoryResponse(
      success: json['success'] ?? false,
      result: StoryResult.fromJson(json['result'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'result': result.toJson()};
  }
}

class StoryResult {
  final StoryPagination? pagination;
  final List<StoryUserGroup> data;

  StoryResult({this.pagination, this.data = const []});

  factory StoryResult.fromJson(Map<String, dynamic> json) {
    return StoryResult(
      pagination: json['pagination'] != null
          ? StoryPagination.fromJson(json['pagination'])
          : null,
      data: json['data'] != null
          ? (json['data'] as List)
                .map((item) => StoryUserGroup.fromJson(item))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pagination': pagination?.toJson(),
      'data': data.map((item) => item.toJson()).toList(),
    };
  }

  // Helper methods to work with the grouped structure
  List<StoryModel> get allStories {
    return data.expand((userGroup) => userGroup.stories).toList();
  }

  List<StoryUserGroup> get usersWithStories {
    return data.where((userGroup) => userGroup.hasStories).toList();
  }
}

class StoryPagination {
  final int total;
  final int limit;
  final int page;
  final int totalPage;

  StoryPagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory StoryPagination.fromJson(Map<String, dynamic> json) {
    return StoryPagination(
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

class StoryUserGroup {
  final String id;
  final String name;
  final String? avatar;
  final List<StoryModel> stories;

  StoryUserGroup({
    required this.id,
    required this.name,
    this.avatar,
    required this.stories,
  });

  factory StoryUserGroup.fromJson(Map<String, dynamic> json) {
    return StoryUserGroup(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      stories: json['stories'] != null
          ? (json['stories'] as List)
                .map((item) => StoryModel.fromJson(item))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'avatar': avatar,
      'stories': stories.map((story) => story.toJson()).toList(),
    };
  }

  // Helper methods
  bool get hasStories => stories.isNotEmpty;
  int get storyCount => stories.length;
  String get avatarUrl => avatar ?? '';
}

class StoryModel {
  final String id;
  final String ownerId;
  final String mediaUrl;
  final int reactionCount;
  final String createdAt;
  final StoryUserInfo? userInfo;
  final StoryReaction? myReaction;

  StoryModel({
    required this.id,
    required this.ownerId,
    required this.mediaUrl,
    this.reactionCount = 0,
    required this.createdAt,
    this.userInfo,
    this.myReaction,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['_id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      reactionCount: json['reactionCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      userInfo: json['userInfo'] != null
          ? StoryUserInfo.fromJson(json['userInfo'])
          : null,
      myReaction: json['myReaction'] != null
          ? StoryReaction.fromJson(json['myReaction'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ownerId': ownerId,
      'mediaUrl': mediaUrl,
      'reactionCount': reactionCount,
      'createdAt': createdAt,
      'userInfo': userInfo?.toJson(),
      'myReaction': myReaction?.toJson(),
    };
  }

  // Backward compatibility getters for existing UI
  String get storyId => id;
  String get imageUrl => mediaUrl;
  bool get isViewed => myReaction != null;

  // Create a copy with updated reaction
  StoryModel copyWith({
    String? id,
    String? ownerId,
    String? mediaUrl,
    int? reactionCount,
    String? createdAt,
    StoryUserInfo? userInfo,
    StoryReaction? myReaction,
  }) {
    return StoryModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      reactionCount: reactionCount ?? this.reactionCount,
      createdAt: createdAt ?? this.createdAt,
      userInfo: userInfo ?? this.userInfo,
      myReaction: myReaction ?? this.myReaction,
    );
  }
}

class StoryUserInfo {
  final String id;
  final String name;
  final String? avatar;

  StoryUserInfo({required this.id, required this.name, this.avatar});

  factory StoryUserInfo.fromJson(Map<String, dynamic> json) {
    return StoryUserInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar']?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'avatar': avatar};
  }
}


class StoryReaction {
  final String reactionType;

  StoryReaction({required this.reactionType});

  factory StoryReaction.fromJson(Map<String, dynamic> json) {
    return StoryReaction(reactionType: json['reaction_type'] ?? 'like');
  }

  Map<String, dynamic> toJson() {
    return {'reaction_type': reactionType};
  }
}

/// Single Story Response for reactions
class SingleStoryResponse {
  final bool success;
  final StoryModel result;

  SingleStoryResponse({required this.success, required this.result});

  factory SingleStoryResponse.fromJson(Map<String, dynamic> json) {
    return SingleStoryResponse(
      success: json['success'] ?? false,
      result: StoryModel.fromJson(json['result'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'result': result.toJson()};
  }
}
