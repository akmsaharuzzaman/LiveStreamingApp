import 'package:dlstarlive/core/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_clients.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../injection/injection.dart';

class UserProfileBottomSheet extends StatefulWidget {
  final String userId;

  const UserProfileBottomSheet({super.key, required this.userId});

  @override
  State<UserProfileBottomSheet> createState() => _UserProfileBottomSheetState();
}

class _UserProfileBottomSheetState extends State<UserProfileBottomSheet> {
  UserModel? userProfile;
  bool isLoading = true;
  bool isFollowLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final userApiClient = getIt<UserApiClient>();
      final response = await userApiClient.getUserById(widget.userId);

      if (response.isSuccess && response.data != null) {
        final userData = response.data!['result'] as Map<String, dynamic>;
        setState(() {
          try {
            userProfile = UserModel.fromJson(userData);
          } catch (e) {
            errorMessage = 'Error parsing user data: $e';
          }
          userProfile = UserModel.fromJson(userData);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.message ?? 'Failed to load user profile';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _handleFollowToggle() async {
    if (userProfile == null || isFollowLoading) return;

    setState(() {
      isFollowLoading = true;
    });

    try {
      final userApiClient = getIt<UserApiClient>();
      final isCurrentlyFollowing = userProfile!.relationship?.myFollowing == true;

      ApiResponse<Map<String, dynamic>> response;

      if (isCurrentlyFollowing) {
        response = await userApiClient.unfollowUser(userProfile!.id);
      } else {
        response = await userApiClient.followUser(userProfile!.id);
      }

      if (response.isSuccess) {
        // Update the local state
        setState(() {
          userProfile = userProfile!.copyWith(
            relationship: userProfile!.relationship?.copyWith(myFollowing: !isCurrentlyFollowing),
          );
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyFollowing ? 'Unfollowed ${userProfile!.name}' : 'Following ${userProfile!.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to update follow status'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        isFollowLoading = false;
      });
    }
  }

  void _navigateToChat() {
    if (userProfile != null) {
      // Close the bottom sheet first
      Navigator.of(context).pop();

      // Navigate directly to chat conversation with this user
      // Pass user information as extra data for better UX
      context.push(
        '/chat-details/${userProfile!.id}',
        extra: {
          'userName': userProfile!.name,
          'userAvatar': userProfile!.avatar ?? userProfile!.profilePictureUrl,
          'userEmail': userProfile!.email,
        },
      );

      // Optional: Show a quick feedback message
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Opening chat with ${userProfile!.name}'),
      //     duration: const Duration(seconds: 1),
      //     backgroundColor: Colors.green,
      //   ),
      // );
    } else {
      // Handle error case
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start chat. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * .6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)), // Increased radius
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 16.r, offset: Offset(0, -4))],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Content
              Expanded(
                child: isLoading
                    ? Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : errorMessage != null
                    ? _buildErrorWidget()
                    : userProfile != null
                    ? _buildUserProfileContent()
                    : Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
                        child: const Center(child: Text('No user data available')),
                      ),
              ),
            ],
          ),

          Positioned(
            top: 16.h,
            right: 16.w,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                'assets/images/general/cross_icon.png',
                width: 25.w,
                height: 25.h,
                color: const Color(0xFF2D3142),
              ),
            ),
          ),
          if (userProfile != null)
            Positioned(
              top: 10.h,
              left: 16.w,
              child: TextButton(onPressed: () {}, child: Text("Report")),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingM),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.h, color: Colors.red),
              SizedBox(height: UIConstants.spacingM.h),
              Text(
                'Error Loading Profile',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: UIConstants.spacingS.h),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: UIConstants.spacingM.h),
              ElevatedButton(onPressed: _loadUserProfile, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileContent() {
    return Column(
      children: [
        // Profile Header with background
        _buildProfileHeader(),
        SizedBox(height: 10.h),

        // User Achievements
        _buildAchievements(),
        SizedBox(height: 10.h),
        _buildStats(),
        SizedBox(height: 25.h),
        _buildFanBadges(),
        SizedBox(height: 25.h),

        // Action Buttons
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: _buildActionButtons(),
        ),

        // Add some spacing at bottom
        Spacer(),
      ],
    );
  }

  Widget _buildFanBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fan Badge
        Image.asset('assets/images/general/badges_card.png', height: 80.h),
        const SizedBox(width: 16),
        // Fan Badge
        Image.asset('assets/images/general/top_fan_card.png', height: 80.h),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fans
        Column(
          children: [
            Text(
              "0",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.sp, color: Color(0xFF2D3142)),
            ),
            Text(
              "Fans",
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16.sp, color: Color(0xFF2D3142)),
            ),
          ],
        ),
        SizedBox(width: 50.w),

        // Likes
        Column(
          children: [
            Text(
              "0",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.sp, color: Color(0xFF2D3142)),
            ),
            SizedBox(height: 4.h),
            Text(
              "Likes",
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16.sp, color: Color(0xFF2D3142)),
            ),
          ],
        ),
        SizedBox(width: 50.w),

        // Country
        Column(
          children: [
            Image.asset('assets/images/general/bd_flag.png', height: 25.h),
            Text(
              "Bangladesh",
              style: TextStyle(fontSize: 14.sp, color: Color(0xFF2D3142)),
            ),
          ],
        ),
        SizedBox(width: 16.w),
      ],
    );
  }

  Widget _buildAchievements() {
    if (userProfile == null) {
      return const SizedBox.shrink();
    }

    // Collect role-based badges
    List<Widget> badges = [];

    // Age Badge
    if (userProfile!.userRole == 'age') {
      badges.add(Image.asset('assets/images/general/age_tag.png', height: 20.h));
    }

    // Coin Badge
    if (userProfile!.userRole == 'coin') {
      badges.add(Image.asset('assets/images/general/coin_tag.png', height: 20.h));
    }

    // VIP Badge
    if (userProfile!.userRole == 'vip') {
      badges.add(Image.asset('assets/images/general/vip_tag.png', height: 20.h));
    }

    // SVIP Badge
    if (userProfile!.userRole == 'svip') {
      badges.add(Image.asset('assets/images/general/svip_tag.png', height: 20.h));
    }

    // Host Badge
    if (userProfile!.userRole == 'host') {
      badges.add(Image.asset('assets/images/general/host_tag.png', height: 20.h));
    }

    // Agent Badge
    if (userProfile!.userRole == 'agent') {
      badges.add(Image.asset('assets/images/general/agent_tag.png', height: 20.h));
    }

    // Re Seller Badge
    if (userProfile!.userRole == 're_seller') {
      badges.add(Image.asset('assets/images/general/re_seller_tag.png', height: 20.h));
    }

    // Admin Badge
    if (userProfile!.userRole == 'admin') {
      badges.add(Image.asset('assets/images/general/super_admin_frame.png', height: 20.h));
    }

    // If no specific role badges, show default level badge
    // if (badges.isEmpty) {
    //   badges.add(Image.asset('assets/images/general/level_frame.png', height: 20.h));
    // }

    // Add level badge if level is greater than 0
    if (userProfile!.level! > 0) {
      badges.add(
        Stack(
          clipBehavior: Clip.none,
          children: [
            (userProfile!.currentLevelBackground != null && userProfile!.currentLevelBackground!.isNotEmpty)
                ? Image.network(userProfile!.currentLevelBackground!, fit: BoxFit.fill, height: 20.h, width: 56.w)
                : Container(
                    height: 20.h,
                    width: 56.w,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: Colors.blue),
                  ),
            Positioned(
              left: -10,
              child: Row(
                children: [
                  (userProfile!.currentLevelTag != null && userProfile!.currentLevelTag!.isNotEmpty)
                      ? Image.network(userProfile!.currentLevelTag!, fit: BoxFit.fill, height: 20.h, width: 20.w)
                      : Text(
                          "Lvl",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14.sp),
                        ),
                  SizedBox(width: 4.w),
                  Text(
                    "Lv.${userProfile!.level}",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Wrap(alignment: WrapAlignment.center, spacing: 4.w, runSpacing: 8.h, children: badges),
    );
  }

  Widget _buildProfileHeader() {
    return InkWell(
      onTap: () {
        if (userProfile != null) {
          context.pushNamed('viewProfile', queryParameters: {'userId': userProfile!.id});
        }
        context.pop(); // Close the bottom sheet
      },
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F3FF), // Light purple background
              Color(0xFFFFFFFF), // White
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 50.h),

            // Profile Picture with Frame
            Stack(
              alignment: Alignment.center,
              children: [
                // Profile Picture
                Container(
                  width: 72.w,
                  height: 72.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: userProfile!.avatar != null
                        ? Image.network(
                            userProfile!.avatar!,
                            width: 72.w,
                            height: 72.h,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                          )
                        : _buildDefaultAvatar(),
                  ),
                ),
                // Profile frame forground
                // Image.asset(
                //   'assets/images/general/profile_frame.png',
                //   width: 120.w,
                //   height: 120.h,
                //   fit: BoxFit.contain,
                // ),
                SizedBox(width: double.infinity),
                Positioned(
                  top: 10.h, // Adjusted position forground desable that why it's 10 from 40
                  right: 50.w,
                  child: Image.asset(
                    'assets/images/general/car_frame.png',
                    width: 65.w,
                    height: 65.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // User Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userProfile!.name,
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w400, color: Color(0xFF202020)),
                ),
                SizedBox(width: 8.w),
                Image.asset('assets/images/general/gender_male_icon.png', width: 25.w, height: 25.h),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 80.w,
      height: 80.h,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF0F0F0)),
      child: Icon(Icons.person, size: 40.sp, color: Colors.grey[600]),
    );
  }

  Widget _buildActionButtons() {
    final relationship = userProfile!.relationship;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Follow Button - matches the pink button in image
        Expanded(
          child: Container(
            height: 44.h,
            decoration: BoxDecoration(
              gradient: relationship?.myFollowing == true
                  ? const LinearGradient(
                      colors: [Color(0xFF7C6C70), Color(0xFF7C6C70)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFF8BA0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: ElevatedButton.icon(
              onPressed: isFollowLoading ? null : _handleFollowToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              icon: isFollowLoading
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Image.asset(
                      relationship?.myFollowing == true
                          ? 'assets/images/general/minus_icon.png'
                          : 'assets/images/general/plus_icon.png',
                      width: 16.w,
                      height: 16.h,
                      color: Colors.white,
                    ),
              label: Text(
                isFollowLoading ? 'Loading...' : (relationship?.myFollowing == true ? 'Unfollow' : 'Follow'),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.sp),
              ),
            ),
          ),
        ),

        SizedBox(width: 12.w),

        // Gift Button - circular with gift icon
        Container(
          width: 44.w,
          height: 44.h,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2.w),
          ),
          child: IconButton(
            onPressed: () {
              // Handle gift action
            },
            icon: Image.asset('assets/images/general/gift_icon.png', width: 40.w, height: 40.h),
            padding: EdgeInsets.zero,
          ),
        ),

        SizedBox(width: 12.w),

        // Message Button - circular with message icon
        Expanded(
          child: Container(
            height: 44.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey[300]!, width: 2.w),
            ),
            child: ElevatedButton.icon(
              onPressed: _navigateToChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              icon: Image.asset(
                'assets/images/general/message_icon.png',
                width: 16.w,
                height: 16.h,
                color: Colors.grey[600],
              ),
              label: Text(
                'Inbox',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 14.sp),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
