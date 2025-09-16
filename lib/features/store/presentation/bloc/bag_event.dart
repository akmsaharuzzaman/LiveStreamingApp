import 'package:equatable/equatable.dart';

/// Base event for bag functionality
abstract class BagEvent extends Equatable {
  const BagEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load bag categories
class LoadBagCategories extends BagEvent {
  const LoadBagCategories();
}

/// Event to select a category and load its bag items
class SelectBagCategory extends BagEvent {
  final String categoryId;
  final String categoryTitle;

  const SelectBagCategory({
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  List<Object?> get props => [categoryId, categoryTitle];
}

/// Event to load bag items for a specific category
class LoadBagItems extends BagEvent {
  final String categoryId;

  const LoadBagItems({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

/// Event to purchase an item from store
class PurchaseItem extends BagEvent {
  final String itemId;

  const PurchaseItem({required this.itemId});

  @override
  List<Object?> get props => [itemId];
}

/// Event to use/select an item from bag
class UseItem extends BagEvent {
  final String bucketId;

  const UseItem({required this.bucketId});

  @override
  List<Object?> get props => [bucketId];
}

/// Event to refresh current category items
class RefreshBagItems extends BagEvent {
  const RefreshBagItems();
}
