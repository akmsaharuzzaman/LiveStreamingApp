import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/network/api_clients.dart';
import '../../../../injection/injection.dart';

class ViewUserProfile extends StatefulWidget {
  const ViewUserProfile({super.key, required this.userId});
  final String userId;

  @override
  State<ViewUserProfile> createState() => _ViewUserProfileState();
}

class _ViewUserProfileState extends State<ViewUserProfile> {
  UserModel? userProfile;
  bool isLoading = true;
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

  void _navigateToChat() {
    if (userProfile != null) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening chat with ${userProfile!.name}'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Handle error case
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start chat. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              // Handle more options
            },
          ),
        ],
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child:
            // Content
            isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? _buildErrorWidget()
            : userProfile != null
            ? _buildUserProfileContent(userProfile!)
            : const Center(child: Text('No user data available')),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacingM),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: UIConstants.spacingM),
            Text(
              'Error Loading Profile',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: UIConstants.spacingS),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: UIConstants.spacingM),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileContent(UserModel user) {
    return Stack(
      children: [
        SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
              ),
              child: Column(
                children: [
                  // Profile Picture with Frame
                  _buildProfileHeader(user),

                  const SizedBox(height: 16),

                  // User Name
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2D3142),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // User ID and Location
                  Text(
                    'ID:${user.id.substring(0, 6)} | Bangladesh', // Truncated ID
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF202020),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: 5.h),

                  // Status Message
                  const Text(
                    'Hey! WhatsApp',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF808080),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Level Badges
                  _buildLevelBadges(),
                  SizedBox(height: 20.h),

                  // Friends/Followers/Following
                  _buildSocialStats(),

                  SizedBox(height: 20.h),

                  // Profile Card Section
                  _buildProfileCard(user),
                  SizedBox(height: 20.h),
                  // Exapanable Tile
                  _buildExpandableTile(
                    'assets/images/general/baggage_icon.png',
                    'Baggage',
                    () {
                      // Handle baggage tap
                      print('Baggage tapped');
                    },
                  ),
                  // DividerLIne
                  Container(
                    height: 1,
                    color: const Color(0xFFF1F1F1),
                    margin: EdgeInsets.symmetric(vertical: 20.h),
                  ),
                  _buildExpandableTile(
                    'assets/images/general/black_badge_icon.png',
                    'Badges',
                    () {
                      // Handle baggage tap
                      print('Baggage tapped');
                    },
                  ),
                  // DividerLIne
                  Container(
                    height: 1,
                    color: const Color(0xFFF1F1F1),
                    margin: EdgeInsets.symmetric(vertical: 20.h),
                  ),
                  _buildMomentsGrid(),
                ],
              ),
            ),
          ),
        ),
        Positioned(right: 0, left: 0, bottom: 0, child: _buildActionButtons()),
      ],
    );
  }

  Widget _buildMomentsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Moments Title
        Text(
          'Moments',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF202020),
          ),
        ),
        SizedBox(height: 10.h),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8.h,
            crossAxisSpacing: 8.w,
            childAspectRatio:
                0.65, // Width:Height = 0.5 (height is twice the width)
          ),
          itemCount: 16,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Moment ${index + 1}',
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpandableTile(
    String iconPath,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(iconPath, width: 24, height: 24),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF202020),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      width: 100.h,
      height: 100.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: (user.avatar != null || user.profilePictureUrl != null)
            ? Image.network(
                user.avatar ?? user.profilePictureUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 100.h,
      height: 100.h,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF0F0F0),
      ),
      child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
    );
  }

  Widget _buildLevelBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Level 1 Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFFF8BA0)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Lv 1',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Yellow Badge (0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text(
                '🤍',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Text(
                '0',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Settings Icon Badge
        Image.asset(
          'assets/images/general/frame.png',
          width: 28,
          height: 28,
          color: const Color(0xFF2D3142),
        ),
      ],
    );
  }

  Widget _buildSocialStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialStatItem('0', 'Friends'),
        Container(width: 1, height: 30, color: const Color(0xFFF1F1F1)),
        _buildSocialStatItem('0', 'Followers'),
        Container(width: 1, height: 30, color: const Color(0xFFF1F1F1)),
        _buildSocialStatItem('0', 'Following'),
      ],
    );
  }

  Widget _buildSocialStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Color(0xFF000000),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Color(0xFF000000),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF82A3), Color(0xFF9BC7FB), Color(0xFFFF82A3)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Profile picture
          Image.asset('assets/images/general/hexagon_icon.png'),

          // CircleAvatar(
          //   radius: 20,
          //   backgroundImage:
          //       (user.avatar != null || user.profilePictureUrl != null)
          //       ? NetworkImage(user.avatar ?? user.profilePictureUrl!)
          //       : null,
          //   child: (user.avatar == null && user.profilePictureUrl == null)
          //       ? const Icon(Icons.person, color: Colors.white)
          //       : null,
          // ),
          const SizedBox(width: 12),

          // Name and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '*${user.name.split(' ').first.toUpperCase()}*',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),

          // Icons on the right
          Row(
            children: [
              Image.asset('assets/images/general/king_level.png'),
              SizedBox(width: 8.w),
              Image.asset('assets/images/general/total_badges_icon.png'),
              SizedBox(width: 8.w),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final relationship = userProfile!.relationship;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 60, top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Follow Button - matches the pink button in image
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: relationship?.myFollowing == true
                    ? Color(0xFF7C6C70)
                    : Color(0xFF7C6C70),
                gradient: relationship?.myFollowing == true
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFF82A3), Color(0xFFFF8BA0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Handle follow action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: Image.asset(
                  relationship?.myFollowing == true
                      ? 'assets/images/general/minus_icon.png'
                      : 'assets/images/general/plus_icon.png',
                  width: 16,
                  height: 16,
                  color: Colors.white,
                ),
                label: Text(
                  relationship?.myFollowing == true ? 'Unfollow' : 'Follow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Message Button - circular with message icon
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _navigateToChat(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: Image.asset(
                  'assets/images/general/message_icon.png',
                  width: 16,
                  height: 16,
                  color: Colors.grey[600],
                ),
                label: Text(
                  'Inbox',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
