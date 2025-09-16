import 'package:equatable/equatable.dart';
import '../../data/models/bag_models.dart';
import '../../data/models/store_models.dart';

/// Base state for bag functionality
abstract class BagState extends Equatable {
  const BagState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BagInitial extends BagState {
  const BagInitial();
}

/// Loading state for categories
class BagCategoriesLoading extends BagState {
  const BagCategoriesLoading();
}

/// Categories loaded successfully
class BagCategoriesLoaded extends BagState {
  final List<StoreCategory> categories;
  final String? selectedCategoryId;
  final String? selectedCategoryTitle;

  const BagCategoriesLoaded({
    required this.categories,
    this.selectedCategoryId,
    this.selectedCategoryTitle,
  });

  @override
  List<Object?> get props => [
    categories,
    selectedCategoryId,
    selectedCategoryTitle,
  ];

  BagCategoriesLoaded copyWith({
    List<StoreCategory>? categories,
    String? selectedCategoryId,
    String? selectedCategoryTitle,
  }) {
    return BagCategoriesLoaded(
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedCategoryTitle:
          selectedCategoryTitle ?? this.selectedCategoryTitle,
    );
  }
}

/// Loading state for bag items
class BagItemsLoading extends BagState {
  final List<StoreCategory> categories;
  final String selectedCategoryId;
  final String selectedCategoryTitle;

  const BagItemsLoading({
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedCategoryTitle,
  });

  @override
  List<Object?> get props => [
    categories,
    selectedCategoryId,
    selectedCategoryTitle,
  ];
}

/// Bag items loaded successfully
class BagItemsLoaded extends BagState {
  final List<StoreCategory> categories;
  final String selectedCategoryId;
  final String selectedCategoryTitle;
  final List<BagItem> bagItems;
  final BagPagination pagination;

  const BagItemsLoaded({
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedCategoryTitle,
    required this.bagItems,
    required this.pagination,
  });

  @override
  List<Object?> get props => [
    categories,
    selectedCategoryId,
    selectedCategoryTitle,
    bagItems,
    pagination,
  ];

  BagItemsLoaded copyWith({
    List<StoreCategory>? categories,
    String? selectedCategoryId,
    String? selectedCategoryTitle,
    List<BagItem>? bagItems,
    BagPagination? pagination,
  }) {
    return BagItemsLoaded(
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedCategoryTitle:
          selectedCategoryTitle ?? this.selectedCategoryTitle,
      bagItems: bagItems ?? this.bagItems,
      pagination: pagination ?? this.pagination,
    );
  }
}

/// Purchasing item
class BagPurchasing extends BagState {
  final List<StoreCategory> categories;
  final String? selectedCategoryId;
  final String? selectedCategoryTitle;
  final List<BagItem>? bagItems;

  const BagPurchasing({
    required this.categories,
    this.selectedCategoryId,
    this.selectedCategoryTitle,
    this.bagItems,
  });

  @override
  List<Object?> get props => [
    categories,
    selectedCategoryId,
    selectedCategoryTitle,
    bagItems,
  ];
}

/// Purchase successful
class BagPurchaseSuccess extends BagState {
  final List<StoreCategory> categories;
  final String? selectedCategoryId;
  final String? selectedCategoryTitle;
  final List<BagItem>? bagItems;
  final String message;

  const BagPurchaseSuccess({
    required this.categories,
    this.selectedCategoryId,
    this.selectedCategoryTitle,
    this.bagItems,
    required this.message,
  });

  @override
  List<Object?> get props => [
    categories,
    selectedCategoryId,
    selectedCategoryTitle,
    bagItems,
    message,
  ];
}

/// Using item
class BagUsingItem extends BagState {
  final List<StoreCategory> categories;
  final String selectedCategoryId;
  final String selectedCategoryTitle;
  final List<BagItem> bagItems;
  final BagPagination pagination;
  final String usingItemId; // Add specific item ID being used

  const BagUsingItem({
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedCategoryTitle,
    required this.bagItems,
    required this.pagination,
    required this.usingItemId,
  });

  @override
  List<Object?> get props => [
    categories,
    selectedCategoryId,
    selectedCategoryTitle,
    bagItems,
    pagination,
    usingItemId,
  ];
}

/// Error state
class BagError extends BagState {
  final String message;

  const BagError({required this.message});

  @override
  List<Object?> get props => [message];
}
