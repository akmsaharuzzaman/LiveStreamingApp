import 'package:dlstarlive/core/network/api_clients.dart';
import 'package:dlstarlive/core/models/user_model.dart';
import 'package:dlstarlive/features/profile/presentation/widgets/user_profile_bottom_sheet.dart';
import 'package:dlstarlive/injection/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HostInfo extends StatefulWidget {
  final String imageUrl;
  final String name;
  final String id;
  final String hostUserId;
  final String currentUserId;

  const HostInfo({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.id,
    required this.hostUserId,
    required this.currentUserId,
  });

  @override
  State<HostInfo> createState() => _HostInfoState();
}

class _HostInfoState extends State<HostInfo> {
  bool isFollowing = false;
  bool isLoading = false;
  bool isLoadingFollow = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    if (widget.hostUserId == widget.currentUserId) {
      // Don't show follow button for self
      return;
    }

    if (widget.hostUserId.isEmpty) {
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final userApiClient = getIt<UserApiClient>();
      final response = await userApiClient.getUserById(widget.hostUserId);

      if (response.isSuccess && response.data != null) {
        final userData = response.data!['result'] as Map<String, dynamic>;
        final userModel = UserModel.fromJson(userData);

        setState(() {
          isFollowing = userModel.relationship?.myFollowing == true;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleFollowToggle() async {
    if (isLoadingFollow) return;

    setState(() {
      isLoadingFollow = true;
    });

    try {
      final userApiClient = getIt<UserApiClient>();

      if (isFollowing) {
        final response = await userApiClient.unfollowUser(widget.hostUserId);
        if (response.isSuccess) {
          setState(() {
            isFollowing = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unfollowed ${widget.name}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        final response = await userApiClient.followUser(widget.hostUserId);
        if (response.isSuccess) {
          setState(() {
            isFollowing = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Following ${widget.name}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        isLoadingFollow = false;
      });
    }
  }

  void _showUserProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserProfileBottomSheet(userId: widget.hostUserId),
    );
  }

  bool get _shouldShowFollowButton {
    // Don't show if user is viewing their own profile
    if (widget.hostUserId == widget.currentUserId) return false;

    // Don't show if already following
    if (isFollowing) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.hostUserId.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Host information not available'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
        _showUserProfile();
      },
      child: Stack(
        children: [
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: Color(0xFF111111).withValues(alpha: .85),
              borderRadius: BorderRadius.circular(100.r),
              // gradient: LinearGradient(
              //   colors: [Color(0xFF000000), Color(0xFFD5FBFB)],
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              // ),
            ),
            child: Row(
              // Use SizedBox for spacing, since Row doesn't have spacing property
              children: [
                // holds the image of the user
                widget.imageUrl.isEmpty
                    ? CircleAvatar(
                        radius: 18.r,
                        backgroundColor: Colors.grey[400],
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      )
                    : CircleAvatar(
                        radius: 18.r,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100.r),
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24.sp,
                              );
                            },
                          ),
                        ),
                      ),
                SizedBox(width: 5.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(fontSize: 16.sp, color: Colors.white),
                    ),
                    Text(
                      "ID: ${widget.id}",
                      style: TextStyle(fontSize: 12.sp, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(width: 6.w),
              ],
            ),
          ),
          // Show follow button only if conditions are met
          if (_shouldShowFollowButton && !isLoading)
            Positioned(
              top: 0,
              bottom: 0,
              right: 6.w,
              child: GestureDetector(
                onTap: _handleFollowToggle,
                child: Container(
                  width: 26.w,
                  height: 26.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLoadingFollow ? Colors.grey : Colors.transparent,
                  ),
                  child: isLoadingFollow
                      ? Center(
                          child: SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Image.asset(
                          'assets/images/general/add_icon.png',
                          width: 26.w,
                          height: 26.h,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
