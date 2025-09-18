import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/services/store_api_service.dart';
import 'store_event.dart';
import 'store_state.dart';

@injectable
class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final StoreApiService _storeApiService;

  StoreBloc(this._storeApiService) : super(const StoreInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<LoadCategoryItemsEvent>(_onLoadCategoryItems);
    on<SelectCategoryEvent>(_onSelectCategory);
    on<SelectItemEvent>(_onSelectItem);
    on<PurchaseItemEvent>(_onPurchaseItem);
  }

  /// Load all store categories
  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<StoreState> emit,
  ) async {
    emit(const StoreCategoriesLoading());

    final result = await _storeApiService.getCategories();

    result.when(
      success: (response) {
        if (response.success && response.result.isNotEmpty) {
          final categories = response.result;
          emit(
            StoreCategoriesLoaded(
              categories: categories,
              selectedCategoryIndex: 0,
              currentItems: const [],
              selectedItemIndex: 0,
              itemsLoading: false,
            ),
          );

          // Automatically load items for the first category
          add(LoadCategoryItemsEvent(categoryId: categories.first.id));
        } else {
          emit(const StoreError(message: 'No categories found'));
        }
      },
      failure: (error) {
        emit(StoreError(message: error));
      },
    );
  }

  /// Load items for a specific category
  Future<void> _onLoadCategoryItems(
    LoadCategoryItemsEvent event,
    Emitter<StoreState> emit,
  ) async {
    final currentState = state;

    if (currentState is StoreCategoriesLoaded) {
      // Update state to show items loading
      emit(currentState.copyWith(itemsLoading: true));

      final result = await _storeApiService.getCategoryItems(event.categoryId);

      result.when(
        success: (response) {
          if (response.success) {
            emit(
              currentState.copyWith(
                currentItems: response.result.items,
                selectedItemIndex: 0,
                itemsLoading: false,
                pagination: response.result.pagination,
              ),
            );
          } else {
            emit(
              currentState.copyWith(
                currentItems: const [],
                selectedItemIndex: 0,
                itemsLoading: false,
              ),
            );
          }
        },
        failure: (error) {
          emit(
            currentState.copyWith(
              currentItems: const [],
              selectedItemIndex: 0,
              itemsLoading: false,
            ),
          );
          emit(StoreError(message: error));
        },
      );
    }
  }

  /// Select a category tab
  Future<void> _onSelectCategory(
    SelectCategoryEvent event,
    Emitter<StoreState> emit,
  ) async {
    final currentState = state;

    if (currentState is StoreCategoriesLoaded) {
      // Update selected category index
      emit(
        currentState.copyWith(
          selectedCategoryIndex: event.categoryIndex,
          currentItems: const [], // Clear current items
          selectedItemIndex: 0,
          itemsLoading: true,
        ),
      );

      // Load items for the newly selected category
      add(LoadCategoryItemsEvent(categoryId: event.categoryId));
    }
  }

  /// Select a specific item
  Future<void> _onSelectItem(
    SelectItemEvent event,
    Emitter<StoreState> emit,
  ) async {
    final currentState = state;

    if (currentState is StoreCategoriesLoaded) {
      emit(currentState.copyWith(selectedItemIndex: event.itemIndex));
    }
  }

  /// Purchase an item
  Future<void> _onPurchaseItem(
    PurchaseItemEvent event,
    Emitter<StoreState> emit,
  ) async {
    final currentState = state;

    if (currentState is StoreCategoriesLoaded) {
      emit(
        StorePurchaseLoading(
          categories: currentState.categories,
          selectedCategoryIndex: currentState.selectedCategoryIndex,
          currentItems: currentState.currentItems,
          selectedItemIndex: currentState.selectedItemIndex,
        ),
      );

      final result = await _storeApiService.purchaseItem(itemId: event.itemId);

      result.when(
        success: (response) {
          // First emit purchase success state to show the success message
          emit(
            StorePurchaseSuccess(
              message: 'Item purchased successfully!',
              categories: currentState.categories,
              selectedCategoryIndex: currentState.selectedCategoryIndex,
              currentItems: currentState.currentItems,
              selectedItemIndex: currentState.selectedItemIndex,
            ),
          );
          
          // Then immediately emit StoreCategoriesLoaded state to ensure UI is interactive
          emit(
            StoreCategoriesLoaded(
              categories: currentState.categories,
              selectedCategoryIndex: currentState.selectedCategoryIndex,
              currentItems: currentState.currentItems,
              selectedItemIndex: currentState.selectedItemIndex,
              itemsLoading: false,
            ),
          );
        },
        failure: (error) {
          emit(StoreError(message: error));
        },
      );
    }
  }
}
