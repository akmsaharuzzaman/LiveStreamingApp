class StoriesApiResponse {
  final bool success;
  final StoriesResult result;

  StoriesApiResponse({required this.success, required this.result});

  factory StoriesApiResponse.fromJson(Map<String, dynamic> json) {
    return StoriesApiResponse(
      success: json['success'] ?? false,
      result: StoriesResult.fromJson(json['result'] ?? {}),
    );
  }
}

class StoriesResult {
  final PaginationInfo pagination;
  final List<UserStoryGroup> data;

  StoriesResult({required this.pagination, required this.data});

  factory StoriesResult.fromJson(Map<String, dynamic> json) {
    return StoriesResult(
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => UserStoryGroup.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class PaginationInfo {
  final int total;
  final int limit;
  final int page;
  final int totalPage;

  PaginationInfo({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 0,
      page: json['page'] ?? 0,
      totalPage: json['totalPage'] ?? 0,
    );
  }
}

class UserStoryGroup {
  final String id;
  final String name;
  final String? avatar;
  final List<StoryItem> stories;

  UserStoryGroup({
    required this.id,
    required this.name,
    this.avatar,
    required this.stories,
  });

  factory UserStoryGroup.fromJson(Map<String, dynamic> json) {
    return UserStoryGroup(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] != null ? json['avatar']['url'] : null,
      stories:
          (json['stories'] as List<dynamic>?)
              ?.map((item) => StoryItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  // Helper method to get the latest story (for displaying in the story circle)
  StoryItem? get latestStory {
    if (stories.isEmpty) return null;
    stories.sort(
      (a, b) =>
          DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)),
    );
    return stories.first;
  }

  // Helper method to check if all stories are viewed
  bool get allStoriesViewed {
    // For now, return false since we don't have viewed status in the API
    // You can implement this based on your local storage or API
    return false;
  }
}

class StoryItem {
  final String id;
  final String ownerId;
  final String mediaUrl;
  final int reactionCount;
  final String createdAt;
  final StoryUserInfo userInfo;
  final StoryItemReaction? myReaction;

  StoryItem({
    required this.id,
    required this.ownerId,
    required this.mediaUrl,
    required this.reactionCount,
    required this.createdAt,
    required this.userInfo,
    this.myReaction,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['_id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      reactionCount: json['reactionCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      userInfo: StoryUserInfo.fromJson(json['userInfo'] ?? {}),
      myReaction: json['myReaction'] != null
          ? StoryItemReaction.fromJson(json['myReaction'])
          : null,
    );
  }
}

class StoryUserInfo {
  final String id;
  final String name;
  final StoryUserAvatar? avatar;

  StoryUserInfo({required this.id, required this.name, this.avatar});

  factory StoryUserInfo.fromJson(Map<String, dynamic> json) {
    return StoryUserInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] != null
          ? StoryUserAvatar.fromJson(json['avatar'])
          : null,
    );
  }
}

class StoryUserAvatar {
  final String name;
  final String url;

  StoryUserAvatar({required this.name, required this.url});

  factory StoryUserAvatar.fromJson(Map<String, dynamic> json) {
    return StoryUserAvatar(name: json['name'] ?? '', url: json['url'] ?? '');
  }
}

class StoryItemReaction {
  final String reactionType;

  StoryItemReaction({required this.reactionType});

  factory StoryItemReaction.fromJson(Map<String, dynamic> json) {
    return StoryItemReaction(reactionType: json['reaction_type'] ?? 'like');
  }
}
