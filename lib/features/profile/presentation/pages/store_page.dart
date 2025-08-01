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
  final List<String> tabNames = ['Frame', 'Room Entry', 'Party Theme'];

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
              Image.asset('assets/images/general/showcase_frame.png'),
              Center(
                child: Image.asset('assets/images/general/profile_frame.png'),
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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // Title
              const Text(
                'Noble Blaze',
                style: TextStyle(
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
              )
            ],
          ),
           // Buy Button
              Container(
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
        itemCount: 9, // Show 9 items for demo
        itemBuilder: (context, index) {
          return _buildStoreItem(index);
        },
      ),
    );
  }

  Widget _buildStoreItem(int index) {
    // Sample data for different items
    final List<Map<String, dynamic>> frameItems = [
      {
        'name': 'Noble Blaze',
        'price': 1000,
        'asset': 'assets/images/general/showcase_frame.png',
      },
      {
        'name': 'Magnificent D.',
        'price': 1300,
        'asset': 'assets/images/general/showcase_frame.png',
      },
      {
        'name': 'Grand regal H.',
        'price': 1300,
        'asset': 'assets/images/general/showcase_frame.png',
      },
      {
        'name': 'Noble Blaze',
        'price': 1000,
        'asset': 'assets/images/general/showcase_frame.png',
      },
      {
        'name': 'Magnificent D.',
        'price': 1300,
        'asset': 'assets/images/general/showcase_frame.png',
      },
      {
        'name': 'Grand regal H.',
        'price': 1300,
        'asset': 'assets/images/general/showcase_frame.png',
      },
      {
        'name': 'Elite Frame',
        'price': 1500,
        'asset': 'assets/images/general/showcase_frame.png',
      },
      {
        'name': 'Royal Frame',
        'price': 1800,
        'asset': 'assets/images/general/showcase_frame.png',
      },
      {
        'name': 'Diamond Frame',
        'price': 2000,
        'asset': 'assets/images/general/showcase_frame.png',
      },
    ];

    final List<IconData> partyThemeIcons = [
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

    final item = frameItems[index % frameItems.length];
    final isPartyTheme = selectedTabIndex == 2;

    return GestureDetector(
      onTap: () {
        _showPurchaseDialog(item['name'], item['price']);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Changed from dark grey to white
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
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
                child: Center(
                  child: isPartyTheme
                      ? Icon(
                          partyThemeIcons[index % partyThemeIcons.length],
                          size: 40.sp,
                          color: const Color(0xFFFF6B9D),
                        )
                      : Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(item['asset']),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
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
                      item['name'],
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
                          '${item['price']}',
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
