import 'package:dlstarlive/core/network/api_service.dart';
import '../../data/models/post_response_model.dart';

abstract class NewsfeedRepository {
  Future<ApiResult<PostResponse>> getAllPosts({int page = 1, int limit = 10});
}
