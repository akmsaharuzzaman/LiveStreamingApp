// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bag_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BagItem _$BagItemFromJson(Map<String, dynamic> json) => BagItem(
  id: json['_id'] as String,
  itemId: BagItemDetails.fromJson(json['itemId'] as Map<String, dynamic>),
  ownerId: json['ownerId'] as String,
  categoryId: BagCategoryDetails.fromJson(
    json['categoryId'] as Map<String, dynamic>,
  ),
  useStatus: json['useStatus'] as bool,
  expireAt: DateTime.parse(json['expireAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  version: (json['__v'] as num).toInt(),
);

Map<String, dynamic> _$BagItemToJson(BagItem instance) => <String, dynamic>{
  '_id': instance.id,
  'itemId': instance.itemId,
  'ownerId': instance.ownerId,
  'categoryId': instance.categoryId,
  'useStatus': instance.useStatus,
  'expireAt': instance.expireAt.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  '__v': instance.version,
};

BagItemDetails _$BagItemDetailsFromJson(Map<String, dynamic> json) =>
    BagItemDetails(
      id: json['_id'] as String,
      name: json['name'] as String,
      validity: (json['validity'] as num).toInt(),
      categoryId: json['categoryId'] as String,
      isPremium: json['isPremium'] as bool,
      price: (json['price'] as num).toInt(),
      svgaFile: json['svgaFile'] as String?,
      deleteStatus: json['deleteStatus'] as bool,
      totalSold: (json['totalSold'] as num).toInt(),
      bundleFiles: json['bundleFiles'] as List<dynamic>,
      expireAt: DateTime.parse(json['expireAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: (json['__v'] as num).toInt(),
    );

Map<String, dynamic> _$BagItemDetailsToJson(BagItemDetails instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'validity': instance.validity,
      'categoryId': instance.categoryId,
      'isPremium': instance.isPremium,
      'price': instance.price,
      'svgaFile': instance.svgaFile,
      'deleteStatus': instance.deleteStatus,
      'totalSold': instance.totalSold,
      'bundleFiles': instance.bundleFiles,
      'expireAt': instance.expireAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      '__v': instance.version,
    };

BagCategoryDetails _$BagCategoryDetailsFromJson(Map<String, dynamic> json) =>
    BagCategoryDetails(
      id: json['_id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: (json['__v'] as num).toInt(),
    );

Map<String, dynamic> _$BagCategoryDetailsToJson(BagCategoryDetails instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      '__v': instance.version,
    };

BagPagination _$BagPaginationFromJson(Map<String, dynamic> json) =>
    BagPagination(
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      totalPage: (json['totalPage'] as num).toInt(),
    );

Map<String, dynamic> _$BagPaginationToJson(BagPagination instance) =>
    <String, dynamic>{
      'total': instance.total,
      'limit': instance.limit,
      'page': instance.page,
      'totalPage': instance.totalPage,
    };

BagItemsResult _$BagItemsResultFromJson(Map<String, dynamic> json) =>
    BagItemsResult(
      pagination: BagPagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
      buckets: (json['buckets'] as List<dynamic>)
          .map((e) => BagItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BagItemsResultToJson(BagItemsResult instance) =>
    <String, dynamic>{
      'pagination': instance.pagination,
      'buckets': instance.buckets,
    };

BagItemsResponse _$BagItemsResponseFromJson(Map<String, dynamic> json) =>
    BagItemsResponse(
      success: json['success'] as bool,
      result: BagItemsResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BagItemsResponseToJson(BagItemsResponse instance) =>
    <String, dynamic>{'success': instance.success, 'result': instance.result};

PurchaseItemRequest _$PurchaseItemRequestFromJson(Map<String, dynamic> json) =>
    PurchaseItemRequest(itemId: json['itemId'] as String);

Map<String, dynamic> _$PurchaseItemRequestToJson(
  PurchaseItemRequest instance,
) => <String, dynamic>{'itemId': instance.itemId};

UseItemRequest _$UseItemRequestFromJson(Map<String, dynamic> json) =>
    UseItemRequest(bucketId: json['bucketId'] as String);

Map<String, dynamic> _$UseItemRequestToJson(UseItemRequest instance) =>
    <String, dynamic>{'bucketId': instance.bucketId};
