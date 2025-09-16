import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bag_models.g.dart';

/// Bag Item model for owned items in user's bag
@JsonSerializable()
class BagItem extends Equatable {
  @JsonKey(name: '_id')
  final String id;
  final BagItemDetails itemId;
  final String ownerId;
  final BagCategoryDetails categoryId;
  final bool useStatus;
  final DateTime expireAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  @JsonKey(name: '__v')
  final int version;

  const BagItem({
    required this.id,
    required this.itemId,
    required this.ownerId,
    required this.categoryId,
    required this.useStatus,
    required this.expireAt,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory BagItem.fromJson(Map<String, dynamic> json) =>
      _$BagItemFromJson(json);

  Map<String, dynamic> toJson() => _$BagItemToJson(this);

  @override
  List<Object?> get props => [
    id,
    itemId,
    ownerId,
    categoryId,
    useStatus,
    expireAt,
    createdAt,
    updatedAt,
    version,
  ];
}

/// Bag Item Details - nested item information
@JsonSerializable()
class BagItemDetails extends Equatable {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final int validity;
  final String categoryId;
  final bool isPremium;
  final int price;
  final String? svgaFile;
  final bool deleteStatus;
  final int totalSold;
  final List<dynamic> bundleFiles;
  final DateTime expireAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  @JsonKey(name: '__v')
  final int version;

  const BagItemDetails({
    required this.id,
    required this.name,
    required this.validity,
    required this.categoryId,
    required this.isPremium,
    required this.price,
    this.svgaFile,
    required this.deleteStatus,
    required this.totalSold,
    required this.bundleFiles,
    required this.expireAt,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory BagItemDetails.fromJson(Map<String, dynamic> json) =>
      _$BagItemDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$BagItemDetailsToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    validity,
    categoryId,
    isPremium,
    price,
    svgaFile,
    deleteStatus,
    totalSold,
    bundleFiles,
    expireAt,
    createdAt,
    updatedAt,
    version,
  ];
}

/// Bag Category Details - nested category information
@JsonSerializable()
class BagCategoryDetails extends Equatable {
  @JsonKey(name: '_id')
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  @JsonKey(name: '__v')
  final int version;

  const BagCategoryDetails({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory BagCategoryDetails.fromJson(Map<String, dynamic> json) =>
      _$BagCategoryDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$BagCategoryDetailsToJson(this);

  @override
  List<Object?> get props => [id, title, createdAt, updatedAt, version];
}

/// Bag Pagination model
@JsonSerializable()
class BagPagination extends Equatable {
  final int total;
  final int limit;
  final int page;
  final int totalPage;

  const BagPagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory BagPagination.fromJson(Map<String, dynamic> json) =>
      _$BagPaginationFromJson(json);

  Map<String, dynamic> toJson() => _$BagPaginationToJson(this);

  @override
  List<Object?> get props => [total, limit, page, totalPage];
}

/// Bag Items Result wrapper
@JsonSerializable()
class BagItemsResult extends Equatable {
  final BagPagination pagination;
  final List<BagItem> buckets;

  const BagItemsResult({required this.pagination, required this.buckets});

  factory BagItemsResult.fromJson(Map<String, dynamic> json) =>
      _$BagItemsResultFromJson(json);

  Map<String, dynamic> toJson() => _$BagItemsResultToJson(this);

  @override
  List<Object?> get props => [pagination, buckets];
}

/// Bag Items Response model
@JsonSerializable()
class BagItemsResponse extends Equatable {
  final bool success;
  final BagItemsResult result;

  const BagItemsResponse({required this.success, required this.result});

  factory BagItemsResponse.fromJson(Map<String, dynamic> json) =>
      _$BagItemsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BagItemsResponseToJson(this);

  @override
  List<Object?> get props => [success, result];
}

/// Purchase Item Request
@JsonSerializable()
class PurchaseItemRequest extends Equatable {
  final String itemId;

  const PurchaseItemRequest({required this.itemId});

  factory PurchaseItemRequest.fromJson(Map<String, dynamic> json) =>
      _$PurchaseItemRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseItemRequestToJson(this);

  @override
  List<Object?> get props => [itemId];
}

/// Use Item Request
@JsonSerializable()
class UseItemRequest extends Equatable {
  final String bucketId;

  const UseItemRequest({required this.bucketId});

  factory UseItemRequest.fromJson(Map<String, dynamic> json) =>
      _$UseItemRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UseItemRequestToJson(this);

  @override
  List<Object?> get props => [bucketId];
}
