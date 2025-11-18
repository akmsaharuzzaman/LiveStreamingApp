import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/joined_user_model.dart';
import '../../../profile/presentation/widgets/user_profile_bottom_sheet.dart';

class ViewersListPage extends StatefulWidget {
  final List<JoinedUserModel> viewers;
  final String? hostUserId;
  final String? hostName;
  final String? hostAvatar;

  const ViewersListPage({super.key, required this.viewers, this.hostUserId, this.hostName, this.hostAvatar});

  @override
  State<ViewersListPage> createState() => _ViewersListPageState();
}

class _ViewersListPageState extends State<ViewersListPage> {
  late List<JoinedUserModel> displayedViewers;

  @override
  void initState() {
    super.initState();
    displayedViewers = List.from(widget.viewers);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total viewers including host if present
    int totalViewers = displayedViewers.length;
    if (widget.hostUserId != null) {
      totalViewers += 1; // Add host to count
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: Colors.transparent,
          elevation: 4,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Viewers ($totalViewers)',
            style: TextStyle(color: Colors.black, fontSize: 18.sp, fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD7CAFE), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
      body: totalViewers == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16.h),
                  Text(
                    'No viewers found',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              itemCount: totalViewers,
              itemBuilder: (context, index) {
                // Show host first if present, then viewers
                if (index == 0 && widget.hostUserId != null) {
                  return _buildHostItem();
                } else {
                  // Adjust index for viewers
                  int viewerIndex = widget.hostUserId != null ? index - 1 : index;
                  if (viewerIndex < displayedViewers.length) {
                    return _buildViewerItem(displayedViewers[viewerIndex]);
                  } else {
                    return const SizedBox.shrink();
                  }
                }
              },
            ),
    );
  }

  Widget _buildHostItem() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          // Profile Picture with Host indicator
          Stack(
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    widget.hostAvatar ?? 'https://i.pravatar.cc/150?u=${widget.hostUserId}',
                    width: 50.w,
                    height: 50.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
              // Host indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.videocam, color: Colors.white, size: 10.sp),
                ),
              ),
            ],
          ),

          SizedBox(width: 12.w),

          // User Info
          Expanded(
            child: InkWell(
              onTap: () {
                if (widget.hostUserId != null) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => UserProfileBottomSheet(userId: widget.hostUserId!),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name with Host badge
                  Row(
                    children: [
                      Text(
                        widget.hostName ?? 'Host',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10.r)),
                        child: Text(
                          'HOST',
                          style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  // Live status
                  Row(
                    children: [
                      Icon(Icons.radio_button_checked, color: Colors.red, size: 12.sp),
                      SizedBox(width: 4.w),
                      Text(
                        'Live',
                        style: TextStyle(fontSize: 12.sp, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerItem(JoinedUserModel viewer) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          // Profile Picture
          Stack(
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    viewer.avatar,
                    width: 50.w,
                    height: 50.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
              // Online indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(width: 12.w),

          // User Info
          Expanded(
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => UserProfileBottomSheet(userId: viewer.id),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    viewer.name,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  SizedBox(height: 4.h),
                  // Badges Row
                  Row(
                    children: [
                      // Level Badge
                      // Image.asset(
                      //   'assets/images/general/level_frame.png',
                      //   height: 20.w,
                      // ),
                      // Level Text with currentBackground and currentTag
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          (viewer.currentBackground != null)
                              ? Image.network(
                                  viewer.currentBackground!,
                                  fit: BoxFit.fill,
                                  height: 20.h,
                                  width: 56.w,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 20.h,
                                    width: 56.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.r),
                                      color: Colors.blue,
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 20.h,
                                  width: 56.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.r),
                                    color: Colors.blue,
                                  ),
                                ),
                          Positioned(
                            left: -10,
                            child: Row(
                              children: [
                                (viewer.currentTag != null)
                                    ? Image.network(
                                        viewer.currentTag!,
                                        fit: BoxFit.fill,
                                        height: 20.h,
                                        width: 20.w,
                                      )
                                    : SizedBox(width: 20.w),
                                SizedBox(width: 4.w),
                                Text(
                                  "Lv.${viewer.currentLevel ?? 0}",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14.sp),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 4.w),
                      // Show diamonds if viewer has sent gifts
                      // if (viewer.diamonds > 0)
                      //   Container(
                      //     padding: EdgeInsets.symmetric(
                      //       horizontal: 6.w,
                      //       vertical: 2.h,
                      //     ),
                      //     decoration: BoxDecoration(
                      //       color: Colors.blue.withValues(alpha: 0.8),
                      //       borderRadius: BorderRadius.circular(8.r),
                      //     ),
                      //     child: Row(
                      //       mainAxisSize: MainAxisSize.min,
                      //       children: [
                      //         Icon(
                      //           Icons.diamond,
                      //           color: Colors.white,
                      //           size: 12.sp,
                      //         ),
                      //         SizedBox(width: 2.w),
                      //         Text(
                      //           AppUtils.formatNumber(viewer.diamonds),
                      //           style: TextStyle(
                      //             fontSize: 10.sp,
                      //             color: Colors.white,
                      //             fontWeight: FontWeight.bold,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  // Online Status
                  Row(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 8.sp),
                      SizedBox(width: 4.w),
                      Text(
                        'Watching',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Gift count indicator
          // if (viewer.diamonds > 0)
          //   Container(
          //     padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          //     decoration: BoxDecoration(
          //       color: Color(0xFFF1F1F1),
          //       borderRadius: BorderRadius.circular(16.r),
          //     ),
          //     child: Text(
          //       '💎 ${AppUtils.formatNumber(viewer.diamonds)}',
          //       style: TextStyle(
          //         fontSize: 12.sp,
          //         fontWeight: FontWeight.w500,
          //         color: Color(0xFF825CB3),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}
