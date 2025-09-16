// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoreCategory _$StoreCategoryFromJson(Map<String, dynamic> json) =>
    StoreCategory(
      id: json['_id'] as String,
      title: json['title'] as String,
      isPremium: json['isPremium'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: (json['__v'] as num).toInt(),
    );

Map<String, dynamic> _$StoreCategoryToJson(StoreCategory instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'isPremium': instance.isPremium,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      '__v': instance.version,
    };

StoreCategoriesResponse _$StoreCategoriesResponseFromJson(
  Map<String, dynamic> json,
) => StoreCategoriesResponse(
  success: json['success'] as bool,
  result: (json['result'] as List<dynamic>)
      .map((e) => StoreCategory.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StoreCategoriesResponseToJson(
  StoreCategoriesResponse instance,
) => <String, dynamic>{'success': instance.success, 'result': instance.result};

BundleFile _$BundleFileFromJson(Map<String, dynamic> json) => BundleFile(
  categoryName: json['categoryName'] as String,
  svgaFile: json['svgaFile'] as String,
  id: json['_id'] as String,
);

Map<String, dynamic> _$BundleFileToJson(BundleFile instance) =>
    <String, dynamic>{
      'categoryName': instance.categoryName,
      'svgaFile': instance.svgaFile,
      '_id': instance.id,
    };

StoreItem _$StoreItemFromJson(Map<String, dynamic> json) => StoreItem(
  id: json['_id'] as String,
  name: json['name'] as String,
  validity: (json['validity'] as num).toInt(),
  categoryId: json['categoryId'] as String,
  isPremium: json['isPremium'] as bool,
  price: (json['price'] as num).toInt(),
  bundleFiles: (json['bundleFiles'] as List<dynamic>)
      .map((e) => BundleFile.fromJson(e as Map<String, dynamic>))
      .toList(),
  deleteStatus: json['deleteStatus'] as bool,
  totalSold: (json['totalSold'] as num).toInt(),
  expireAt: DateTime.parse(json['expireAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  version: (json['__v'] as num).toInt(),
);

Map<String, dynamic> _$StoreItemToJson(StoreItem instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'validity': instance.validity,
  'categoryId': instance.categoryId,
  'isPremium': instance.isPremium,
  'price': instance.price,
  'bundleFiles': instance.bundleFiles,
  'deleteStatus': instance.deleteStatus,
  'totalSold': instance.totalSold,
  'expireAt': instance.expireAt.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  '__v': instance.version,
};

StorePagination _$StorePaginationFromJson(Map<String, dynamic> json) =>
    StorePagination(
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      totalPage: (json['totalPage'] as num).toInt(),
    );

Map<String, dynamic> _$StorePaginationToJson(StorePagination instance) =>
    <String, dynamic>{
      'total': instance.total,
      'limit': instance.limit,
      'page': instance.page,
      'totalPage': instance.totalPage,
    };

StoreItemsResult _$StoreItemsResultFromJson(Map<String, dynamic> json) =>
    StoreItemsResult(
      pagination: StorePagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
      items: (json['items'] as List<dynamic>)
          .map((e) => StoreItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StoreItemsResultToJson(StoreItemsResult instance) =>
    <String, dynamic>{
      'pagination': instance.pagination,
      'items': instance.items,
    };

StoreItemsResponse _$StoreItemsResponseFromJson(Map<String, dynamic> json) =>
    StoreItemsResponse(
      success: json['success'] as bool,
      result: StoreItemsResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StoreItemsResponseToJson(StoreItemsResponse instance) =>
    <String, dynamic>{'success': instance.success, 'result': instance.result};
