import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

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

  void _loadUsers() {
    // Simulate loading
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        isLoading = false;
        // Mock data for demonstration
        users = [
          UserListItem(
            id: '1',
            name: 'Habib Khan',
            avatar: 'https://i.pravatar.cc/150?img=1',
            level: 'Lv17',
            badges: ['SVIP'],
            coins: '20',
            lastSeen: '1 d ago',
            isOnline: false,
            canFollow: widget.title == 'Followers',
            isFollowing: false,
          ),
          UserListItem(
            id: '2',
            name: 'Habib khan214',
            avatar: 'https://i.pravatar.cc/150?img=2',
            level: 'Lv17',
            badges: ['SVIP'],
            coins: null,
            lastSeen: 'Moment ago',
            isOnline: true,
            canFollow: widget.title == 'Followers',
            isFollowing: false,
          ),
          UserListItem(
            id: '3',
            name: 'Habib khan2214',
            avatar: 'https://i.pravatar.cc/150?img=3',
            level: 'Lv17',
            badges: [],
            coins: null,
            lastSeen: '22/03/2024',
            isOnline: false,
            canFollow: widget.title == 'Followers',
            isFollowing: false,
          ),
          UserListItem(
            id: '4',
            name: 'Habib khan2214',
            avatar: 'https://i.pravatar.cc/150?img=4',
            level: 'Lv17',
            badges: [],
            coins: null,
            lastSeen: 'Live',
            isOnline: true,
            canFollow: widget.title == 'Followers',
            isFollowing: false,
          ),
        ];
      });
    });
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
          elevation: 50,
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
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Badges Row
                Row(
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Level Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFFF8BA0)],
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        user.level,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    // SVIP Badge
                    if (user.badges.contains('SVIP'))
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3142),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'SVIP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    SizedBox(width: 4.w),
                    // Coins Badge
                    if (user.coins != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🤍', style: TextStyle(fontSize: 8.sp)),
                            Text(
                              user.coins!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                // Last Seen
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
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 16.sp),
                    ),
                  ),
                SizedBox(width: 8.w),
                // Remove/Unfollow Button
                GestureDetector(
                  onTap: () => _handleRemoveUser(user),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey[600],
                      size: 16.sp,
                    ),
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
