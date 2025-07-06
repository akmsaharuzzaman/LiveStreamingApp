import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showGiftBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return const GiftBottomSheet();
    },
  );
}

class GiftBottomSheet extends StatefulWidget {
  const GiftBottomSheet({super.key});

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedGiftIndex = -1;
  int _giftQuantity = 1;
  int _currentBalance = 15100;

  final List<String> _tabs = ['Recent', 'Hot', 'SVIP', 'Nobel', 'Package'];

  final List<Map<String, dynamic>> _gifts = [
    {'name': 'Pink rose', 'price': 99, 'image': '🌸', 'category': 'Recent'},
    {'name': 'Rose', 'price': 9, 'image': '🌹', 'category': 'Hot'},
    {'name': 'Love', 'price': 1, 'image': '❤️', 'category': 'Hot'},
    {'name': 'Pink rose', 'price': 99, 'image': '👑', 'category': 'SVIP'},
    {'name': 'Pink rose', 'price': 9, 'image': '🧸', 'category': 'Recent'},
    {'name': 'Pink rose', 'price': 1, 'image': '🎊', 'category': 'Package'},
    {'name': 'Car', 'price': 999, 'image': '🚗', 'category': 'Nobel'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // User avatars and close button
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // User avatars
                Row(
                  children: [
                    _buildUserAvatar('https://picsum.photos/40/40?random=1'),
                    SizedBox(width: 8.w),
                    _buildUserAvatar('https://picsum.photos/40/40?random=2'),
                    SizedBox(width: 8.w),
                    _buildUserAvatar('https://picsum.photos/40/40?random=3'),
                    SizedBox(width: 8.w),
                    Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3E),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'All',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3E),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 20.sp),
                  ),
                ),
              ],
            ),
          ),

          // Level progress bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'LV.1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                    child: LinearProgressIndicator(
                      value: 0.3,
                      backgroundColor: Colors.grey[600],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFE91E63),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'LV.2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Level up text
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              'Send this gift to receive 50k level up',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ),

          // Tabs
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFFE91E63),
              indicatorWeight: 2,
              labelColor: const Color(0xFFE91E63),
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),

          // Gift grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((category) {
                final categoryGifts = _gifts
                    .where((gift) => gift['category'] == category)
                    .toList();
                return _buildGiftGrid(categoryGifts);
              }).toList(),
            ),
          ),

          // Bottom section with quantity and send button
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                // Quantity selector
                Container(
                  width: 80.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_giftQuantity > 1) {
                            setState(() {
                              _giftQuantity--;
                            });
                          }
                        },
                        child: Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                      Text(
                        '$_giftQuantity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _giftQuantity++;
                          });
                        },
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 16.w),

                // Balance
                Row(
                  children: [
                    Container(
                      width: 20.w,
                      height: 20.h,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 12.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '$_currentBalance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Send button
                GestureDetector(
                  onTap: _selectedGiftIndex >= 0 ? _sendGift : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedGiftIndex >= 0
                          ? const Color(0xFFE91E63)
                          : Colors.grey[600],
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Send',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String imageUrl) {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _buildGiftGrid(List<Map<String, dynamic>> gifts) {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.8,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        final isSelected = _selectedGiftIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedGiftIndex = index;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE91E63).withOpacity(0.2)
                  : const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE91E63)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(gift['image'], style: TextStyle(fontSize: 32.sp)),
                SizedBox(height: 4.h),
                Text(
                  gift['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.diamond, color: Colors.blue, size: 10.sp),
                    SizedBox(width: 2.w),
                    Text(
                      '${gift['price']}',
                      style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendGift() {
    if (_selectedGiftIndex >= 0) {
      final selectedGift = _gifts[_selectedGiftIndex];
      final totalCost = (selectedGift['price'] as int) * _giftQuantity;

      if (totalCost <= _currentBalance) {
        setState(() {
          _currentBalance -= totalCost;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sent ${selectedGift['name']} x$_giftQuantity!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFE91E63),
            duration: const Duration(seconds: 2),
          ),
        );

        // Reset selection
        setState(() {
          _selectedGiftIndex = -1;
          _giftQuantity = 1;
        });

        // Close bottom sheet after a delay
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pop(context);
        });
      } else {
        // Show insufficient balance message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insufficient balance!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
