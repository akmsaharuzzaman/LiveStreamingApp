import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  int selectedTabIndex = 0;
  int selectedItemIndex = 0;
  final List<String> tabNames = ['Frame', 'Room Entry', 'Party Theme'];

  // Lightweight item model for the store
  // asset supports static images and animated GIFs (Image.asset renders GIFs natively)
  // If you later introduce Lottie/Rive, add nullable fields and render accordingly in _buildStoreAssetWidget.
  static const _fallbackAsset = 'assets/images/general/showcase_frame.png';
  static const _altAsset = 'assets/images/general/profile_frame.png';

  List<_StoreItem> get _frameItems => [
    _StoreItem(name: 'Noble Blaze', price: 1000, asset: _altAsset),
    _StoreItem(name: 'Magnificent D.', price: 1300, asset: _fallbackAsset),
    _StoreItem(name: 'Grand regal H.', price: 1300, asset: _fallbackAsset),
    _StoreItem(name: 'Noble Blaze', price: 1000, asset: _altAsset),
    _StoreItem(name: 'Magnificent D.', price: 1300, asset: _fallbackAsset),
    _StoreItem(name: 'Grand regal H.', price: 1300, asset: _fallbackAsset),
    _StoreItem(name: 'Elite Frame', price: 1500, asset: _altAsset),
    _StoreItem(name: 'Royal Frame', price: 1800, asset: _fallbackAsset),
    _StoreItem(name: 'Diamond Frame', price: 2000, asset: _fallbackAsset),
  ];

  List<_StoreItem> get _roomEntryItems => [
    _StoreItem(name: 'Golden Car', price: 1000, asset: _altAsset),
    _StoreItem(name: 'Geen Car', price: 1300, asset: _fallbackAsset),
    _StoreItem(name: 'Ferari Car', price: 1300, asset: _fallbackAsset),
    _StoreItem(name: 'Gaming Car', price: 1000, asset: _altAsset),
    _StoreItem(name: 'Entry Car', price: 1300, asset: _fallbackAsset),
    _StoreItem(name: 'Flower', price: 1300, asset: _fallbackAsset),
    _StoreItem(name: 'Temple', price: 1200, asset: _altAsset),
    _StoreItem(name: 'Princess', price: 1500, asset: _fallbackAsset),
    _StoreItem(name: 'Regal Entry', price: 1700, asset: _fallbackAsset),
  ];

  // Party themes use icons primarily; asset is optional and can be a GIF if added later
  final List<IconData> _partyThemeIcons = const [
    Icons.celebration,
    Icons.cake,
    Icons.star,
    Icons.favorite,
    Icons.music_note,
    Icons.local_fire_department,
    Icons.diamond,
    Icons.flash_on,
    Icons.auto_awesome,
  ];

  List<_StoreItem> get _partyThemeItems => List.generate(
    9,
    (i) => _StoreItem(
      name: [
        'Celebrate',
        'Birthday',
        'Starry',
        'Romance',
        'Music',
        'Blaze',
        'Diamond',
        'Flash',
        'Awesome',
      ][i],
      price: 1000 + (i % 3) * 300,
      icon: _partyThemeIcons[i],
    ),
  );

  List<_StoreItem> get _itemsForCurrentTab {
    switch (selectedTabIndex) {
      case 0:
        return _frameItems;
      case 1:
        return _roomEntryItems;
      case 2:
      default:
        return _partyThemeItems;
    }
  }

  _StoreItem get _selectedItem => _itemsForCurrentTab[selectedItemIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background as shown in design
      body: Column(
        children: [
          // Showcase Section
          _buildShowcaseSection(),
          SizedBox(height: 20.h),

          // Purchase Section
          _buildPurchaseSection(),
          SizedBox(height: 20.h),

          // Tabs Section
          _buildTabsSection(),

          // Content Grid
          Expanded(child: _buildContentGrid()),
        ],
      ),
    );
  }

  Widget _buildShowcaseSection() {
    return Stack(
      children: [
        Container(
          height: 280.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: const Color(0xFF1A1A1A), // Dark showcase area as in design
          ),
          child: Stack(
            children: [
              // Pedestal / base showcase
              Image.asset(
                'assets/images/general/showcase_frame.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              // Selected item preview layered on top of the pedestal
              Center(
                child: SizedBox(
                  width: 220.w,
                  height: 180.h,
                  child: _buildStoreAssetWidget(
                    _selectedItem,
                    isShowcase: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        //Navigation back button
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

  Widget _buildPurchaseSection() {
    final item = _selectedItem;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // Title
              Text(
                item.name,
                style: const TextStyle(
                  color: Colors.black, // Black text on white background
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 8.h),

              // Subtitle
              Text(
                'Purchase with coin',
                style: TextStyle(
                  color: Colors.grey[600], // Grey text
                  fontSize: 16,
                ),
              ),
            ],
          ),
          // Buy Button
          GestureDetector(
            onTap: () => _showPurchaseDialog(item.name, item.price),
            child: Container(
              width: 120.w,
              height: 40.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8BA0)],
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: const Center(
                child: Text(
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

  Widget _buildTabsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        children: List.generate(
          tabNames.length,
          (index) => GestureDetector(
            onTap: () {
              setState(() {
                selectedTabIndex = index;
                selectedItemIndex = 0; // reset selection to first item
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              margin: EdgeInsets.only(right: 16.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selectedTabIndex == index
                        ? const Color(0xFFFF6B9D)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabNames[index],
                style: TextStyle(
                  color: selectedTabIndex == index
                      ? const Color(0xFFFF6B9D)
                      : Colors
                            .grey[600], // Changed from grey[400] to grey[600] for better contrast on white
                  fontSize: 16,
                  fontWeight: selectedTabIndex == index
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

  Widget _buildContentGrid() {
    return Container(
      margin: EdgeInsets.all(20.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16.h,
          crossAxisSpacing: 16.w,
          childAspectRatio: 0.8,
        ),
        itemCount: _itemsForCurrentTab.length,
        itemBuilder: (context, index) {
          return _buildStoreItem(index, _itemsForCurrentTab[index]);
        },
      ),
    );
  }

  Widget _buildStoreItem(int index, _StoreItem item) {
    final isSelected = index == selectedItemIndex;
    final isPartyTheme = selectedTabIndex == 2;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedItemIndex = index; // select & preview on showcase
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Changed from dark grey to white
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B9D) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ), // Light grey border
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
            // Item Image/Icon
            Expanded(
              flex: 3,
              child: Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  color:
                      Colors.grey[100], // Light grey background instead of dark
                ),
                child: Stack(
                  children: [
                    Center(
                      child: isPartyTheme
                          ? Icon(
                              item.icon ?? Icons.celebration,
                              size: 40.sp,
                              color: const Color(0xFFFF6B9D),
                            )
                          : SizedBox(
                              width: 60.w,
                              height: 60.h,
                              child: _buildStoreAssetWidget(item),
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
                        color: Colors.black, // Black text instead of white
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

  void _showPurchaseDialog(String itemName, int price) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // White background instead of dark
          title: Text(
            'Purchase $itemName',
            style: const TextStyle(color: Colors.black), // Black text
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Do you want to purchase this item for $price coins?',
                style: TextStyle(color: Colors.grey[600]), // Dark grey text
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
                    '$price',
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ), // Darker grey for better contrast
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handlePurchase(itemName, price);
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

  void _handlePurchase(String itemName, int price) {
    // TODO: Implement actual purchase logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully purchased $itemName for $price coins!'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }
}

// Simple value type for store catalog entries
class _StoreItem {
  final String name;
  final int price;
  final String? asset; // supports png/jpg/gif
  final IconData? icon; // used for party theme placeholder

  const _StoreItem({
    required this.name,
    required this.price,
    this.asset,
    this.icon,
  });

  bool get isAnimated =>
      (asset != null && asset!.toLowerCase().endsWith('.gif'));
}

// Renders a store asset robustly with fallback and GIF support
Widget _buildStoreAssetWidget(_StoreItem item, {bool isShowcase = false}) {
  if (item.asset == null || item.asset!.isEmpty) {
    return Icon(
      item.icon ?? Icons.emoji_objects,
      size: isShowcase ? 120.sp : 40.sp,
      color: const Color(0xFFFF6B9D),
    );
  }

  return Image.asset(
    item.asset!,
    fit: BoxFit.contain,
    // Image.asset plays GIFs automatically; errorBuilder provides a graceful fallback
    errorBuilder: (context, error, stackTrace) => Icon(
      item.icon ?? Icons.broken_image,
      size: isShowcase ? 120.sp : 40.sp,
      color: Colors.grey[400],
    ),
  );
}
