import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svga_easyplayer/flutter_svga_easyplayer.dart';
import 'package:go_router/go_router.dart';
import '../../../store/presentation/bloc/store_bloc.dart';
import '../../../store/presentation/bloc/store_event.dart';
import '../../../store/presentation/bloc/store_state.dart';
import '../../../store/data/models/store_models.dart';
import '../../../../injection/injection.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<StoreBloc>()..add(const LoadCategoriesEvent()),
      child: const _StorePageContent(),
    );
  }
}

class _StorePageContent extends StatelessWidget {
  const _StorePageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<StoreBloc, StoreState>(
        listener: (context, state) {
          if (state is StoreError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is StorePurchaseSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            // The state will automatically transition to StoreCategoriesLoaded
            // in the bloc, so we don't need to do anything else here
          }
        },
        builder: (context, state) {
          if (state is StoreCategoriesLoading) {
            return const _LoadingWidget();
          } else if (state is StoreCategoriesLoaded) {
            return _StoreContent(state: state);
          } else if (state is StoreItemsLoading) {
            return _StoreContent(
              state: StoreCategoriesLoaded(
                categories: state.categories,
                selectedCategoryIndex: state.selectedCategoryIndex,
                currentItems: const [],
                selectedItemIndex: 0,
                itemsLoading: true,
              ),
            );
          } else if (state is StorePurchaseLoading) {
            return _StoreContent(
              state: StoreCategoriesLoaded(
                categories: state.categories,
                selectedCategoryIndex: state.selectedCategoryIndex,
                currentItems: state.currentItems,
                selectedItemIndex: state.selectedItemIndex,
                itemsLoading: false,
              ),
              showPurchaseLoading: true,
            );
          } else if (state is StorePurchaseSuccess) {
            // Convert to StoreCategoriesLoaded state to ensure all buttons work
            return _StoreContent(
              state: StoreCategoriesLoaded(
                categories: state.categories,
                selectedCategoryIndex: state.selectedCategoryIndex,
                currentItems: state.currentItems,
                selectedItemIndex: state.selectedItemIndex,
                itemsLoading: false,
              ),
            );
          } else if (state is StoreError) {
            return _ErrorWidget(message: state.message);
          }

          return const _LoadingWidget();
        },
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;

  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.sp, color: Colors.red),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    context.read<StoreBloc>().add(const LoadCategoriesEvent());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreContent extends StatelessWidget {
  final StoreCategoriesLoaded state;
  final bool showPurchaseLoading;

  const _StoreContent({required this.state, this.showPurchaseLoading = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Showcase Section
        _buildShowcaseSection(context),
        SizedBox(height: 20.h),

        // Purchase Section
        _buildPurchaseSection(context),
        SizedBox(height: 20.h),

        // Tabs Section
        _buildTabsSection(context),

        // Content Grid
        Expanded(child: _buildContentGrid(context)),
      ],
    );
  }

