import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dlstarlive/features/reels/custom_package/reels_viewer.dart'
    as reels_viewer;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/network/api_clients.dart';
import '../../../../core/network/api_service.dart';
import '../../../../injection/injection.dart';
import '../../data/services/friends_api_service.dart';
import '../../data/models/friends_models.dart';
import '../../../newsfeed/data/datasources/post_service.dart';
import '../../../newsfeed/data/models/post_response_model.dart';
import '../../../newsfeed/presentation/widgets/api_post_container.dart';
import '../../../reels/data/services/reels_service.dart';
import '../../../reels/data/models/reel_response_model.dart';
import '../../../reels/data/models/reel_api_response_model.dart';
import '../../../reels/presentation/utils/reel_mapper.dart';
import '../../../../core/auth/auth_bloc_adapter.dart';

class ViewUserProfile extends StatefulWidget {
  const ViewUserProfile({super.key, required this.userId});
  final String userId;

  @override
  State<ViewUserProfile> createState() => _ViewUserProfileState();
}

class _ViewUserProfileState extends State<ViewUserProfile> {
  UserModel? userProfile;
  bool isLoading = true;
  bool isFollowLoading = false;
  String? errorMessage;

  // Follower count data
  FollowerCountResult? followerCounts;
  bool isLoadingCounts = true;

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

