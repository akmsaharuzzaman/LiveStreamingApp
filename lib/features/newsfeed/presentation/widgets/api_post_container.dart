import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../components/utilities/chat_theme.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/simple_auth_service.dart';
import '../../../../core/network/api_service.dart';
import '../pages/comments_page.dart';

class ApiPostContainer extends StatefulWidget {
  final dynamic post;
  final Function? onPostDeleted;
  final Function? onPostUpdated;

  const ApiPostContainer({
    Key? key,
    required this.post,
    this.onPostDeleted,
    this.onPostUpdated,
  }) : super(key: key);

  @override
  State<ApiPostContainer> createState() => _ApiPostContainerState();
}

class _ApiPostContainerState extends State<ApiPostContainer> {
  late PostService _postService;
  bool _isReacting = false;
  bool _hasReacted = false;
  int _reactionCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _initializeReactionState();
  }

  void _initializeService() {
    final apiService = ApiService.instance;
    final authService = AuthService();
    _postService = PostService(apiService, authService);
  }

  void _initializeReactionState() {
    _hasReacted = widget.post.myReaction != null;
    _reactionCount = widget.post.reactionCount ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5.sp, horizontal: 0.0),
      elevation: 1.sp,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.sp)),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.sp),
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPostHeader(context),
                  SizedBox(height: 4.h),
                  // Handle null postCaption with better spacing
                  if (widget.post.postCaption != null &&
                      widget.post.postCaption!.trim().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(
                        widget.post.postCaption!.trim(),
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                ],
              ),
            ),
            // Handle media with better error handling - only show if mediaUrl exists and is not empty
            if (widget.post.mediaUrl != null &&
                widget.post.mediaUrl!.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: _buildPostImage(widget.post.mediaUrl!.trim()),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: _buildPostStats(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) {
    return Row(
      children: [
        // Profile Avatar with null handling
        _buildUserAvatar(
          widget.post.userInfo?.avatar?.url,
          widget.post.userInfo?.name,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.post.userInfo?.name ?? 'Unknown User',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${_formatDate(widget.post.updatedAt ?? widget.post.createdAt)} • ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.public, color: Colors.grey[600], size: 12.sp),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.more_horiz, size: 20.sp),
          onPressed: () => _showPostOptions(context),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(String? avatarUrl, String? userName) {
    return CircleAvatar(
      radius: 20.r,
      backgroundColor: MyTheme.kPrimaryColor,
      child: CircleAvatar(
        radius: 17.r,
        backgroundColor: Colors.grey[200],
        child: ClipOval(child: _buildAvatarContent(avatarUrl, userName)),
      ),
    );
  }

  Widget _buildAvatarContent(String? avatarUrl, String? userName) {
    // Check if avatarUrl is null, empty, or invalid
    if (avatarUrl == null ||
        avatarUrl.trim().isEmpty ||
        !_isValidUrl(avatarUrl.trim())) {
      return Container(
        width: 34.w,
        height: 34.h,
        color: Colors.grey[300],
        child: Icon(Icons.person, size: 20.sp, color: Colors.grey[600]),
      );
    }

    return CachedNetworkImage(
      imageUrl: avatarUrl.trim(),
      width: 34.w,
      height: 34.h,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: 34.w,
        height: 34.h,
        color: Colors.grey[200],
        child: Center(
          child: SizedBox(
            width: 16.w,
            height: 16.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 34.w,
        height: 34.h,
        color: Colors.grey[300],
        child: Icon(Icons.person, size: 20.sp, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildPostImage(String imageUrl) {
    // Check if it's a valid URL
    if (!_isValidUrl(imageUrl)) {
      return Container(
        height: 200.h,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.grey, size: 48.sp),
              SizedBox(height: 8.h),
              Text(
                'Invalid media URL',
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 200.h,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
              SizedBox(height: 8.h),
              Text(
                'Loading image...',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 200.h,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 48.sp,
                color: Colors.grey[400],
              ),
              SizedBox(height: 8.h),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostStats(BuildContext context) {
    // Use the state variables for reaction count and status
    final int safeCommentCount = (widget.post.commentCount ?? 0) > 0
        ? (widget.post.commentCount ?? 0)
        : 0;
    final bool hasReactions = _reactionCount > 0;
    final bool hasComments = safeCommentCount > 0;

    return Column(
      children: [
        // Only show stats row if there are reactions or comments
        if (hasReactions || hasComments)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                if (hasReactions) ...[
                  Container(
                    padding: EdgeInsets.all(4.sp),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.thumb_up,
                      size: 10.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatCount(_reactionCount),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
                  ),
                ],
                const Spacer(),
                if (hasComments)
                  Text(
                    '$safeCommentCount Comment${safeCommentCount != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
                  ),
              ],
            ),
          ),
        // Divider line
        if (hasReactions || hasComments)
          Divider(height: 1, thickness: 0.5, color: Colors.grey[300]),
        // Action buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPostButton(
              context: context,
              icon: Icon(
                _hasReacted ? MdiIcons.thumbUp : MdiIcons.thumbUpOutline,
                color: _hasReacted ? Colors.blue : Colors.grey[600],
                size: 20.sp,
              ),
              label: 'Like',
              onTap: () => _handleReaction(context),
            ),
            _buildPostButton(
              context: context,
              icon: Icon(
                MdiIcons.commentOutline,
                color: Colors.grey[600],
                size: 20.sp,
              ),
              label: 'Comment',
              onTap: () => _handleComment(context),
            ),
            _buildPostButton(
              context: context,
              icon: Icon(
                MdiIcons.shareOutline,
                color: Colors.grey[600],
                size: 20.sp,
              ),
              label: 'Share',
              onTap: () => _handleShare(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostButton({
    required BuildContext context,
    required Icon icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Save Post'),
              onTap: () {
                Navigator.pop(context);
                // Handle save post
                print('Save post: ${widget.post.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                // Handle report post
                print('Report post: ${widget.post.id}');
              },
            ),
            // Show delete option only for own posts
            if (_isOwnPost()) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Post',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Hide Post'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle hide post
                  print('Hide post: ${widget.post.id}');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  bool _isOwnPost() {
    // TODO: Implement proper user ID check
    // For now, return true if post was made by current user
    // You should compare widget.post.ownerId with current user ID
    return true; // Placeholder
  }

  Future<void> _deletePost() async {
    final result = await _postService.deletePost(widget.post.id);

    if (mounted) {
      result.when(
        success: (data) {
          _showSuccessSnackBar('Post deleted successfully');
          widget.onPostDeleted?.call();
        },
        failure: (error) {
          _showErrorSnackBar(error);
        },
      );
    }
  }

  Future<void> _handleReaction(BuildContext context) async {
    if (_isReacting) return;

    setState(() {
      _isReacting = true;
    });

    final result = await _postService.reactToPost(
      postId: widget.post.id,
      reactionType: 'like',
    );

    if (mounted) {
      setState(() {
        _isReacting = false;
      });

      result.when(
        success: (data) {
          setState(() {
            if (_hasReacted) {
              _hasReacted = false;
              _reactionCount = _reactionCount > 0 ? _reactionCount - 1 : 0;
            } else {
              _hasReacted = true;
              _reactionCount++;
            }
          });
          widget.onPostUpdated?.call();
        },
        failure: (error) {
          _showErrorSnackBar(error);
        },
      );
    }
  }

  void _handleComment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(
          postId: widget.post.id,
          postOwnerName: widget.post.userInfo?.name ?? 'Unknown User',
        ),
      ),
    ).then((_) {
      // Refresh post data when returning from comments
      widget.onPostUpdated?.call();
    });
  }

  void _handleShare(BuildContext context) {
    // TODO: Implement share functionality
    print('Share post: ${widget.post.id}');
    _showErrorSnackBar('Share functionality not implemented yet');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';

    try {
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
