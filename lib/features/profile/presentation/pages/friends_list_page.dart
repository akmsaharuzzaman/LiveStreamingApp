import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../injection/injection.dart';
import '../../data/models/friends_models.dart';
import '../../data/services/friends_api_service.dart';
import '../widgets/user_profile_bottom_sheet.dart';

class FriendsListPage extends StatefulWidget {
  final String userId;
  final String title; // "Friends", "Followers", or "Following"

  const FriendsListPage({super.key, required this.userId, required this.title});

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  bool isLoading = true;
  List<UserListItem> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    setState(() {
      isLoading = true;
    });

    final friendsService = getIt<FriendsApiService>();

    try {
      final result = await _getDataBasedOnTitle(friendsService);

      result.when(
        success: (data) {
          setState(() {
            users = _convertApiDataToUserListItems(data);
            isLoading = false;
          });
          print('${widget.title} loaded successfully: ${users.length} users');
        },
        failure: (error) {
          setState(() {
            isLoading = false;
          });
          print('Error loading ${widget.title}: $error');
          // Show error message or keep empty list
        },
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading ${widget.title}: $e');
    }
  }

  Future<dynamic> _getDataBasedOnTitle(FriendsApiService service) {
    switch (widget.title) {
      case 'Friends':
        return service.getFriendList(widget.userId);
      case 'Followers':
        return service.getFollowerList(widget.userId);
      case 'Following':
        return service.getFollowingList(widget.userId);
      default:
        return service.getFriendList(widget.userId);
    }
  }

  List<UserListItem> _convertApiDataToUserListItems(dynamic apiResponse) {
    print('Converting API data for ${widget.title}:');
    print('API Response Type: ${apiResponse.runtimeType}');
    print('API Response: $apiResponse');

    List<UserInfo> userInfoList = [];

    if (apiResponse is List<FriendItem>) {
      print('Processing Friends List with ${apiResponse.length} items');
      // Friends list - use friendInfo from each item
      userInfoList = apiResponse.map((item) => item.friendInfo).toList();
    } else if (apiResponse is List<FollowItem>) {
      print('Processing Follow List with ${apiResponse.length} items');
      // For followers/following, we need to determine which user info to use
      // For followers: use myId (the one who is following me)
      // For following: use followerId (the one I am following)
      if (widget.title == 'Followers') {
        userInfoList = apiResponse.map((item) => item.myId).toList();
      } else {
        userInfoList = apiResponse.map((item) => item.followerId).toList();
      }
    } else {
      print('Unknown API response type: ${apiResponse.runtimeType}');
    }

    print('Extracted ${userInfoList.length} user info items');

    return userInfoList
        .map(
          (user) => UserListItem(
            id: user.id,
            name: user.name,
            avatar:
                'https://i.pravatar.cc/150?u=${user.id}', // Generate avatar from user ID
            level: 'Lv1', // API doesn't provide level in friends list
            badges: [], // API doesn't provide badges in friends list
            coins: null, // API doesn't provide coins in friends list
            lastSeen:
                'Recently', // API doesn't provide last seen in friends list
            isOnline:
                false, // API doesn't provide online status in friends list
            canFollow: widget.title == 'Followers',
            isFollowing:
                false, // You might want to add this field to the API response
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: Colors.transparent,
          elevation: 4, // Set elevation here (e.g., 4 for shadow)
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD7CAFE), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16.h),
                  Text(
                    'No ${widget.title.toLowerCase()} found',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserItem(user);
              },
            ),
    );
  }

  Widget _buildUserItem(UserListItem user) {
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
                  border: Border.all(
                    color: user.isOnline ? Colors.green : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    user.avatar,
                    width: 50.w,
                    height: 50.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
              // Online indicator
              if (user.isOnline)
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
                  builder: (context) =>
                      UserProfileBottomSheet(userId: widget.userId),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Badges Row
                  Row(
                    children: [
                      // Level Badge
                      Image.asset(
                        'assets/images/general/level_frame.png',
                        height: 20.w,
                      ),
                      SizedBox(width: 4.w),
                      // SVIP Badge
                      if (user.badges.contains('SVIP'))
                        Image.asset(
                          'assets/images/general/svip_frame.png',
                          height: 20.w,
                        ),
                      SizedBox(width: 4.w),
                      // Coins Badge
                      if (user.coins != null)
                        Image.asset(
                          'assets/images/general/coin_frame.png',
                          height: 20.w,
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  // Online Status
                  Row(
                    children: [
                      if (user.lastSeen == 'Live')
                        Icon(
                          Icons.radio_button_checked,
                          color: Colors.red,
                          size: 12.sp,
                        ),
                      if (user.lastSeen == 'Live') SizedBox(width: 4.w),
                      Text(
                        user.lastSeen,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: user.lastSeen == 'Live'
                              ? Colors.red
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          if (widget.title == 'Followers')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Follow Back Button
                if (!user.isFollowing)
                  GestureDetector(
                    onTap: () => _handleFollowUser(user),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.all(Radius.circular(16.r)),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Color(0xFF825CB3),
                        size: 16.sp,
                      ),
                    ),
                  ),
                SizedBox(width: 8.w),
                // Remove/Unfollow Button
                GestureDetector(
                  onTap: () => _handleRemoveUser(user),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      // color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(Icons.close, color: Colors.black, size: 20.sp),
                  ),
                ),
              ],
            ),
          if (widget.title == 'Following')
            GestureDetector(
              onTap: () => _handleUnfollowUser(user),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(Icons.close, color: Colors.grey[600], size: 16.sp),
              ),
            ),
        ],
      ),
    );
  }

  void _handleFollowUser(UserListItem user) {
    setState(() {
      user.isFollowing = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Following ${user.name}')));
  }

  void _handleRemoveUser(UserListItem user) {
    setState(() {
      users.remove(user);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Removed ${user.name}')));
  }

  void _handleUnfollowUser(UserListItem user) {
    setState(() {
      users.remove(user);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Unfollowed ${user.name}')));
  }
}

// Data Model
class UserListItem {
  final String id;
  final String name;
  final String avatar;
  final String level;
  final List<String> badges;
  final String? coins;
  final String lastSeen;
  final bool isOnline;
  final bool canFollow;
  bool isFollowing;

  UserListItem({
    required this.id,
    required this.name,
    required this.avatar,
    required this.level,
    required this.badges,
    this.coins,
    required this.lastSeen,
    required this.isOnline,
    required this.canFollow,
    required this.isFollowing,
  });
}
