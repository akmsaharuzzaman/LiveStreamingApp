import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/bag_models.dart';
import '../../data/models/store_models.dart';
import '../../data/services/bag_api_service.dart';
import 'bag_event.dart';
import 'bag_state.dart';

@injectable
class BagBloc extends Bloc<BagEvent, BagState> {
  final BagApiService _bagApiService;

  BagBloc(this._bagApiService) : super(const BagInitial()) {
    on<LoadBagCategories>(_onLoadBagCategories);
    on<SelectBagCategory>(_onSelectBagCategory);
    on<LoadBagItems>(_onLoadBagItems);
    on<PurchaseItem>(_onPurchaseItem);
    on<UseItem>(_onUseItem);
    on<RefreshBagItems>(_onRefreshBagItems);
  }

  Future<void> _onLoadBagCategories(
    LoadBagCategories event,
    Emitter<BagState> emit,
  ) async {
    emit(const BagCategoriesLoading());

    final result = await _bagApiService.getCategories();

    result.when(
      success: (response) {
        final categories = response.result;
        if (categories.isNotEmpty) {
          // Automatically select the first category
          emit(
            BagCategoriesLoaded(
              categories: categories,
              selectedCategoryId: categories.first.id,
              selectedCategoryTitle: categories.first.title,
            ),
          );
          // Load items for the first category
          add(LoadBagItems(categoryId: categories.first.id));
        } else {
          emit(BagCategoriesLoaded(categories: categories));
        }
      },
      failure: (error) {
        emit(BagError(message: error));
      },
    );
  }

  Future<void> _onSelectBagCategory(
    SelectBagCategory event,
    Emitter<BagState> emit,
  ) async {
    final currentState = state;

    if (currentState is BagCategoriesLoaded ||
        currentState is BagItemsLoaded ||
        currentState is BagUsingItem) {
      List<StoreCategory> categories;

      if (currentState is BagCategoriesLoaded) {
        categories = currentState.categories;
      } else if (currentState is BagItemsLoaded) {
        categories = currentState.categories;
      } else if (currentState is BagUsingItem) {
        categories = currentState.categories;
      } else {
        return;
      }

      // Update the selected category
      emit(
        BagCategoriesLoaded(
          categories: categories,
          selectedCategoryId: event.categoryId,
          selectedCategoryTitle: event.categoryTitle,
        ),
      );

      // Load items for this category
      add(LoadBagItems(categoryId: event.categoryId));
    }
  }

  Future<void> _onLoadBagItems(
    LoadBagItems event,
    Emitter<BagState> emit,
  ) async {
    final currentState = state;

    if (currentState is BagCategoriesLoaded ||
        currentState is BagItemsLoaded ||
        currentState is BagUsingItem) {
      List<StoreCategory> categories;
      String selectedCategoryTitle = '';

      if (currentState is BagCategoriesLoaded) {
        categories = currentState.categories;
        selectedCategoryTitle = currentState.selectedCategoryTitle ?? '';
      } else if (currentState is BagItemsLoaded) {
        categories = currentState.categories;
        selectedCategoryTitle = currentState.selectedCategoryTitle;
      } else if (currentState is BagUsingItem) {
        categories = currentState.categories;
        selectedCategoryTitle = currentState.selectedCategoryTitle;
      } else {
        return;
      }

      emit(
        BagItemsLoading(
          categories: categories,
          selectedCategoryId: event.categoryId,
          selectedCategoryTitle: selectedCategoryTitle,
        ),
      );

      final result = await _bagApiService.getBagItemsByCategory(
        event.categoryId,
      );

      result.when(
        success: (response) {
          emit(
            BagItemsLoaded(
              categories: categories,
              selectedCategoryId: event.categoryId,
              selectedCategoryTitle: selectedCategoryTitle,
              bagItems: response.result.buckets,
              pagination: response.result.pagination,
            ),
          );
        },
        failure: (error) {
          emit(BagError(message: error));
        },
      );
    }
  }

  Future<void> _onPurchaseItem(
    PurchaseItem event,
    Emitter<BagState> emit,
  ) async {
    final currentState = state;

    if (currentState is BagCategoriesLoaded) {
      List<BagItem>? currentBagItems;
      if (currentState is BagItemsLoaded) {
        currentBagItems = (currentState as BagItemsLoaded).bagItems;
      }

      emit(
        BagPurchasing(
          categories: currentState.categories,
          selectedCategoryId: currentState.selectedCategoryId,
          selectedCategoryTitle: currentState.selectedCategoryTitle,
          bagItems: currentBagItems,
        ),
      );

      final result = await _bagApiService.purchaseItem(event.itemId);

      result.when(
        success: (response) {
          emit(
            BagPurchaseSuccess(
              categories: currentState.categories,
              selectedCategoryId: currentState.selectedCategoryId,
              selectedCategoryTitle: currentState.selectedCategoryTitle,
              bagItems: currentBagItems,
              message: 'Item purchased successfully!',
            ),
          );

          // Refresh bag items if a category is selected
          if (currentState.selectedCategoryId != null) {
            add(LoadBagItems(categoryId: currentState.selectedCategoryId!));
          }
        },
        failure: (error) {
          emit(BagError(message: error));
        },
      );
    }
  }

  Future<void> _onUseItem(UseItem event, Emitter<BagState> emit) async {
    final currentState = state;

    if (currentState is BagItemsLoaded) {
      emit(
        BagUsingItem(
          categories: currentState.categories,
          selectedCategoryId: currentState.selectedCategoryId,
          selectedCategoryTitle: currentState.selectedCategoryTitle,
          bagItems: currentState.bagItems,
          pagination: currentState.pagination,
          usingItemId: event.bucketId, // Pass the specific item ID
        ),
      );

      final result = await _bagApiService.useItem(event.bucketId);

      result.when(
        success: (response) {
          // Refresh the bag items to get updated useStatus
          add(LoadBagItems(categoryId: currentState.selectedCategoryId));
        },
        failure: (error) {
          // Return to the previous state on error
          emit(
            BagItemsLoaded(
              categories: currentState.categories,
              selectedCategoryId: currentState.selectedCategoryId,
              selectedCategoryTitle: currentState.selectedCategoryTitle,
              bagItems: currentState.bagItems,
              pagination: currentState.pagination,
            ),
          );

          // Then emit error (this will be handled by the UI listener)
          emit(BagError(message: error));
        },
      );
    }
  }

  Future<void> _onRefreshBagItems(
    RefreshBagItems event,
    Emitter<BagState> emit,
  ) async {
    final currentState = state;

    if (currentState is BagItemsLoaded) {
      add(LoadBagItems(categoryId: currentState.selectedCategoryId));
    } else if (currentState is BagUsingItem) {
      add(LoadBagItems(categoryId: currentState.selectedCategoryId));
    }
  }
}
