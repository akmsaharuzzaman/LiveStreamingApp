import '../../../../core/network_temp/api_result.dart';
import '../../data/models/post_response_model.dart';
import '../repositories/newsfeed_repository.dart';

class GetAllPostsUseCase {
  final NewsfeedRepository _repository;

  GetAllPostsUseCase(this._repository);

  Future<ApiResult<PostResponse>> call({int page = 1, int limit = 10}) async {
    return await _repository.getAllPosts(page: page, limit: limit);
  }
}
