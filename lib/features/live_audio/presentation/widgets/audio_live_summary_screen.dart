import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AudioLiveSummaryScreen extends StatelessWidget {
  final String userName;
  final String userId;
  final String? userAvatar;

  const AudioLiveSummaryScreen({super.key, this.userName = "Md. Habibur", this.userId = "154154", this.userAvatar});

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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar
                            SizedBox(height: 40.h),

                            // User Name
                            Text(
                              userName,
                              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w400, color: Colors.black87),
                            ),

                            SizedBox(height: 12.h),

                            // Badges Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset("assets/icons/level_badge.png", height: 18.h),
                                SizedBox(width: 8.w),
                                Image.asset("assets/icons/host_level.png", height: 18.h),
                                SizedBox(width: 8.w),
                                Image.asset("assets/icons/mc_icon.png", height: 18.h),
                                SizedBox(width: 8.w),
                                Image.asset("assets/icons/svip_icon.png", height: 18.h),
                              ],
                            ),

                            SizedBox(height: 16.h),

                            // User ID
                            Text(
                              "ID:$userId",
                              style: TextStyle(fontSize: 15.sp, color: Colors.grey[600], fontWeight: FontWeight.w400),
                            ),

                            SizedBox(height: 24.h),

                            // Live Stream End Message
                            Text(
                              "Live Stream Ended",
                              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 0,
                      child: Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 38.r,
                          backgroundImage: userAvatar != null ? NetworkImage(userAvatar!) : null,
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF85A3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600),
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
}
