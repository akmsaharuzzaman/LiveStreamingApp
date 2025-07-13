import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/models/user_model.dart';
import '../../../../injection/injection.dart';
import '../../../../routing/app_router.dart';
import '../../data/models/friends_models.dart';
import '../../data/services/friends_api_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return _ProfileContent(user: state.user);
        }
        return const Center(child: Text('User not authenticated'));
      },
    );
  }
}

class _ProfileContent extends StatefulWidget {
  final UserModel user;

  const _ProfileContent({required this.user});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  bool isLoading = true;
  bool isFollowLoading = false;
  bool isLoadingCounts = true;
  // Follower count data
  FollowerCountResult? followerCounts;
  Future<void> _loadFollowerCounts() async {
    final friendsService = getIt<FriendsApiService>();

    try {
      final result = await friendsService.getFollowerAndFollowingCount(null);

      result.when(
        success: (data) {
          setState(() {
            followerCounts = data;
            isLoadingCounts = false;
          });
        },
        failure: (error) {
          setState(() {
            isLoadingCounts = false;
          });
          print('Error loading follower counts: $error');
        },
      );
    } catch (e) {
      setState(() {
        isLoadingCounts = false;
      });
      print('Error loading follower counts: $e');
    }
  }

  @override
  void initState() {
    _loadFollowerCounts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.centerLeft,
          colors: [Color(0xFFD7CAFE), Color(0xFFFFFFFF)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 42),
            // Top Icons (Edit and Settings)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    context.push(AppRoutes.profileUpdate);
                  },
                  child: Image.asset(
                    'assets/images/general/edit_icon.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                InkWell(
                  onTap: () {
                    context.push(AppRoutes.settings);
                  },
                  child: Image.asset(
                    'assets/images/general/settings_icon.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Profile Picture with Frame
            _buildProfileHeader(),

            const SizedBox(height: 16),

            // User Name
            Text(
              widget.user.name,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w400,
                color: Color(0xFF2D3142),
              ),
            ),

            const SizedBox(height: 8),

            // User ID and Location
            Text(
              'ID:${widget.user.id.substring(0, 6)} | Bangladesh', // Truncated ID
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

            const SizedBox(height: 20),

            // Stats Row (Gold and Diamonds)
            _buildStatsRow(),

            SizedBox(height: 10.h),
            // Divider
            Divider(color: const Color(0xFFCCCCCC), thickness: 1, height: 1),
            SizedBox(height: 20.h),

            // Friends/Followers/Following
            _buildSocialStats(),

            SizedBox(height: 20.h),

            // Profile Card Section
            _buildProfileCard(),
            SizedBox(height: 20.h),

            // Feature Icons Grid
            _buildFeatureGrid(context),

            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: 100.h,
      height: 100.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child:
            (widget.user.avatar != null ||
                widget.user.profilePictureUrl != null)
            ? Image.network(
                widget.user.avatar ?? widget.user.profilePictureUrl!,
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

  Widget _buildStatsRow() {
    final stats = widget.user.stats;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Gold/Stars
        Row(
          children: [
            SizedBox(width: 25.w),
            Image.asset(
              'assets/images/general/coin_icon.png',
              width: 25.w,
              height: 25.h,
            ),
            const SizedBox(width: 8),
            Text(
              stats?.stars.toString() ?? '100',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w400,
                color: Color(0xFF202020),
              ),
            ),
          ],
        ),

        //Devider
        Container(width: 1, height: 30, color: const Color(0xFFCCCCCC)),

        // Diamonds
        Row(
          children: [
            Image.asset(
              'assets/images/general/diamond_icon.png',
              width: 25.w,
              height: 25.h,
            ),
            const SizedBox(width: 8),
            Text(
              stats?.diamonds.toString() ?? '100',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w400,
                color: Color(0xFF202020),
              ),
            ),
            SizedBox(width: 25.w),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialStatItem(
          isLoadingCounts ? '...' : '${followerCounts?.friendshipCount ?? 0}',
          'Friends',
          () {
            // context.push('/friends-list/${widget.userId}?title=Friends');
          },
        ),
        Container(width: 1, height: 30, color: const Color(0xFFF1F1F1)),
        _buildSocialStatItem(
          isLoadingCounts ? '...' : '${followerCounts?.followerCount ?? 0}',
          'Followers',
          () {
            // context.push('/friends-list/${widget.userId}?title=Followers');
          },
        ),
        Container(width: 1, height: 30, color: const Color(0xFFF1F1F1)),
        _buildSocialStatItem(
          isLoadingCounts ? '...' : '${followerCounts?.followingCount ?? 0}',
          'Following',
          () {
            // context.push('/friends-list/${widget.userId}?title=Following');
          },
        ),
      ],
    );
  }

  Widget _buildSocialStatItem(String count, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }

  Widget _buildProfileCard() {
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
                  '*${widget.user.name.split(' ').first.toUpperCase()}*',
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

  Widget _buildFeatureGrid(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFeatureIcon(
              "assets/images/general/vip_icon.png",
              'VIP',
              context,
            ),
            _buildFeatureIcon(
              "assets/images/general/fan_club_icon.png",
              'Fan Club',
              context,
            ),
            _buildFeatureIcon(
              "assets/images/general/my_level_icon.png",
              'My Level',
              context,
            ),
            _buildFeatureIcon(
              "assets/images/general/my_agency_icon.png",
              'My Agency',
              context,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFeatureIcon(
              "assets/images/general/my_bag_icon.png",
              'My Bag',
              context,
            ),
            _buildFeatureIcon(
              "assets/images/general/live_tv_icon.png",
              'Live',
              context,
            ),
            _buildFeatureIcon(
              "assets/images/general/helping_icon.png",
              'Helping',
              context,
            ),
            _buildFeatureIcon(
              "assets/images/general/top_up_icon.png",
              'Top Up',
              context,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFeatureIcon(
              "assets/images/general/store_icon.png",
              'Store',
              context,
            ),
            _buildFeatureIcon(
              "assets/images/general/room_management_icon.png",
              'Room Management',
              context,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 4 - 20,
            ), // Empty space for alignment
            SizedBox(
              width: MediaQuery.of(context).size.width / 4 - 20,
            ), // Empty space for alignment
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureIcon(
    String iconPath,
    String label,
    BuildContext context,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 4 - 20,
      child: Column(
        children: [
          Image.asset(iconPath, width: 50.h, height: 50.h),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF202020),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
