import 'package:flutter_test/flutter_test.dart';
import 'package:dlstarlive/features/store/data/models/store_models.dart';
import 'dart:convert';

void main() {
  group('Store Models Tests', () {
    test('StoreCategory model should parse correctly', () {
      final json = {
        "_id": "507f1f77bcf86cd799439011",
        "title": "Fashion",
        "isPremium": false,
        "createdAt": "2023-01-01T00:00:00.000Z",
        "updatedAt": "2023-01-01T00:00:00.000Z",
        "__v": 0,
      };

      final category = StoreCategory.fromJson(json);

      expect(category.id, "507f1f77bcf86cd799439011");
      expect(category.title, "Fashion");
      expect(category.isPremium, false);
    });

    test('StoreItem model should parse correctly with bundle files', () {
      final json = {
        "_id": "507f1f77bcf86cd799439012",
        "name": "Cool Sunglasses",
        "validity": 30,
        "categoryId": "507f1f77bcf86cd799439011",
        "isPremium": false,
        "price": 299,
        "bundleFiles": [
          {
            "categoryName": "sunglasses",
            "svgaFile": "sunglasses_model.svga",
            "_id": "507f1f77bcf86cd799439013",
          },
        ],
        "deleteStatus": false,
        "totalSold": 0,
        "expireAt": "2024-01-01T00:00:00.000Z",
        "createdAt": "2023-01-01T00:00:00.000Z",
        "updatedAt": "2023-01-01T00:00:00.000Z",
        "__v": 0,
      };

      final item = StoreItem.fromJson(json);

      expect(item.id, "507f1f77bcf86cd799439012");
      expect(item.name, "Cool Sunglasses");
      expect(item.price, 299);
      expect(item.validity, 30);
      expect(item.bundleFiles.length, 1);
      expect(item.bundleFiles.first.id, "507f1f77bcf86cd799439013");
      expect(item.bundleFiles.first.categoryName, "sunglasses");
      expect(item.bundleFiles.first.svgaFile, "sunglasses_model.svga");
    });

    test('StoreItemsResponse should parse correctly with nested structure', () {
      const jsonString = '''
      {
        "success": true,
        "result": {
          "pagination": {
            "total": 1,
            "limit": 10,
            "page": 1,
            "totalPage": 1
          },
          "items": [
            {
              "_id": "507f1f77bcf86cd799439014",
              "name": "Cool Item",
              "validity": 30,
              "categoryId": "507f1f77bcf86cd799439011",
              "isPremium": false,
              "price": 100,
              "bundleFiles": [],
              "deleteStatus": false,
              "totalSold": 5,
              "expireAt": "2024-01-01T00:00:00.000Z",
              "createdAt": "2023-01-01T00:00:00.000Z",
              "updatedAt": "2023-01-01T00:00:00.000Z",
              "__v": 0
            }
          ]
        }
      }
      ''';

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final response = StoreItemsResponse.fromJson(jsonMap);

      expect(response.success, true);
      expect(response.result.pagination.page, 1);
      expect(response.result.pagination.limit, 10);
      expect(response.result.pagination.total, 1);
      expect(response.result.items.length, 1);
      expect(response.result.items.first.id, "507f1f77bcf86cd799439014");
      expect(response.result.items.first.name, "Cool Item");
    });
  });
}
