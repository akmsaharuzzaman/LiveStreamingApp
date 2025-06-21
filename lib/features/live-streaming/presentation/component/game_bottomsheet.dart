import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'web_game_bottomsheet.dart';

void showGameBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return const GameBottomSheet();
    },
  );
}

class GameBottomSheet extends StatelessWidget {
  const GameBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400.h,
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

          // Stream Duration
          Container(
            margin: EdgeInsets.symmetric(vertical: 16.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'Stream Duration: 000:00:00',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Game Options Row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGameOption(
                  icon: Icons.gamepad,
                  label: 'Greedy Stars',
                  onTap: () {
                    Navigator.pop(context);
                    // Open Greedy Stars web game
                    showWebGameBottomSheet(
                      context,
                      gameUrl:
                          'http://147.93.103.135:8001/game/?spain_time=30&profit=0&user_id=2ufXoAdqAY',
                      gameTitle: 'Greedy Stars',
                      userId:
                          '2ufXoAdqAY', // You can replace this with actual user ID
                    );
                  },
                ),
                _buildGameOption(
                  icon: Icons.gamepad_outlined,
                  label: 'Fruit Loops',
                  onTap: () {
                    Navigator.pop(context);
                    // You can add another game URL here or show coming soon
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fruit Loops - Coming Soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Control Options Grid
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 0.8,
                children: [
                  _buildControlOption(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () {
                      Navigator.pop(context);
                      // Handle share
                    },
                  ),
                  _buildControlOption(
                    icon: Icons.account_balance_wallet,
                    label: 'Coin Bag',
                    onTap: () {
                      Navigator.pop(context);
                      // Handle coin bag
                    },
                  ),
                  _buildControlOption(
                    icon: Icons.emoji_emotions,
                    label: 'Sticker',
                    onTap: () {
                      Navigator.pop(context);
                      // Handle sticker
                    },
                  ),
                  _buildControlOption(
                    icon: Icons.flip_camera_ios,
                    label: 'Flip Camera',
                    onTap: () {
                      Navigator.pop(context);
                      // Handle flip camera
                    },
                  ),
                  _buildControlOption(
                    icon: Icons.auto_fix_high,
                    label: 'Effect',
                    onTap: () {
                      Navigator.pop(context);
                      // Handle effect
                    },
                  ),
                  _buildControlOption(
                    icon: Icons.inbox,
                    label: 'Inbox',
                    onTap: () {
                      Navigator.pop(context);
                      // Handle inbox
                    },
                  ),
                  _buildControlOption(
                    icon: Icons.flash_on,
                    label: 'Flash on',
                    onTap: () {
                      Navigator.pop(context);
                      // Handle flash
                    },
                  ),
                  _buildControlOption(
                    icon: Icons.face_retouching_natural,
                    label: 'Beauty Camera',
                    onTap: () {
                      Navigator.pop(context);
                      // Handle beauty camera
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120.w,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[700]!, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: Colors.white, size: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
