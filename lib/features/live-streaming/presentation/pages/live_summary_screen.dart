import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class LiveSummaryScreen extends StatelessWidget {
  const LiveSummaryScreen({
    super.key,
    this.userName = "Md. Habibur",
    this.userId = "154154",
    this.earnedPoints = 0,
    this.newFollowers = 0,
    this.totalDuration = "55:10:05",
    this.userAvatar,
  });

  final String userName;
  final String userId;
  final int earnedPoints;
  final int newFollowers;
  final String totalDuration;
  final String? userAvatar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB568D6), // Purple
              Color(0xFF9FDEEA), // Light blue
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 80.h),

                // Profile Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 38.r,
                          backgroundImage: userAvatar != null
                              ? NetworkImage(userAvatar!)
                              : const AssetImage(
                                      'assets/images/new_images/profile.png',
                                    )
                                    as ImageProvider,
                          backgroundColor: Colors.grey[300],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // User Name
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // Badges Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBadge("LV17", const Color(0xFFFF69B4)),
                          SizedBox(width: 8.w),
                          _buildBadge("20", const Color(0xFF4285F4)),
                          SizedBox(width: 8.w),
                          _buildBadge("VIP", const Color(0xFFFFD700)),
                          SizedBox(width: 8.w),
                          _buildBadge("SVIP", const Color(0xFF2E2E2E)),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // User ID
                      Text(
                        "ID:$userId",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Stats Row
                      Row(
                        children: [
                          // Earned Points
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.monetization_on,
                              iconColor: const Color(0xFFB568D6),
                              title: "Earned Points",
                              value: earnedPoints.toString(),
                            ),
                          ),

                          SizedBox(width: 24.w),

                          // New Followers
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.person_add,
                              iconColor: const Color(0xFFB568D6),
                              title: "New followers",
                              value: newFollowers.toString(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Total Duration Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 20.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Duration",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20.sp,
                            color: Colors.black87,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            totalDuration,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8FA3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color backgroundColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