  Widget _buildShowcaseSection(BuildContext context) {
    final selectedItem = state.selectedItem;

    return Stack(
      children: [
        Container(
          height: 280.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: const Color(0xFF1A1A1A),
          ),
          child: Stack(
            children: [
              // Pedestal / base showcase
              Image.asset(
                'assets/images/general/showcase_frame.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: const Color(0xFF1A1A1A),
                    ),
                  );
                },
              ),
              // Selected item preview
              Center(
                child: SizedBox(
                  width: 220.w,
                  height: 180.h,
                  child: selectedItem != null
                      ? _buildStoreAssetWidget(selectedItem, isShowcase: true)
                      : Icon(
                          Icons.shopping_bag_outlined,
                          size: 120.sp,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                ),
              ),
            ],
          ),
        ),
        // Navigation back button
        Positioned(
          top: 40.h,
          left: 20.w,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseSection(BuildContext context) {
    final selectedItem = state.selectedItem;

    if (selectedItem == null) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        child: const Text(
          'Select an item to see purchase options',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  selectedItem.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                // Subtitle
                Text(
                  'Purchase with coin',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                if (selectedItem.validity > 0) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Validity: ${selectedItem.validity} days',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 16.w),
          // Buy Button
          GestureDetector(
            onTap: showPurchaseLoading
                ? null
                : () => _showPurchaseDialog(context, selectedItem),
            child: Container(
              width: 120.w,
              height: 40.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: showPurchaseLoading
                      ? [Colors.grey, Colors.grey]
                      : [const Color(0xFFFF6B9D), const Color(0xFFFF8BA0)],
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Center(
                child: showPurchaseLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Buy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        children: List.generate(
          state.categories.length,
          (index) => GestureDetector(
            onTap: () {
              context.read<StoreBloc>().add(
                SelectCategoryEvent(
                  categoryIndex: index,
                  categoryId: state.categories[index].id,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              margin: EdgeInsets.only(right: 16.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: state.selectedCategoryIndex == index
                        ? const Color(0xFFFF6B9D)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                state.categories[index].title,
                style: TextStyle(
                  color: state.selectedCategoryIndex == index
                      ? const Color(0xFFFF6B9D)
                      : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: state.selectedCategoryIndex == index
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentGrid(BuildContext context) {
    if (state.itemsLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
        ),
      );
    }

    if (state.currentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No items available in this category',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(20.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16.h,
          crossAxisSpacing: 16.w,
          childAspectRatio: 0.8,
        ),
        itemCount: state.currentItems.length,
        itemBuilder: (context, index) {
          return _buildStoreItem(context, index, state.currentItems[index]);
        },
      ),
    );
  }

  Widget _buildStoreItem(BuildContext context, int index, StoreItem item) {
    final isSelected = index == state.selectedItemIndex;

    return GestureDetector(
      onTap: () {
        context.read<StoreBloc>().add(SelectItemEvent(itemIndex: index));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B9D) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[200]!,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Item Image
            Expanded(
              flex: 3,
              child: Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  color: Colors.grey[100],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 60.w,
                        height: 60.h,
                        child: _buildStoreAssetWidget(item, thumbnail: true),
                      ),
                    ),
                    if (item.isAnimated)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 18.sp,
                          color: const Color(0x99000000),
                        ),
                      ),
                    if (item.isPremium)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Icon(
                          Icons.star,
                          size: 18.sp,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Item Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  children: [
                    // Item Name
                    Text(
                      item.name,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: const Color(0xFFFFD700),
                          size: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${item.price}',
                          style: TextStyle(
                            color: const Color(0xFFFFD700),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, StoreItem item) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Purchase ${item.name}',
            style: const TextStyle(color: Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Do you want to purchase this item for ${item.price} coins?',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: const Color(0xFFFFD700),
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${item.price}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<StoreBloc>().add(
                  PurchaseItemEvent(itemId: item.id),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
              ),
              child: const Text(
                'Buy Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Helper function to build app bar
Widget _buildAppBar(BuildContext context) {
  return Container(
    height: 100.h,
    decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            const Expanded(
              child: Text(
                'Store',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 48.w), // Balance the back button
          ],
        ),
      ),
    ),
  );
}

// Helper function to render store assets
Widget _buildStoreAssetWidget(
  StoreItem item, {
  bool isShowcase = false,
  bool thumbnail = false,
}) {
  if (item.asset == null || item.asset!.isEmpty) {
    return Icon(
      Icons.shopping_bag_outlined,
      size: isShowcase ? 120.sp : 40.sp,
      color: const Color(0xFFFF6B9D),
    );
  }

  // If it's a URL, use NetworkImage
  if (item.asset!.startsWith('http') && !thumbnail) {
    return SVGAEasyPlayer(resUrl: item.asset!, fit: BoxFit.contain);
  } else {
    return Image.network(
      item.asset!,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.broken_image,
        size: isShowcase ? 120.sp : 40.sp,
        color: Colors.grey[400],
      ),
    );
  }

  // If it's a local asset
  return Image.asset(
    item.asset!,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) => Icon(
      Icons.broken_image,
      size: isShowcase ? 120.sp : 40.sp,
      color: Colors.grey[400],
    ),
  );
}
