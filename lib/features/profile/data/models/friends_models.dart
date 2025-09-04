import 'package:equatable/equatable.dart';

// Count Response Model
class FollowerCountResponse extends Equatable {
  final bool success;
  final FollowerCountResult result;

  const FollowerCountResponse({required this.success, required this.result});

  factory FollowerCountResponse.fromJson(Map<String, dynamic> json) {
    return FollowerCountResponse(
      success: json['success'] ?? false,
      result: FollowerCountResult.fromJson(json['result'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [success, result];
}

class FollowerCountResult extends Equatable {
  final int followerCount;
  final int followingCount;
  final int friendshipCount;

  const FollowerCountResult({
    required this.followerCount,
    required this.followingCount,
    required this.friendshipCount,
  });

  factory FollowerCountResult.fromJson(Map<String, dynamic> json) {
    return FollowerCountResult(
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      friendshipCount: json['friendshipCount'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [followerCount, followingCount, friendshipCount];
}

// Friend List Response Model
class FriendListResponse extends Equatable {
  final bool success;
  final FriendListResult result;

  const FriendListResponse({required this.success, required this.result});

  factory FriendListResponse.fromJson(Map<String, dynamic> json) {
    return FriendListResponse(
      success: json['success'] ?? false,
      result: FriendListResult.fromJson(json['result'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [success, result];
}

class FriendListResult extends Equatable {
  final Pagination pagination;
  final List<FriendItem> data;

  const FriendListResult({required this.pagination, required this.data});

  factory FriendListResult.fromJson(Map<String, dynamic> json) {
    return FriendListResult(
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => FriendItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [pagination, data];
}

class FriendItem extends Equatable {
  final String id;
  final String user1;
  final String user2;
  final String createdAt;
  final String updatedAt;
  final UserInfo friendInfo;
  final UserInfo myInfo;

  const FriendItem({
    required this.id,
    required this.user1,
    required this.user2,
    required this.createdAt,
    required this.updatedAt,
    required this.friendInfo,
    required this.myInfo,
  });

  factory FriendItem.fromJson(Map<String, dynamic> json) {
    return FriendItem(
      id: json['_id'] ?? '',
      user1: json['user1'] ?? '',
      user2: json['user2'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      friendInfo: UserInfo.fromJson(json['friendInfo'] ?? {}),
      myInfo: UserInfo.fromJson(json['myInfo'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    id,
    user1,
    user2,
    createdAt,
    updatedAt,
    friendInfo,
    myInfo,
  ];
}

// Following/Follower List Response Model
class FollowListResponse extends Equatable {
  final bool success;
  final FollowListResult result;

  const FollowListResponse({required this.success, required this.result});

  factory FollowListResponse.fromJson(Map<String, dynamic> json) {
    return FollowListResponse(
      success: json['success'] ?? false,
      result: FollowListResult.fromJson(json['result'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [success, result];
}

class FollowListResult extends Equatable {
  final Pagination pagination;
  final List<FollowItem> data;

  const FollowListResult({required this.pagination, required this.data});

  factory FollowListResult.fromJson(Map<String, dynamic> json) {
    return FollowListResult(
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => FollowItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [pagination, data];
}

class FollowItem extends Equatable {
  final String id;
  final UserInfo myId;
  final UserInfo followerId;
  final String createdAt;
  final String updatedAt;

  const FollowItem({
    required this.id,
    required this.myId,
    required this.followerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FollowItem.fromJson(Map<String, dynamic> json) {
    return FollowItem(
      id: json['_id'] ?? '',
      myId: UserInfo.fromJson(json['myId'] ?? {}),
      followerId: UserInfo.fromJson(json['followerId'] ?? {}),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, myId, followerId, createdAt, updatedAt];
}

// Common Models
class UserInfo extends Equatable {
  final String id;
  final String name;
  final String? avatar;

  const UserInfo({required this.id, required this.name, this.avatar});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
    );
  }

  @override
  List<Object?> get props => [id, name, avatar];
}

class Pagination extends Equatable {
  final int total;
  final int limit;
  final int page;
  final int totalPage;

  const Pagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 0,
      page: json['page'] ?? 0,
      totalPage: json['totalPage'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [total, limit, page, totalPage];
}
