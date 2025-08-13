import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CallOverlayWidget extends StatelessWidget {
  final String? userImage;
  final String? userName;
  final String? userId;
  final VoidCallback? onDisconnect;
  final VoidCallback? onMute;
  final VoidCallback? onManage;

  const CallOverlayWidget({
    super.key,
    this.userImage,
    this.userName,
    this.userId,
    this.onDisconnect,
    this.onMute,
    this.onManage,
  });

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Info Header
            Container(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25.r,
                    backgroundImage: userImage != null
                        ? NetworkImage(userImage!)
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: userImage == null
                        ? Icon(
                            Icons.person,
                            size: 30.sp,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          userId ?? '',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Options List
            _buildOptionTile(
              icon: Icons.call_end,
              title: 'Disconnect Call',
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                onDisconnect?.call();
              },
            ),
            _buildOptionTile(
              icon: Icons.mic_off,
              title: 'Mute Call',
              iconColor: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                onMute?.call();
              },
            ),
            _buildOptionTile(
              icon: Icons.settings,
              title: 'Manage',
              iconColor: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                onManage?.call();
              },
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: iconColor, size: 20.sp),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptionsBottomSheet(context),
      child: Container(
        margin: EdgeInsets.only(bottom: 15.h),
        height: 100.h,
        width: 100.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.r),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: userImage != null
                    ? Image.network(
                        userImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: Icon(
                              Icons.person,
                              color: Colors.white54,
                              size: 40.sp,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: Icon(
                          Icons.person,
                          color: Colors.white54,
                          size: 40.sp,
                        ),
                      ),
              ),

              // Blur Overlay
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
              ),

              // Center Profile Circle
              Center(
                child: Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 2.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: userImage != null
                        ? Image.network(
                            userImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[600],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30.sp,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[600],
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30.sp,
                            ),
                          ),
                  ),
                ),
              ),

              // Online Indicator (optional)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  width: 12.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5.w),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
