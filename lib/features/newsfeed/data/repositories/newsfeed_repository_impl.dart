import 'package:dlstarlive/core/network/api_result.dart';
import 'package:dlstarlive/core/network/network_exceptions.dart';
import '../models/post_response_model.dart';
import '../datasources/newsfeed_remote_datasource.dart';
import '../../domain/repositories/newsfeed_repository.dart';

class NewsfeedRepositoryImpl implements NewsfeedRepository {
  final NewsfeedRemoteDataSource _remoteDataSource;

  NewsfeedRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<PostResponse>> getAllPosts({int page = 1, int limit = 10}) async {
    try {
      return await _remoteDataSource.getAllPosts(page: page, limit: limit);
    } catch (e) {
      return ApiResult.failure(
        NetworkExceptions.defaultError('Repository error: $e'),
      );
    }
  }
}
