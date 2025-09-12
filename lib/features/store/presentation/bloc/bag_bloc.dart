import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/bag_models.dart';
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
        emit(BagCategoriesLoaded(categories: response.result));
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
    
    if (currentState is BagCategoriesLoaded) {
      // Update the selected category
      emit(currentState.copyWith(
        selectedCategoryId: event.categoryId,
        selectedCategoryTitle: event.categoryTitle,
      ));
      
      // Load items for this category
      add(LoadBagItems(categoryId: event.categoryId));
    }
  }

  Future<void> _onLoadBagItems(
    LoadBagItems event,
    Emitter<BagState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is BagCategoriesLoaded) {
      emit(BagItemsLoading(
        categories: currentState.categories,
        selectedCategoryId: event.categoryId,
        selectedCategoryTitle: currentState.selectedCategoryTitle ?? '',
      ));

      final result = await _bagApiService.getBagItemsByCategory(event.categoryId);

      result.when(
        success: (response) {
          emit(BagItemsLoaded(
            categories: currentState.categories,
            selectedCategoryId: event.categoryId,
            selectedCategoryTitle: currentState.selectedCategoryTitle ?? '',
            bagItems: response.result.buckets,
            pagination: response.result.pagination,
          ));
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
      
      emit(BagPurchasing(
        categories: currentState.categories,
        selectedCategoryId: currentState.selectedCategoryId,
        selectedCategoryTitle: currentState.selectedCategoryTitle,
        bagItems: currentBagItems,
      ));

      final result = await _bagApiService.purchaseItem(event.itemId);

      result.when(
        success: (response) {
          emit(BagPurchaseSuccess(
            categories: currentState.categories,
            selectedCategoryId: currentState.selectedCategoryId,
            selectedCategoryTitle: currentState.selectedCategoryTitle,
            bagItems: currentBagItems,
            message: 'Item purchased successfully!',
          ));
          
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

  Future<void> _onUseItem(
    UseItem event,
    Emitter<BagState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is BagItemsLoaded) {
      emit(BagUsingItem(
        categories: currentState.categories,
        selectedCategoryId: currentState.selectedCategoryId,
        selectedCategoryTitle: currentState.selectedCategoryTitle,
        bagItems: currentState.bagItems,
        pagination: currentState.pagination,
      ));

      final result = await _bagApiService.useItem(event.bucketId);

      result.when(
        success: (response) {
          // Refresh the bag items to get updated useStatus
          add(LoadBagItems(categoryId: currentState.selectedCategoryId));
        },
        failure: (error) {
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
    }
  }
}
