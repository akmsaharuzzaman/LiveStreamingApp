import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_model.dart';

class BagPage extends StatelessWidget {
  final UserModel user;

  const BagPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B5CF6), // Purple
              Color(0xFFEC4899), // Pink
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              SizedBox(height: 40.h),

              // User Profile with Frame
              _buildUserProfile(),

              SizedBox(height: 30.h),

              // VIP Status
              _buildVipStatus(),

              // Content area (can be expanded later)
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 40.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4FF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Bag Content Area',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
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
      height: 160.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Profile Frame
          Image.asset(
            'assets/images/general/profile_frame.png',
            width: 160.w,
            height: 160.w,
            fit: BoxFit.contain,
          ),
          // User Image
          Positioned(
            child: Container(
              width: 100.w,
              height: 100.w,
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

  Widget _buildVipStatus() {
    // Get user role or default to VIP
    final userRole = user.userRole.toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        userRole,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
