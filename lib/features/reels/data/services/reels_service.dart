import 'dart:developer';

import '../../../../core/auth/auth_bloc_adapter.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/app_constants.dart';

class ReelsService {
  final ApiService _apiService;
  final AuthBlocAdapter _authBlocAdapter;

  ReelsService(this._apiService, this._authBlocAdapter);

  /// Get user-specific reels
  Future<ApiResult<Map<String, dynamic>>> getUserReels({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      log('Fetching user reels: userId=$userId, page=$page, limit=$limit');

      final token = await _authBlocAdapter.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication token not found');
      }

      final result = await _apiService.get(
        ApiConstants.getUserReels(userId, page, limit),
      );

      return result.when(
        success: (data) {
          log('User reels fetched successfully');
          if (data is Map<String, dynamic>) {
            return ApiResult.success(data);
          } else if (data is String) {
            // Handle string response by parsing it
            try {
              final Map<String, dynamic> jsonData = Map<String, dynamic>.from(
                data as Map,
              );
              return ApiResult.success(jsonData);
            } catch (e) {
              log('Error parsing response: $e');
              return ApiResult.failure('Error parsing response');
            }
          } else {
            return ApiResult.failure('Unexpected response format');
          }
        },
        failure: (error) {
          log('Error fetching user reels: $error');
          return ApiResult.failure(error);
        },
      );
    } catch (e) {
      log('Exception in getUserReels: $e');
      return ApiResult.failure('Error: ${e.toString()}');
    }
  }

  /// Get all reels
  Future<ApiResult<Map<String, dynamic>>> getReels({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      log('Fetching reels: page=$page, limit=$limit');

      final token = await _authBlocAdapter.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication token not found');
      }

      final result = await _apiService.get(ApiConstants.getReels(page, limit));

      return result.when(
        success: (data) {
          log('Reels fetched successfully');
          if (data is Map<String, dynamic>) {
            return ApiResult.success(data);
          } else if (data is String) {
            try {
              final Map<String, dynamic> jsonData = Map<String, dynamic>.from(
                data as Map,
              );
              return ApiResult.success(jsonData);
            } catch (e) {
              log('Error parsing response: $e');
              return ApiResult.failure('Error parsing response');
            }
          } else {
            return ApiResult.failure('Unexpected response format');
          }
        },
        failure: (error) {
          log('Error fetching reels: $error');
          return ApiResult.failure(error);
        },
      );
    } catch (e) {
      log('Exception in getReels: $e');
      return ApiResult.failure('Error: ${e.toString()}');
    }
  }
}
