import 'package:equatable/equatable.dart';
import '../../data/models/store_models.dart';

/// Store States
abstract class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class StoreInitial extends StoreState {
  const StoreInitial();
}

/// Loading categories
class StoreCategoriesLoading extends StoreState {
  const StoreCategoriesLoading();
}

/// Categories loaded successfully
class StoreCategoriesLoaded extends StoreState {
  final List<StoreCategory> categories;
  final int selectedCategoryIndex;
  final List<StoreItem> currentItems;
  final int selectedItemIndex;
  final bool itemsLoading;
  final StorePagination? pagination;

  const StoreCategoriesLoaded({
    required this.categories,
    this.selectedCategoryIndex = 0,
    this.currentItems = const [],
    this.selectedItemIndex = 0,
    this.itemsLoading = false,
    this.pagination,
  });

  /// Get the currently selected category
  StoreCategory get selectedCategory => categories[selectedCategoryIndex];

  /// Get the currently selected item (if any)
  StoreItem? get selectedItem => 
      currentItems.isNotEmpty ? currentItems[selectedItemIndex] : null;

  @override
  List<Object?> get props => [
        categories,
        selectedCategoryIndex,
        currentItems,
        selectedItemIndex,
        itemsLoading,
        pagination,
      ];

  /// Copy with method for state updates
  StoreCategoriesLoaded copyWith({
    List<StoreCategory>? categories,
    int? selectedCategoryIndex,
    List<StoreItem>? currentItems,
    int? selectedItemIndex,
    bool? itemsLoading,
    StorePagination? pagination,
  }) {
    return StoreCategoriesLoaded(
      categories: categories ?? this.categories,
      selectedCategoryIndex: selectedCategoryIndex ?? this.selectedCategoryIndex,
      currentItems: currentItems ?? this.currentItems,
      selectedItemIndex: selectedItemIndex ?? this.selectedItemIndex,
      itemsLoading: itemsLoading ?? this.itemsLoading,
      pagination: pagination ?? this.pagination,
    );
  }
}

/// Error state
class StoreError extends StoreState {
  final String message;

  const StoreError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Items loading state
class StoreItemsLoading extends StoreState {
  final List<StoreCategory> categories;
  final int selectedCategoryIndex;

  const StoreItemsLoading({
    required this.categories,
    required this.selectedCategoryIndex,
  });

  @override
  List<Object?> get props => [categories, selectedCategoryIndex];
}

/// Purchase loading state
class StorePurchaseLoading extends StoreState {
  final List<StoreCategory> categories;
  final int selectedCategoryIndex;
  final List<StoreItem> currentItems;
  final int selectedItemIndex;

  const StorePurchaseLoading({
    required this.categories,
    required this.selectedCategoryIndex,
    required this.currentItems,
    required this.selectedItemIndex,
  });

  @override
  List<Object?> get props => [
        categories,
        selectedCategoryIndex,
        currentItems,
        selectedItemIndex,
      ];
}

/// Purchase success state
class StorePurchaseSuccess extends StoreState {
  final String message;
  final List<StoreCategory> categories;
  final int selectedCategoryIndex;
  final List<StoreItem> currentItems;
  final int selectedItemIndex;

  const StorePurchaseSuccess({
    required this.message,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.currentItems,
    required this.selectedItemIndex,
  });

  @override
  List<Object?> get props => [
        message,
        categories,
        selectedCategoryIndex,
        currentItems,
        selectedItemIndex,
      ];
}
