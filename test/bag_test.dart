import 'package:flutter_test/flutter_test.dart';
import 'package:dlstarlive/features/store/data/models/bag_models.dart';
import 'dart:convert';

void main() {
  group('Bag Models Tests', () {
    test('BagItem model should parse correctly', () {
      const jsonString = '''
      {
        "_id": "68c029bd53e13ed58144bc7b",
        "itemId": {
          "_id": "68c0240e960d7f0f2696c356",
          "name": "fighter jet",
          "validity": 10,
          "categoryId": "68c00eb05a8f735317e5a002",
          "isPremium": false,
          "price": 150,
          "svgaFile": "https://res.cloudinary.com/test.svga",
          "deleteStatus": false,
          "totalSold": 0,
          "bundleFiles": [],
          "expireAt": "2099-12-31T18:00:00.000Z",
          "createdAt": "2025-09-09T12:56:46.210Z",
          "updatedAt": "2025-09-09T12:56:46.210Z",
          "__v": 0
        },
        "ownerId": "686e46eb9edb3a9f2d80e1fd",
        "categoryId": {
          "_id": "68c00eb05a8f735317e5a002",
          "title": "entry",
          "createdAt": "2025-09-09T11:25:36.208Z",
          "updatedAt": "2025-09-09T11:25:36.208Z",
          "__v": 0
        },
        "useStatus": false,
        "expireAt": "2025-09-19T13:21:01.916Z",
        "createdAt": "2025-09-09T13:21:01.920Z",
        "updatedAt": "2025-09-09T13:21:01.920Z",
        "__v": 0
      }
      ''';

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final bagItem = BagItem.fromJson(jsonMap);

      expect(bagItem.id, "68c029bd53e13ed58144bc7b");
      expect(bagItem.itemId.name, "fighter jet");
      expect(bagItem.itemId.price, 150);
      expect(bagItem.categoryId.title, "entry");
      expect(bagItem.useStatus, false);
      expect(bagItem.ownerId, "686e46eb9edb3a9f2d80e1fd");
    });

    test('BagItemsResponse should parse correctly', () {
      const jsonString = '''
      {
        "success": true,
        "result": {
          "pagination": {
            "total": 2,
            "limit": 9999,
            "page": 1,
            "totalPage": 1
          },
          "buckets": [
            {
              "_id": "68c029bd53e13ed58144bc7b",
              "itemId": {
                "_id": "68c0240e960d7f0f2696c356",
                "name": "fighter jet",
                "validity": 10,
                "categoryId": "68c00eb05a8f735317e5a002",
                "isPremium": false,
                "price": 150,
                "svgaFile": "https://res.cloudinary.com/test.svga",
                "deleteStatus": false,
                "totalSold": 0,
                "bundleFiles": [],
                "expireAt": "2099-12-31T18:00:00.000Z",
                "createdAt": "2025-09-09T12:56:46.210Z",
                "updatedAt": "2025-09-09T12:56:46.210Z",
                "__v": 0
              },
              "ownerId": "686e46eb9edb3a9f2d80e1fd",
              "categoryId": {
                "_id": "68c00eb05a8f735317e5a002",
                "title": "entry",
                "createdAt": "2025-09-09T11:25:36.208Z",
                "updatedAt": "2025-09-09T11:25:36.208Z",
                "__v": 0
              },
              "useStatus": true,
              "expireAt": "2025-09-19T13:21:01.916Z",
              "createdAt": "2025-09-09T13:21:01.920Z",
              "updatedAt": "2025-09-09T13:21:01.920Z",
              "__v": 0
            }
          ]
        }
      }
      ''';

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final response = BagItemsResponse.fromJson(jsonMap);

      expect(response.success, true);
      expect(response.result.pagination.total, 2);
      expect(response.result.pagination.page, 1);
      expect(response.result.buckets.length, 1);
      expect(response.result.buckets.first.useStatus, true);
      expect(response.result.buckets.first.itemId.name, "fighter jet");
    });

    test('PurchaseItemRequest should serialize correctly', () {
      const request = PurchaseItemRequest(itemId: "68c186b08983765299e75e80");
      final json = request.toJson();

      expect(json['itemId'], "68c186b08983765299e75e80");
    });

    test('UseItemRequest should serialize correctly', () {
      const request = UseItemRequest(bucketId: "68c18823b6ebe2a8d75919f6");
      final json = request.toJson();

      expect(json['bucketId'], "68c18823b6ebe2a8d75919f6");
    });
  });
}