  @override
  void initState() {
    super.initState();
    _postService = PostService(ApiService.instance, AuthBlocAdapter(context));
    _reelsService = ReelsService(ApiService.instance, AuthBlocAdapter(context));
    _loadUserProfile();
    _loadFollowerCounts();
    _loadUserPosts();
    _loadUserReels();
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

  Future<void> _loadFollowerCounts() async {
    final friendsService = getIt<FriendsApiService>();

    try {
      final result = await friendsService.getFollowerAndFollowingCount(
        widget.userId,
      );

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

  Future<void> _loadUserPosts() async {
    try {
      setState(() {
        isLoadingPosts = true;
        postsErrorMessage = null;
      });

      final result = await _postService.getUserPosts(
        userId: widget.userId,
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
        userId: widget.userId,
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

  Future<void> _handleFollowToggle() async {
    if (userProfile == null || isFollowLoading) return;

    setState(() {
      isFollowLoading = true;
    });

    try {
      final userApiClient = getIt<UserApiClient>();
      final isCurrentlyFollowing =
          userProfile!.relationship?.myFollowing == true;

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
            relationship: userProfile!.relationship?.copyWith(
              myFollowing: !isCurrentlyFollowing,
            ),
          );
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyFollowing
                  ? 'Unfollowed ${userProfile!.name}'
                  : 'Following ${userProfile!.name}',
            ),
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
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.centerLeft,
              colors: [Color(0xFFD7CAFE), Color(0xFFFFFFFF)],
            ),
          ),
          height: double.infinity,
          width: double.infinity,
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Cover Photo and Top Icons
                    Stack(
                      children: [
                        (user.coverPicture != null)
                            ? Container(
                                width: double.infinity,
                                height: 170.h,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                ),
                                child: Image.network(
                                  user.coverPicture ?? '',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                height: 170.h,
                                width: double.infinity,
                                color: const Color(0xFF888686),
                                child: Center(
                                  child: Text(
                                    'No Cover Photo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                ),
                              ),
                        if (user.userRole == 'admin')
                          Positioned.fill(
                            top: 125.h,
                            left: MediaQuery.of(context).size.width - 160.w,
                            child: Image.asset(
                              "assets/images/general/super_admin_frame.png",
                              height: 26.h,
                            ),
                          ),
                        Positioned(
                          top: 50.h,
                          left: 20.w,
                          right: 20.w,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => Navigator.of(context).pop(),
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  size: 20.sp,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                child: Icon(
                                  Icons.more_horiz,
                                  size: 20.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Content section with padding for overlapping profile picture
                    SizedBox(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 50.h,
                          left: 20.w,
                          right: 20.w,
                        ),
                        child: Column(
                          children: [
                            // Space and layout for profile picture with user info
                            SizedBox(height: 36.h),

                            // Profile info section - positioned next to profile picture
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User information positioned to the right of profile
                                Expanded(child: _buildLevelBadges()),
                              ],
                            ),

                            SizedBox(height: 20.h),

                            // Friends/Followers/Following
                            _buildSocialStats(),

                            SizedBox(height: 20.h),

                            // Profile Card Section
                            _buildProfileCard(user),
                            SizedBox(height: 20.h),

                            // Expandable Tiles
                            _buildExpandableTile(
                              'assets/images/general/baggage_icon.png',
                              'Baggage',
                              () {
                                // Handle baggage tap
                                print('Baggage tapped');
                              },
                            ),
                            // Divider Line
                            Container(
                              height: 1,
                              color: const Color(0xFFF1F1F1),
                              margin: EdgeInsets.symmetric(vertical: 20.h),
                            ),
                            _buildExpandableTile(
                              'assets/images/general/black_badge_icon.png',
                              'Badges',
                              () {
                                // Handle badges tap
                                print('Badges tapped');
                              },
                            ),

                            // Continue with the rest of the content...
                            Container(
                              height: 1,
                              color: const Color(0xFFF1F1F1),
                              margin: EdgeInsets.symmetric(vertical: 20.h),
                            ),

                            // Moments and Posts section
                            _buildMomentsGrid(),
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
                  child: _buildProfileHeader(user),
                ),
                // Build Overlapping User Information
                Positioned(
                  top: 160.h, // Position to overlap cover photo and content
                  left: 140.w, // Left position closer to left edge
                  child: _buildOverlappingUserInformation(user),
                ),
              ],
            ),
          ),
        ),
        Positioned(right: 0, left: 0, bottom: 0, child: _buildActionButtons()),
      ],
    );
  }

  // Add the missing _buildOverlappingUserInformation method
  Widget _buildOverlappingUserInformation(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        // User Name
        Text(
          user.name,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),

        SizedBox(height: 12.h),

        // User ID and Location
        Row(
          children: [
            Text(
              'ID:${user.id.substring(0, 6)} | Bangladesh',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF202020),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMomentsGrid() {
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
              const SizedBox(height: 16),
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.movie_creation_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
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
            // Navigate to reel viewer with this specific reel
            // You can implement navigation to full reel viewer here
            _openReelViewer(reel, index);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Video thumbnail (placeholder for now)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                // Reel info overlay
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reactions count
                      if (reel.reactions > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${reel.reactions}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      // Comments count
                      if (reel.comments > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.comment,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${reel.comments}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
    // Navigate to the reels viewer page with the specific reel
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserReelsViewer(
          userReels: userReels,
          initialIndex: index,
          userId: widget.userId,
        ),
      ),
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
      width: 100.w,
      height: 100.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: (user.avatar != null || user.profilePictureUrl != null)
            ? Image.network(
                user.avatar ?? user.profilePictureUrl!,
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
        _buildSocialStatItem(
          isLoadingCounts ? '...' : '${followerCounts?.friendshipCount ?? 0}',
          'Friends',
          () {
            context.push('/friends-list/${widget.userId}?title=Friends');
          },
        ),
        Container(width: 1, height: 30, color: const Color(0xFFF1F1F1)),
        _buildSocialStatItem(
          isLoadingCounts ? '...' : '${followerCounts?.followerCount ?? 0}',
          'Followers',
          () {
            context.push('/friends-list/${widget.userId}?title=Followers');
          },
        ),
        Container(width: 1, height: 30, color: const Color(0xFFF1F1F1)),
        _buildSocialStatItem(
          isLoadingCounts ? '...' : '${followerCounts?.followingCount ?? 0}',
          'Following',
          () {
            context.push('/friends-list/${widget.userId}?title=Following');
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
                onPressed: isFollowLoading ? null : _handleFollowToggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: isFollowLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Image.asset(
                        relationship?.myFollowing == true
                            ? 'assets/images/general/minus_icon.png'
                            : 'assets/images/general/plus_icon.png',
                        width: 16,
                        height: 16,
                        color: Colors.white,
                      ),
                label: Text(
                  isFollowLoading
                      ? 'Loading...'
                      : (relationship?.myFollowing == true
                            ? 'Unfollow'
                            : 'Follow'),
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading posts: $postsErrorMessage',
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(Icons.post_add, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
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
              // Remove the post from the list
              setState(() {
                userPosts.removeAt(index);
              });
            },
            onPostUpdated: () {
              // Optionally refresh the post or update UI
              // For now, we'll just show a brief loading indicator
              _loadUserPosts();
            },
          ),
        );
      },
    );
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
