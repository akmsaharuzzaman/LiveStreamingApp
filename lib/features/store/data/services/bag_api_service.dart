import 'package:injectable/injectable.dart';
import '../../../../core/network/api_service.dart';
import '../models/bag_models.dart';
import '../models/store_models.dart';

@injectable
class BagApiService {
  final ApiService _apiService;

  BagApiService(this._apiService);

  /// Get categories for bag page (reusing store categories)
  Future<ApiResult<StoreCategoriesResponse>> getCategories() async {
    return await _apiService.get<StoreCategoriesResponse>(
      '/api/store/categories',
      fromJson: (json) => StoreCategoriesResponse.fromJson(json),
    );
  }

  /// Get bag items by category
  Future<ApiResult<BagItemsResponse>> getBagItemsByCategory(String categoryId) async {
    return await _apiService.get<BagItemsResponse>(
      '/api/store/bucket/category/$categoryId',
      fromJson: (json) => BagItemsResponse.fromJson(json),
    );
  }

  /// Purchase an item
  Future<ApiResult<Map<String, dynamic>>> purchaseItem(String itemId) async {
    final request = PurchaseItemRequest(itemId: itemId);
    return await _apiService.post<Map<String, dynamic>>(
      '/api/store/bucket',
      data: request.toJson(),
      fromJson: (json) => json,
    );
  }

  /// Use/Select an item
  Future<ApiResult<Map<String, dynamic>>> useItem(String bucketId) async {
    final request = UseItemRequest(bucketId: bucketId);
    return await _apiService.put<Map<String, dynamic>>(
      '/api/store/bucket',
      data: request.toJson(),
      fromJson: (json) => json,
    );
  }
}
