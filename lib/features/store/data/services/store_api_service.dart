import 'package:injectable/injectable.dart';
import '../../../../core/network/api_service.dart';
import '../models/store_models.dart';

@injectable
class StoreApiService {
  final ApiService _apiService;

  StoreApiService(this._apiService);

  /// Get all store categories
  Future<ApiResult<StoreCategoriesResponse>> getCategories() async {
    try {
      final result = await _apiService.get<StoreCategoriesResponse>(
        '/api/store/categories',
        fromJson: (json) => StoreCategoriesResponse.fromJson(json),
      );

      return result;
    } catch (e) {
      return ApiResult.failure(
        NetworkExceptions.defaultError('Failed to fetch categories: $e'),
      );
    }
  }

  /// Get items for a specific category
  Future<ApiResult<StoreItemsResponse>> getCategoryItems(String categoryId) async {
    try {
      final result = await _apiService.get<StoreItemsResponse>(
        '/api/store/items/category/$categoryId',
        fromJson: (json) => StoreItemsResponse.fromJson(json),
      );

      return result;
    } catch (e) {
      return ApiResult.failure(
        NetworkExceptions.defaultError('Failed to fetch category items: $e'),
      );
    }
  }

  /// Purchase an item (if needed in the future)
  Future<ApiResult<Map<String, dynamic>>> purchaseItem({
    required String itemId,
    required int price,
  }) async {
    try {
      final result = await _apiService.post<Map<String, dynamic>>(
        '/api/store/purchase',
        data: {
          'itemId': itemId,
          'price': price,
        },
      );

      return result;
    } catch (e) {
      return ApiResult.failure(
        NetworkExceptions.defaultError('Failed to purchase item: $e'),
      );
    }
  }
}
