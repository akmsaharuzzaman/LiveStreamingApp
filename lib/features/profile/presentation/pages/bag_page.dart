import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_model.dart';
import '../../../../injection/injection.dart';
import '../../../store/data/models/bag_models.dart';
import '../../../store/data/models/store_models.dart';
import '../../../store/presentation/bloc/bag_bloc.dart';
import '../../../store/presentation/bloc/bag_event.dart';
import '../../../store/presentation/bloc/bag_state.dart';

class BagPage extends StatelessWidget {
  final UserModel user;

  const BagPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<BagBloc>()..add(const LoadBagCategories()),
      child: Scaffold(
        body: Column(
          children: [
            Container(
              height: 280.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.topRight,
                  colors: [
                    Color(0xFF9D64B0), // Purple
                    Color(0xFFFE82A7), // Pink
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    SizedBox(height: 20.h),
                    _buildUserProfile(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            // Categories and Items Section
            Expanded(
              child: BlocConsumer<BagBloc, BagState>(
                listener: (context, state) {
                  if (state is BagError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is BagPurchaseSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is BagCategoriesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is BagCategoriesLoaded ||
                      state is BagItemsLoading ||
                      state is BagItemsLoaded ||
                      state is BagPurchasing ||
                      state is BagPurchaseSuccess ||
                      state is BagUsingItem) {
                    return _buildCategoriesAndItems(context, state);
                  } else if (state is BagError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64.sp,
                            color: Colors.red[300],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Something went wrong',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            state.message,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<BagBloc>().add(
                                const LoadBagCategories(),
                              );
                            },
                            icon: Icon(Icons.refresh),
                            label: Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF9D64B0),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 15.w),
          Text(
            'My Bag',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return SizedBox(
      width: 160.w,
      height: 140.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // User Image
          Positioned(
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.w),
              ),
              child: ClipOval(
                child: user.avatar != null && user.avatar!.isNotEmpty
                    ? Image.network(
                        user.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
          ),
          // Profile Frame
          Image.asset(
            'assets/images/general/profile_frame.png',
            width: 140.w,
            height: 140.w,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.person, size: 50.sp, color: Colors.grey[600]),
    );
  }

  Widget _buildCategoriesAndItems(BuildContext context, BagState state) {
    List<StoreCategory> categories = [];
    String? selectedCategoryId;
    List<BagItem>? bagItems;
    bool isLoadingItems = false;
    bool isPurchasing = false;
    String? usingItemId; // Track which specific item is being used

    if (state is BagCategoriesLoaded) {
      categories = state.categories;
      selectedCategoryId = state.selectedCategoryId;
    } else if (state is BagItemsLoading) {
      categories = state.categories;
      selectedCategoryId = state.selectedCategoryId;
      isLoadingItems = true;
    } else if (state is BagItemsLoaded) {
      categories = state.categories;
      selectedCategoryId = state.selectedCategoryId;
      bagItems = state.bagItems;
    } else if (state is BagPurchasing) {
      categories = state.categories;
      selectedCategoryId = state.selectedCategoryId;
      bagItems = state.bagItems;
      isPurchasing = true;
    } else if (state is BagPurchaseSuccess) {
      categories = state.categories;
      selectedCategoryId = state.selectedCategoryId;
      bagItems = state.bagItems;
    } else if (state is BagUsingItem) {
      categories = state.categories;
      selectedCategoryId = state.selectedCategoryId;
      bagItems = state.bagItems;
      usingItemId = state.usingItemId; // Get the specific item ID being used
    }

    return Column(
      children: [
        // Categories Tab Bar
        if (categories.isNotEmpty)
          _buildCategoriesTabBar(context, categories, selectedCategoryId),

        SizedBox(height: 16.h),

        // Items Grid
        Expanded(
          child: isLoadingItems
              ? const Center(child: CircularProgressIndicator())
              : bagItems != null && bagItems.isNotEmpty
              ? RefreshIndicator(
                  onRefresh: () async {
                    if (selectedCategoryId != null) {
                      final category = categories.firstWhere(
                        (cat) => cat.id == selectedCategoryId,
                      );
                      context.read<BagBloc>().add(
                        SelectBagCategory(
                          categoryId: selectedCategoryId,
                          categoryTitle: category.title,
                        ),
                      );
                    }
                  },
                  child: _buildBagItemsGrid(
                    context,
                    bagItems,
                    isPurchasing,
                    state is BagUsingItem,
                    usingItemId,
                  ),
                )
              : selectedCategoryId != null
              ? _buildEmptyBag()
              : _buildSelectCategoryPrompt(),
        ),
      ],
    );
  }

  Widget _buildCategoriesTabBar(
    BuildContext context,
    List<StoreCategory> categories,
    String? selectedCategoryId,
  ) {
    return SizedBox(
      height: 50.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategoryId == category.id;

          return GestureDetector(
            onTap: () {
              context.read<BagBloc>().add(
                SelectBagCategory(
                  categoryId: category.id,
                  categoryTitle: category.title,
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(right: 12.w),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [Color(0xFF9D64B0), Color(0xFFFE82A7)],
                      )
                    : null,
                color: isSelected ? null : Colors.grey[200],
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Text(
                  category.title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 14.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBagItemsGrid(
    BuildContext context,
    List<BagItem> bagItems,
    bool isPurchasing,
    bool isUsingItem,
    String? usingItemId,
  ) {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: bagItems.length,
      itemBuilder: (context, index) {
        final bagItem = bagItems[index];
        final isThisItemUsing =
            usingItemId != null && usingItemId == bagItem.id;
        return _buildBagItemCard(
          context,
          bagItem,
          isPurchasing,
          isThisItemUsing,
        );
      },
    );
  }

  Widget _buildBagItemCard(
    BuildContext context,
    BagItem bagItem,
    bool isPurchasing,
    bool isUsingItem,
  ) {
    final item = bagItem.itemId;
    final isSelected = bagItem.useStatus;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey[300]!,
          width: isSelected ? 2.w : 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item Image
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey[100],
                child: item.svgaFile != null && item.svgaFile!.isNotEmpty
                    ? Image.network(
                        item.svgaFile!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),
            ),

            // Item Details
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 4.h),

                    Text(
                      '${item.validity} days',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),

                    Spacer(),

                    // Use/Selected Button
                    SizedBox(
                      width: double.infinity,
                      height: 28.h,
                      child: ElevatedButton(
                        onPressed: isUsingItem
                            ? null
                            : () {
                                if (!isSelected) {
                                  context.read<BagBloc>().add(
                                    UseItem(bucketId: bagItem.id),
                                  );

                                  // Add timeout to prevent infinite loading
                                  Future.delayed(Duration(seconds: 8), () {
                                    // Check if widget is still mounted and force refresh if stuck
                                    if (context.mounted) {
                                      final currentState = context
                                          .read<BagBloc>()
                                          .state;
                                      if (currentState is BagUsingItem &&
                                          currentState.usingItemId ==
                                              bagItem.id) {
                                        // Reload items to get fresh state
                                        final selectedCategory = currentState
                                            .categories
                                            .firstWhere(
                                              (cat) =>
                                                  cat.id ==
                                                  currentState
                                                      .selectedCategoryId,
                                            );
                                        context.read<BagBloc>().add(
                                          SelectBagCategory(
                                            categoryId:
                                                currentState.selectedCategoryId,
                                            categoryTitle:
                                                selectedCategory.title,
                                          ),
                                        );
                                      }
                                    }
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Colors.green
                              : Color(0xFF9D64B0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: isUsingItem
                            ? SizedBox(
                                height: 16.h,
                                width: 16.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                isSelected ? 'Using' : 'Use',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Selected Indicator
            if (isSelected) Container(height: 4.h, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image, size: 40.sp, color: Colors.grey[400]),
    );
  }

  Widget _buildEmptyBag() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No items in this category',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Purchase items from the store to see them here',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectCategoryPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'Select a category',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Choose a category above to view your items',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
