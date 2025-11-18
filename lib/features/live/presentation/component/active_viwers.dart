import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/network/models/joined_user_model.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../profile/presentation/widgets/user_profile_bottom_sheet.dart';
import '../pages/viewers_list_page.dart';

class ActiveViewers extends StatelessWidget {
  const ActiveViewers({
    super.key,
    required this.activeUserList,
    this.hostUserId,
    this.hostName,
    this.hostAvatar,
  });

  final List<JoinedUserModel> activeUserList;
  final String? hostUserId;
  final String? hostName;
  final String? hostAvatar;

  @override
  Widget build(BuildContext context) {
    bool isLarge = MediaQuery.of(context).size.width > 400.w;
    int maxVisible = isLarge ? 3 : 2;
    List visibleUsers = activeUserList.take(maxVisible).toList();
    return Row(
      children: [
        for (var user in visibleUsers)
          Row(
            children: [
              SizedBox(width: 6.w),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        UserProfileBottomSheet(userId: user.id),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(80.r),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        child: Image.network(user.avatar, fit: BoxFit.cover),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha((255 * 0.58).toInt()),
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          child: Center(
                            child: Text(
                              AppUtils.formatNumber(user.diamonds ?? 0),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

        if (activeUserList.isEmpty)
          SizedBox.shrink()
        else
          Transform.translate(
            offset: Offset(-6.w, 0),
            child: GestureDetector(
              onTap: () {
                // Navigate to viewers list page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ViewersListPage(
                      viewers: activeUserList,
                      hostUserId: hostUserId,
                      hostName: hostName,
                      hostAvatar: hostAvatar,
                    ),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Color(0xff888686),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activeUserList.length.toString(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 16.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
