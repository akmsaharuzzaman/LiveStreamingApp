import 'package:injectable/injectable.dart';
import '../../../../core/network/api_service.dart';
import '../models/friends_models.dart';

@injectable
class FriendsApiService {
  final ApiService _apiService;

  FriendsApiService(this._apiService);

  /// Get follower and following count for a user
  Future<ApiResult<FollowerCountResult>> getFollowerAndFollowingCount(
    String? userId,
  ) async {
    final String url = userId == null
        ? '/api/followers/follower-and-following-count'
        : '/api/followers/follower-and-following-count/$userId';
    try {
      final response = await _apiService.get(
        url,
      );

      return response.fold((data) {
        try {
          final countResponse = FollowerCountResponse.fromJson(data);
          if (countResponse.success) {
            return ApiResult.success(countResponse.result);
          } else {
            return const ApiResult.failure('Failed to get follower count');
          }
        } catch (e) {
          return ApiResult.failure('Error parsing follower count: $e');
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure('Error getting follower count: $e');
    }
  }

  /// Get friend list for a user
  Future<ApiResult<List<FriendItem>>> getFriendList(String userId) async {
    try {
      final response = await _apiService.get(
        '/api/followers/friend-list/$userId',
      );

      return response.fold((data) {
        try {
          final friendListResponse = FriendListResponse.fromJson(data);
          if (friendListResponse.success) {
            return ApiResult.success(friendListResponse.result.data);
          } else {
            return const ApiResult.failure('Failed to get friend list');
          }
        } catch (e) {
          return ApiResult.failure('Error parsing friend list: $e');
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure('Error getting friend list: $e');
    }
  }

  /// Get following list for a user
  Future<ApiResult<List<FollowItem>>> getFollowingList(String userId) async {
    try {
      final response = await _apiService.get(
        '/api/followers/following-list/$userId',
      );

      return response.fold((data) {
        try {
          final followListResponse = FollowListResponse.fromJson(data);
          if (followListResponse.success) {
            return ApiResult.success(followListResponse.result.data);
          } else {
            return const ApiResult.failure('Failed to get following list');
          }
        } catch (e) {
          return ApiResult.failure('Error parsing following list: $e');
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure('Error getting following list: $e');
    }
  }

  /// Get follower list for a user
  Future<ApiResult<List<FollowItem>>> getFollowerList(String userId) async {
    try {
      final response = await _apiService.get(
        '/api/followers/follower-list/$userId',
      );

      return response.fold((data) {
        try {
          final followListResponse = FollowListResponse.fromJson(data);
          if (followListResponse.success) {
            return ApiResult.success(followListResponse.result.data);
          } else {
            return const ApiResult.failure('Failed to get follower list');
          }
        } catch (e) {
          return ApiResult.failure('Error parsing follower list: $e');
        }
      }, (error) => ApiResult.failure(error));
    } catch (e) {
      return ApiResult.failure('Error getting follower list: $e');
    }
  }
}
