import 'package:dlstarlive/core/network/models/call_request_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CallManageBottomSheet extends StatefulWidget {
  const CallManageBottomSheet({
    super.key,
    required this.callers,
    required this.onKickUser,
    required this.onAcceptCall,
    required this.onRejectCall,
    required this.inCallList,
  });
  final List<CallRequestList> callers;
  final List<String> inCallList;
  final void Function(String userId) onKickUser;
  final void Function(String userId) onAcceptCall;
  final void Function(String userId) onRejectCall;

  @override
  State<CallManageBottomSheet> createState() => _CallManageBottomSheetState();
}

class _CallManageBottomSheetState extends State<CallManageBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.60.h,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with close button
          _buildHeader(),

          // Tab bar
          _buildTabBar(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildInCallTab(), _buildCallRequestTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Handle bar centered
          Expanded(
            child: Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
          ),

          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Icon(
                Icons.close,
                size: 24.sp,
                color: const Color(0xFF2D3142),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25.r),
          color: const Color(0xFFFF6B9D), // Pink color from image
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF8B8B8B),
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'In Call'),
          Tab(text: 'Call request'),
        ],
      ),
    );
  }

  Widget _buildInCallTab() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          // User requesting call
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.inCallList.length,
            itemBuilder: (context, index) {
              final caller = widget.inCallList[index];
              return _buildUserItem(
                userId: caller,
                name: caller,
                profileImage: 'assets/images/image_placeholder.png',
                showKickButton: true,
              );
            },
          ),
          SizedBox(height: 16.h),

          // Add more users as needed
          // You can add more _buildUserItem widgets here for other users in call
        ],
      ),
    );
  }

  Widget _buildCallRequestTab() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),

          // User requesting call
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.callers.length,
            itemBuilder: (context, index) {
              final caller = widget.callers[index];
              return _buildUserItem(
                userId: caller.userDetails.id,
                name: caller.userDetails.name,
                profileImage:
                    caller.userDetails.avatar ??
                    'assets/images/image_placeholder.png',
                showCallActions: true,
              );
            },
          ),

          SizedBox(height: 16.h),

          // Add more users as needed
          // You can add more _buildUserItem widgets here for other call requests
        ],
      ),
    );
  }

  Widget _buildUserItem({
    required String userId,
    required String name,
    required String profileImage,
    bool showKickButton = false,
    bool showCallActions = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
      ),
      child: Row(
        children: [
          // Profile image
          Container(
            width: 48.w,
            height: 48.h,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: Image.network(
                profileImage,
                width: 48.w,
                height: 48.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE0E0E0),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 24.sp,
                      color: const Color(0xFF8B8B8B),
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // Name
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2D3142),
              ),
            ),
          ),

          // Action buttons
          if (showKickButton) ...[
            GestureDetector(
              onTap: () => widget.onKickUser(userId),
              child: Image.asset(
                'assets/images/general/kick_icon.png',
                width: 20.w,
                height: 20.h,
                fit: BoxFit.cover,
              ),
            ),
          ],

          if (showCallActions) ...[
            // Reject button
            GestureDetector(
              onTap: () => widget.onRejectCall(userId),
              child: Image.asset(
                'assets/images/general/cross_icon.png',
                width: 20.w,
                height: 20.h,
                fit: BoxFit.cover,
              ),
            ),

            SizedBox(width: 12.w),

            // Accept button
            GestureDetector(
              onTap: () => widget.onAcceptCall(userId),
              child: Image.asset(
                'assets/images/general/tick_icon.png',
                width: 20.w,
                height: 20.h,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
