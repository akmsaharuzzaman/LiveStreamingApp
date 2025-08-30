import 'package:dlstarlive/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dlstarlive/features/reels/custom_package/reels_viewer.dart'
    as reels_viewer;
import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/auth/auth_bloc_adapter.dart';
import '../../../../injection/injection.dart';
import '../../../../routing/app_router.dart';
import '../../data/models/friends_models.dart';
import '../../data/services/friends_api_service.dart';
import '../../../newsfeed/data/datasources/post_service.dart';
import '../../../newsfeed/data/models/post_response_model.dart';
import '../../../newsfeed/presentation/widgets/api_post_container.dart';
import '../../../reels/data/services/reels_service.dart';
import '../../../reels/data/models/reel_response_model.dart';
import '../../../reels/data/models/reel_api_response_model.dart';
import '../../../reels/presentation/utils/reel_mapper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Refresh user profile data when ProfilePage is created
    _refreshUserProfile();
  }

  void _refreshUserProfile() {
    // Trigger auth refresh to get latest user data from /api/auth/my-profile
    final authBloc = context.read<AuthBloc>();
    authBloc.add(const AuthCheckStatusEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return _ProfileContent(user: state.user);
        } else if (state is AuthLoading) {
          // Show loading indicator when auth is refreshing
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Refreshing profile...'),
              ],
            ),
          );
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

  // Posts data
  late PostService _postService;
  List<PostModel> userPosts = [];
  bool isLoadingPosts = true;
  String? postsErrorMessage;
  int _currentPage = 1;

  // Reels data
  late ReelsService _reelsService;
  List<ReelApiModel> userReels = [];
  bool isLoadingReels = true;
  String? reelsErrorMessage;
  int _currentReelsPage = 1;
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
    super.initState();
    _postService = PostService(ApiService.instance, AuthBlocAdapter(context));
    _reelsService = ReelsService(ApiService.instance, AuthBlocAdapter(context));
    _loadInitialData();
  }

  @override
  void didUpdateWidget(_ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If user data changed, refresh follower counts (important social stats)
    if (oldWidget.user.id != widget.user.id) {
      _refreshImportantData();
    }
  }

  void _loadInitialData() {
    _loadFollowerCounts();
    _loadUserPosts();
    _loadUserReels();
  }

  /// Refresh only important data (follower counts, not posts/reels)
  void _refreshImportantData() {
    debugPrint('🔄 Refreshing important profile data (follower counts)');
    _loadFollowerCounts();
  }

  /// Public method to refresh all data - can be called from parent
  void refreshData() {
    setState(() {
      isLoadingCounts = true;
      isLoadingPosts = true;
      isLoadingReels = true;
      // Reset page counters
      _currentPage = 1;
      _currentReelsPage = 1;
      // Clear existing data
      userPosts.clear();
      userReels.clear();
      followerCounts = null;
    });

    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Stack(
        children: [
          Column(
            children: [
              // Cover Photo and Top Icons
              Stack(
                children: [
                  (widget.user.coverPicture != null)
                      ? Container(
                          width: double.infinity,
                          height: 170.h,
                          decoration: const BoxDecoration(color: Colors.white),
                          child: Image.network(
                            widget.user.coverPicture ?? '',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          height: 170.h,
                          width: double.infinity,
                          color: Color(0xFF888686),
                          child: Center(
                            child: Text(
                              'No Cover Photo',
                              style: TextStyle(color: Colors.white, fontSize: 16.sp),
                            ),
                          ),
                        ),
                  Positioned.fill(
                    // top: 10.h,
                    // left: 20.w,
                    bottom: 70.h,
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Spacer(),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,

                            onTap: () {
                              context.push(AppRoutes.profileUpdate);
                            },
                            child: Image.asset(
                              'assets/images/general/edit_icon.png',
                              width: 24.w,
                              height: 24.h,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.user.userRole == 'admin')
                    Positioned.fill(
                      top: 125.h,
                      left: MediaQuery.of(context).size.width - 160.w,
                      // bottom: 100.h,
                      child: Image.asset(
                        "assets/images/general/super_admin_frame.png",
                        height: 26.h,
                      ),
                    ),
                ],
              ),

              // Content section with padding for overlapping profile picture
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.centerLeft,
                    colors: [Color(0xFFD7CAFE), Color(0xFFFFFFFF)],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: 50.h, left: 20.w, right: 20.w),
                  child: Column(
                    children: [
                      // Space and layout for profile picture with user info
                      SizedBox(height: 36.h),

                      // Profile info section - positioned next to profile picture
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Space for the overlapping profile picture
                          // SizedBox(width: 110.w),

                          // User information positioned to the right of profile
                          Expanded(child: _buildTagsWidgetRow()),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // Friends/Followers/Following
                      _buildSocialStats(),

                      SizedBox(height: 20.h),

                      // Stats Row (Gold and Diamonds)
                      _buildStatsRow(),

                      SizedBox(height: 10.h),

                      // Profile Card Section
                      _buildProfileCard(),
                      SizedBox(height: 20.h),

                      // Feature Icons Grid
                      _buildFeatureGrid(context),

                      SizedBox(height: 20.h),

                      // Reels and Posts Section
                      _buildReelsAndPostsSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Overlapping Profile Picture
          Positioned(
            top: 120.h, // Position to overlap cover photo and content
            left: 25.w, // Left position closer to left edge
            child: _buildOverlappingProfilePicture(),
          ),
          //Build Overlaping UserInformation
          Positioned(
            top: 160.h, // Position to overlap cover photo and content
            left: 140.w, // Left position closer to left edge
            child: _buildOverlapingUserInformation(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlapingUserInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        // User Name
        Text(
          widget.user.name,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),

        SizedBox(height: 12.h),

        // User ID and Super Admin
        Row(
          children: [
            Row(
              children: [
                Text(
                  'ID:${widget.user.id.substring(0, 6)}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF202020),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 6.w),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.user.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User ID copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy,
                    size: 18.sp,
                    color: const Color(0xFF202020),
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              width: 4.w,
              height: 4.h,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              widget.user.userRole.toUpperCase(),
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF1B706A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverlappingProfilePicture() {
    return Container(
      width: 100.w,
      height: 100.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child:
            (widget.user.avatar != null ||
                widget.user.profilePictureUrl != null)
            ? Image.network(
                widget.user.avatar ?? widget.user.profilePictureUrl!,
                width: 100.w,
                height: 100.h,
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
      width: 100.w,
      height: 100.h,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF0F0F0),
      ),
      child: Icon(Icons.person, size: 40.sp, color: Colors.grey[600]),
    );
  }

  Widget _buildTagsWidgetRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 2.w,
        runSpacing: 8.h,
        children: [
          //Age Badge
          if (widget.user.userRole == 'age')
            Image.asset('assets/images/general/age_tag.png'),
          SizedBox(width: 8.w),
          if (widget.user.userRole == 'coin')
            Image.asset('assets/images/general/coin_tag.png'),

          SizedBox(width: 8.w),
          // Host Badge
          if (widget.user.userRole == 'vip')
            Image.asset('assets/images/general/vip_tag.png'),

          SizedBox(width: 8.w),
          if (widget.user.userRole == 'svip')
            Image.asset('assets/images/general/svip_tag.png'),

          SizedBox(width: 8.w),
          if (widget.user.userRole == 'host')
            Image.asset('assets/images/general/host_tag.png'),

          SizedBox(width: 8.w),
          if (widget.user.userRole == 'agent')
            Image.asset('assets/images/general/agent_tag.png'),

          SizedBox(width: 8.w),
          // Re Seller Badge
          if (widget.user.userRole == 're_seller')
            Image.asset('assets/images/general/re_seller_tag.png'),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = widget.user.stats;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Gold/Stars
        Stack(
          children: [
            Image.asset(
              'assets/images/general/coins_banner.png',
              width: MediaQuery.of(context).size.width * 0.5 - 25.w,
            ),
            Positioned(
              left: 50.w,
              top: 5.h,
              child: Text(
                AppUtils.formatNumber(stats?.coins ?? 0),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF202020),
                ),
              ),
            ),
          ],
        ),

        // Diamonds
        GestureDetector(
          onTap: () => _showWithdrawDialog(context),
          child: Stack(
            children: [
              Image.asset(
                'assets/images/general/withdraw_banner.png',
                width: MediaQuery.of(context).size.width * 0.5 - 25.w,
              ),
              Positioned(
                left: 50.w,
                top: 5.h,
                child: Text(
                  AppUtils.formatNumber(stats?.diamonds ?? 0),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF202020),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialStats() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2.r,
            blurRadius: 8.r,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSocialStatItem(
            isLoadingCounts ? '...' : '${followerCounts?.friendshipCount ?? 0}',
            'Friends',
            () {
              context.push('/friends-list/${widget.user.id}?title=Friends');
            },
          ),
          Container(width: 1.w, height: 30.h, color: const Color(0xFFF1F1F1)),
          _buildSocialStatItem(
            isLoadingCounts ? '...' : '${followerCounts?.followerCount ?? 0}',
            'Followers',
            () {
              context.push('/friends-list/${widget.user.id}?title=Followers');
            },
          ),
          Container(width: 1.w, height: 30.h, color: const Color(0xFFF1F1F1)),
          _buildSocialStatItem(
            isLoadingCounts ? '...' : '${followerCounts?.followingCount ?? 0}',
            'Following',
            () {
              context.push('/friends-list/${widget.user.id}?title=Following');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialStatItem(String count, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF000000),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF000000),
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
          SizedBox(width: 12.w),

          // Name and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '*${widget.user.name.split(' ').first.toUpperCase()}*',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 20.sp,
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
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16.sp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Column(
      spacing: 8.h,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 2.r,
                blurRadius: 8.r,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _buildFeatureIcon(
                "assets/images/general/store_icon.png",
                'Store',
                context,
                onTap: () {
                  // context.push(AppRoutes.store);
                },
              ),
              _buildFeatureIcon(
                "assets/images/general/vip_icon.png",
                'VIP',
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
              _buildFeatureIcon(
                "assets/images/general/my_bag_icon.png",
                'My Bag',
                context,
              ),
              _buildFeatureIcon(
                "assets/images/general/helping_icon.png",
                'Helping',
                context,
              ),
              _buildFeatureIcon(
                "assets/images/general/fan_club_icon.png",
                'Fan Club',
                context,
              ),
              _buildFeatureIcon(
                "assets/images/general/live_record_icon.png",
                'Live Record',
                context,
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Image.asset("assets/images/general/svip_banner.png"),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 2.r,
                blurRadius: 8.r,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _buildFeatureIcon(
                "assets/images/general/room_management_icon.png",
                'Manage Rooms',
                context,
              ),
              _buildFeatureIcon(
                "assets/images/general/about_us_icon.png",
                'About Us',
                context,
              ),
              _buildFeatureIcon(
                "assets/images/general/my_invite_icon.png",
                'My Invite',
                context,
              ),
              _buildFeatureIcon(
                "assets/images/general/settings_icon.png",
                'Settings',
                context,
                onTap: () {
                  context.push(AppRoutes.settings);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureIcon(
    String iconPath,
    String label,
    BuildContext context, {
    Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4 - 20.w,
        child: Column(
          children: [
            Image.asset(iconPath, width: 68.w, height: 68.h),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 15.sp,
                color: const Color(0xFF202020),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUserPosts() async {
    try {
      setState(() {
        isLoadingPosts = true;
        postsErrorMessage = null;
      });

      final result = await _postService.getUserPosts(
        userId: widget.user.id,
        page: _currentPage,
        limit: 10,
      );

      result.when(
        success: (data) {
          final postResponse = PostResponse.fromJson(data);
          setState(() {
            userPosts = postResponse.result.data;
            isLoadingPosts = false;
          });
        },
        failure: (error) {
          setState(() {
            postsErrorMessage = error;
            isLoadingPosts = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        postsErrorMessage = 'Error: ${e.toString()}';
        isLoadingPosts = false;
      });
    }
  }

  Future<void> _loadUserReels() async {
    try {
      setState(() {
        isLoadingReels = true;
        reelsErrorMessage = null;
      });

      final result = await _reelsService.getUserReels(
        userId: widget.user.id,
        page: _currentReelsPage,
        limit: 10,
      );

      result.when(
        success: (data) {
          final reelsResponse = ReelsResponse.fromJson(data);
          setState(() {
            userReels = reelsResponse.result.data;
            isLoadingReels = false;
          });
        },
        failure: (error) {
          setState(() {
            reelsErrorMessage = error;
            isLoadingReels = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        reelsErrorMessage = 'Error: ${e.toString()}';
        isLoadingReels = false;
      });
    }
  }

  Widget _buildReelsAndPostsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
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
        _buildReelsGrid(),
        //Divider Line
        Container(
          height: 1,
          color: const Color(0xFFF1F1F1),
          margin: EdgeInsets.symmetric(vertical: 20.h),
        ),
        Text(
          'Posts',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF202020),
          ),
        ),
        SizedBox(height: 10.h),
        _buildPostsSection(),
        SizedBox(height: 100.h),
      ],
    );
  }

  Widget _buildReelsGrid() {
    if (isLoadingReels) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (reelsErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading reels: $reelsErrorMessage',
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadUserReels,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (userReels.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Icon(
                Icons.movie_creation_outlined,
                size: 48.sp,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16.h),
              Text(
                'No reels yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
              ),
            ],
          ),
        ),
      );
    }

    // Show actual reels in a grid
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: 0.75, // Slightly taller for video thumbnails
      ),
      itemCount: userReels.length,
      itemBuilder: (context, index) {
        final reel = userReels[index];
        return GestureDetector(
          onTap: () {
            _openReelViewer(reel, index);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [BoxShadow(offset: const Offset(0, 2))],
            ),
            child: Stack(
              children: [
                // Video thumbnail (placeholder for now)
                Container(),
                // Reel info overlay
                Positioned(
                  bottom: 8.h,
                  left: 8.w,
                  right: 8.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white, size: 24.sp),
                      Text(
                        '${reel.reactions}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openReelViewer(ReelApiModel reel, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserReelsViewer(
          userReels: userReels,
          initialIndex: index,
          userId: widget.user.id,
        ),
      ),
    );
  }

  Widget _buildPostsSection() {
    if (isLoadingPosts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (postsErrorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
              SizedBox(height: 16.h),
              Text(
                'Error loading posts: $postsErrorMessage',
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadUserPosts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (userPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Icon(Icons.post_add, size: 48.sp, color: Colors.grey[400]),
              SizedBox(height: 16.h),
              Text(
                'No posts yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userPosts.length,
      itemBuilder: (context, index) {
        final post = userPosts[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: ApiPostContainer(
            post: post,
            onPostDeleted: () {
              setState(() {
                userPosts.removeAt(index);
              });
            },
            onPostUpdated: () {
              _loadUserPosts();
            },
          ),
        );
      },
    );
  }

  // Withdraw Dialog Method
  void _showWithdrawDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    String selectedAccountType = 'bkash';
    bool isLoading = false;

    // Set max amount from user's diamonds
    final maxAmount = widget.user.stats?.diamonds ?? 0;
    amountController.text = maxAmount.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).primaryColor,
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Withdraw Bonus',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF202020),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Field
                    Text(
                      'Amount (Max: ${AppUtils.formatNumber(maxAmount)})',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.diamond,
                          color: Colors.amber,
                          size: 20.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Account Type Selection
                    Text(
                      'Account Type',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAccountType,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: 'bkash',
                              child: Row(
                                children: [
                                  Container(
                                    width: 24.w,
                                    height: 24.h,
                                    decoration: BoxDecoration(
                                      color: Colors.pink.shade100,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'bK',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.pink,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  const Text('bKash'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'nagad',
                              child: Row(
                                children: [
                                  Container(
                                    width: 24.w,
                                    height: 24.h,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'N',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  const Text('Nagad'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'rocket',
                              child: Row(
                                children: [
                                  Container(
                                    width: 24.w,
                                    height: 24.h,
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'R',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  const Text('Rocket'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedAccountType = newValue!;
                            });
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Phone Number Field
                    Text(
                      'Account Number / Phone Number',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter account number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.phone,
                          color: Colors.green,
                          size: 20.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Info text
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'You can only withdraw once per day',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Cancel Button
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),

                // Withdraw Button
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (amountController.text.isEmpty ||
                              phoneController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final amount = int.tryParse(amountController.text);
                          if (amount == null ||
                              amount <= 0 ||
                              amount > maxAmount) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please enter a valid amount (1 - $maxAmount)',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          await _processWithdraw(
                            context: context,
                            dialogContext: dialogContext,
                            accountType: selectedAccountType,
                            accountNumber: phoneController.text,
                            totalSalary: amount,
                          );

                          setState(() {
                            isLoading = false;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Withdraw',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Process Withdraw API Call
  Future<void> _processWithdraw({
    required BuildContext context,
    required BuildContext dialogContext,
    required String accountType,
    required String accountNumber,
    required int totalSalary,
  }) async {
    try {
      final apiService = ApiService.instance;

      final response = await apiService.post<Map<String, dynamic>>(
        '/api/auth/withdraw-bonus',
        data: {
          'accountType': accountType,
          'accountNumber': accountNumber,
          'totalSalary': totalSalary,
        },
      );

      response.fold(
        (data) {
          // Success
          Navigator.of(dialogContext).pop(); // Close dialog

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Withdraw request submitted successfully!',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Refresh user profile to update diamond count
          final authBloc = context.read<AuthBloc>();
          authBloc.add(const AuthCheckStatusEvent());
        },
        (error) {
          // Error
          Navigator.of(dialogContext).pop(); // Close dialog

          // Parse error message
          String errorMessage = 'Failed to process withdrawal';
          if (error.contains('already applied')) {
            errorMessage = 'You have already applied for bonus today';
          } else if (error.contains('insufficient')) {
            errorMessage = 'Insufficient balance';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        },
      );
    } catch (e) {
      Navigator.of(dialogContext).pop(); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Network error. Please try again.',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// User Reels Viewer Widget
class UserReelsViewer extends StatefulWidget {
  final List<ReelApiModel> userReels;
  final int initialIndex;
  final String userId;

  const UserReelsViewer({
    super.key,
    required this.userReels,
    required this.initialIndex,
    required this.userId,
  });

  @override
  State<UserReelsViewer> createState() => _UserReelsViewerState();
}

class _UserReelsViewerState extends State<UserReelsViewer> {
  late List<reels_viewer.ReelModel> reelsList;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;

    // Convert ReelApiModel to ReelModel for ReelsViewer
    reelsList = widget.userReels.map((apiModel) {
      return ReelMapper.entityToReelModel(
        ReelMapper.apiModelToEntity(apiModel),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: reels_viewer.ReelsViewer(
        reelsList: reelsList,
        appbarTitle: 'User Reels',
        onShare: (url) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Share feature coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        onLike: (url) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Like feature coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        onFollow: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Follow feature coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        onComment: (comment) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment feature coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        onClickMoreBtn: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('More options coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        onClickBackArrow: () {
          Navigator.pop(context);
        },
        onIndexChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        showProgressIndicator: true,
        showVerifiedTick: true,
        showAppbar: true,
      ),
    );
  }
}
