import 'package:equatable/equatable.dart';

/// Store Events
abstract class StoreEvent extends Equatable {
  const StoreEvent();

  @override
  List<Object?> get props => [];
}

/// Load store categories
class LoadCategoriesEvent extends StoreEvent {
  const LoadCategoriesEvent();
}

/// Load items for a specific category
class LoadCategoryItemsEvent extends StoreEvent {
  final String categoryId;

  const LoadCategoryItemsEvent({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

/// Select a category tab
class SelectCategoryEvent extends StoreEvent {
  final int categoryIndex;
  final String categoryId;

  const SelectCategoryEvent({
    required this.categoryIndex,
    required this.categoryId,
  });

  @override
  List<Object?> get props => [categoryIndex, categoryId];
}

/// Select a specific item
class SelectItemEvent extends StoreEvent {
  final int itemIndex;

  const SelectItemEvent({required this.itemIndex});

  @override
  List<Object?> get props => [itemIndex];
}

/// Purchase an item
class PurchaseItemEvent extends StoreEvent {
  final String itemId;

  const PurchaseItemEvent({required this.itemId});

  @override
  List<Object?> get props => [itemId];
}
