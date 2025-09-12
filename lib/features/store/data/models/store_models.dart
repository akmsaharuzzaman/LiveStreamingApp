import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'store_models.g.dart';

/// Store Category model for the API response
@JsonSerializable()
class StoreCategory extends Equatable {
  @JsonKey(name: '_id')
  final String id;
  final String title;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime updatedAt;
  @JsonKey(name: '__v')
  final int version;

  const StoreCategory({
    required this.id,
    required this.title,
    required this.isPremium,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory StoreCategory.fromJson(Map<String, dynamic> json) =>
      _$StoreCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$StoreCategoryToJson(this);

  @override
  List<Object?> get props => [id, title, isPremium, createdAt, updatedAt, version];
}

/// Store Categories Response model
@JsonSerializable()
class StoreCategoriesResponse extends Equatable {
  final bool success;
  final List<StoreCategory> result;

  const StoreCategoriesResponse({
    required this.success,
    required this.result,
  });

  factory StoreCategoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$StoreCategoriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StoreCategoriesResponseToJson(this);

  @override
  List<Object?> get props => [success, result];
}

/// Bundle File model for store items
@JsonSerializable()
class BundleFile extends Equatable {
  final String categoryName;
  final String svgaFile;
  @JsonKey(name: '_id')
  final String id;

  const BundleFile({
    required this.categoryName,
    required this.svgaFile,
    required this.id,
  });

  factory BundleFile.fromJson(Map<String, dynamic> json) =>
      _$BundleFileFromJson(json);

  Map<String, dynamic> toJson() => _$BundleFileToJson(this);

  @override
  List<Object?> get props => [categoryName, svgaFile, id];
}

/// Store Item model for the API response
@JsonSerializable()
class StoreItem extends Equatable {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final int validity;
  final String categoryId;
  final bool isPremium;
  final int price;
  final List<BundleFile> bundleFiles;
  final bool deleteStatus;
  final int totalSold;
  final DateTime expireAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  @JsonKey(name: '__v')
  final int version;

  const StoreItem({
    required this.id,
    required this.name,
    required this.validity,
    required this.categoryId,
    required this.isPremium,
    required this.price,
    required this.bundleFiles,
    required this.deleteStatus,
    required this.totalSold,
    required this.expireAt,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory StoreItem.fromJson(Map<String, dynamic> json) =>
      _$StoreItemFromJson(json);

  Map<String, dynamic> toJson() => _$StoreItemToJson(this);

  /// Get the primary asset URL (first bundle file's svgaFile)
  String? get asset => bundleFiles.isNotEmpty ? bundleFiles.first.svgaFile : null;

  /// Check if the item has an animated asset (SVGA files are animated)
  bool get isAnimated => bundleFiles.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        name,
        validity,
        categoryId,
        isPremium,
        price,
        bundleFiles,
        deleteStatus,
        totalSold,
        expireAt,
        createdAt,
        updatedAt,
        version,
      ];
}

/// Pagination model for store items response
@JsonSerializable()
class StorePagination extends Equatable {
  final int total;
  final int limit;
  final int page;
  final int totalPage;

  const StorePagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory StorePagination.fromJson(Map<String, dynamic> json) =>
      _$StorePaginationFromJson(json);

  Map<String, dynamic> toJson() => _$StorePaginationToJson(this);

  @override
  List<Object?> get props => [total, limit, page, totalPage];
}

/// Store Items Result model (nested structure in response)
@JsonSerializable()
class StoreItemsResult extends Equatable {
  final StorePagination pagination;
  final List<StoreItem> items;

  const StoreItemsResult({
    required this.pagination,
    required this.items,
  });

  factory StoreItemsResult.fromJson(Map<String, dynamic> json) =>
      _$StoreItemsResultFromJson(json);

  Map<String, dynamic> toJson() => _$StoreItemsResultToJson(this);

  @override
  List<Object?> get props => [pagination, items];
}

/// Store Items Response model
@JsonSerializable()
class StoreItemsResponse extends Equatable {
  final bool success;
  final StoreItemsResult result;

  const StoreItemsResponse({
    required this.success,
    required this.result,
  });

  factory StoreItemsResponse.fromJson(Map<String, dynamic> json) =>
      _$StoreItemsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StoreItemsResponseToJson(this);

  @override
  List<Object?> get props => [success, result];
}
