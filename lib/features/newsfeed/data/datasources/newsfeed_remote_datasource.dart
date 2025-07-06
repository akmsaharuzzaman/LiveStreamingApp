import 'package:dlstarlive/core/network/api_service.dart';
import 'package:dlstarlive/core/network/api_constants.dart';
import 'package:dlstarlive/core/network/api_result.dart';
import 'package:dlstarlive/core/network/network_exceptions.dart';
import '../models/post_response_model.dart';

abstract class NewsfeedRemoteDataSource {
  Future<ApiResult<PostResponse>> getAllPosts({int page = 1, int limit = 10});
}

class NewsfeedRemoteDataSourceImpl implements NewsfeedRemoteDataSource {
  final ApiService _apiService;

  NewsfeedRemoteDataSourceImpl(this._apiService);

  @override
  Future<ApiResult<PostResponse>> getAllPosts({int page = 1, int limit = 10}) async {
    try {
      final result = await _apiService.get<PostResponse>(
        ApiConstants.getAllPosts(page, limit),
        fromJson: (json) => PostResponse.fromJson(json),
      );

      return result;
    } catch (e) {
      return ApiResult.failure(
        NetworkExceptions.defaultError('Failed to fetch posts: $e'),
      );
    }
  }
}
