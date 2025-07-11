import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/network_temp/api_result.dart';
import 'package:dlstarlive/core/network_temp/api_service.dart';
import 'package:dlstarlive/core/network_temp/post_service.dart';
import 'package:dlstarlive/core/network_temp/simple_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/comment_response_model.dart';

class CommentsPage extends StatefulWidget {
  final String postId;
  final String postOwnerName;

  const CommentsPage({
    super.key,
    required this.postId,
    required this.postOwnerName,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();

  late PostService _postService;
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _replyingToCommentId;
  String? _replyingToUserName;
  String? _editingCommentId;
  int _currentPage = 1;
  bool _hasMoreComments = true;
  int _initialCommentCount = 0; // Track initial comment count
  bool _commentCountChanged = false; // Track if comment count changed

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  void _initializeService() {
    final apiService = ApiService.instance;
    final authService = AuthService();
    _postService = PostService(apiService, authService);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _postService.getPostComments(
      postId: widget.postId,
      page: 1,
      limit: 20,
    );

    if (mounted) {
      result.when(
        success: (data) {
          final commentResponse = CommentResponse.fromJson(data);
          setState(() {
            _comments = commentResponse.result.data;
            _isLoading = false;
            _currentPage = 1;
            _hasMoreComments =
                commentResponse.result.pagination?.page !=
                commentResponse.result.pagination?.totalPage;
            // Set initial comment count on first load
            if (_initialCommentCount == 0) {
              _initialCommentCount = _comments.length;
            }
          });
        },
        failure: (error) {
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        },
      );
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMoreComments) return;

    setState(() {
      _isLoadingMore = true;
    });

    final result = await _postService.getPostComments(
      postId: widget.postId,
      page: _currentPage + 1,
      limit: 20,
    );

    if (mounted) {
      result.when(
        success: (data) {
          final commentResponse = CommentResponse.fromJson(data);
          setState(() {
            _comments.addAll(commentResponse.result.data);
            _isLoadingMore = false;
            _currentPage++;
            _hasMoreComments =
                commentResponse.result.pagination?.page !=
                commentResponse.result.pagination?.totalPage;
          });
        },
        failure: (error) {
          setState(() {
            _isLoadingMore = false;
          });
          _showErrorSnackBar(error);
        },
      );
    }
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    ApiResult<Map<String, dynamic>> result;

    if (_editingCommentId != null) {
      // Edit existing comment
      result = await _postService.editComment(
        commentId: _editingCommentId!,
        newCommentText: commentText,
      );
    } else if (_replyingToCommentId != null) {
      // Create reply to comment
      result = await _postService.replyToComment(
        postId: widget.postId,
        commentId: _replyingToCommentId!,
        commentText: commentText,
      );
    } else {
      // Create new comment
      result = await _postService.createComment(
        postId: widget.postId,
        commentText: commentText,
      );
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      result.when(
        success: (data) {
          _commentController.clear();
          _cancelReplyOrEdit();

          // Always reload comments to get fresh data from server
          _commentCountChanged = true;
          _loadComments();

          _showSuccessSnackBar(
            _editingCommentId != null
                ? 'Comment updated successfully'
                : 'Comment posted successfully',
          );
        },
        failure: (error) {
          _showErrorSnackBar(error);
        },
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final result = await _postService.deleteComment(
      postId: widget.postId,
      commentId: commentId,
    );

    if (mounted) {
      result.when(
        success: (data) {
          _commentCountChanged = true;
          _loadComments(); // Reload comments to get fresh data
          _showSuccessSnackBar('Comment deleted successfully');
        },
        failure: (error) {
          _showErrorSnackBar('Failed to delete comment: $error');
        },
      );
    }
  }

  Future<void> _reactToComment(String commentId, String reactionType) async {
    final result = await _postService.reactToComment(
      commentId: commentId,
      reactionType: reactionType,
    );

    if (mounted) {
      result.when(
        success: (data) {
          // Reload comments to get fresh reaction data
          _loadComments();
        },
        failure: (error) {
          _showErrorSnackBar(error);
        },
      );
    }
  }

  void _startReply(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
      _editingCommentId = null;
    });
    _commentFocusNode.requestFocus();
  }

  void _startEdit(String commentId, String currentText) {
    setState(() {
      _editingCommentId = commentId;
      _replyingToCommentId = null;
      _replyingToUserName = null;
      _commentController.text = currentText;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReplyOrEdit() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
      _editingCommentId = null;
    });
  }

  void _showCommentOptions(CommentModel comment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                _startReply(comment.id, comment.userName ?? 'Unknown User');
              },
            ),
            // Show edit/delete options only for own comments
            if (_isOwnComment(comment)) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _startEdit(comment.id, comment.commentText);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(comment.id);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                _showErrorSnackBar('Report functionality not implemented yet');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(commentId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  bool _isOwnComment(CommentModel comment) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return comment.commentedBy == authState.user.id;
    }
    return false;
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

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // This callback is called after the pop has already occurred
        // We don't need to call Navigator.pop() again here as it would cause a double-pop
        // The result data should be handled in the custom back button instead
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Comments'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Custom back button behavior
              Navigator.of(context).pop({
                'shouldRefresh': false, // We handle updates optimistically
                'commentCountChanged': _commentCountChanged,
              });
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(child: _buildCommentsBody()),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadComments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.comment_outlined, size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              'No comments yet',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 8.h),
            Text(
              'Be the first to comment!',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComments,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _comments.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _comments.length) {
            return Container(
              padding: EdgeInsets.all(16.w),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          return _buildCommentItem(_comments[index]);
        },
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Container(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserAvatar(
                comment.avatar?.url ?? '',
                comment.userName ?? 'Unknown User',
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.userName ?? 'Unknown User',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            comment.commentText,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text(
                          _formatDate(comment.createdAt ?? DateTime.now()),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        GestureDetector(
                          onTap: () => _reactToComment(comment.id, 'like'),
                          child: Row(
                            children: [
                              Icon(
                                comment.myReaction?.reactionType == 'like'
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                size: 16.sp,
                                color:
                                    comment.myReaction?.reactionType == 'like'
                                    ? Colors.blue
                                    : Colors.grey[600],
                              ),
                              if (comment.reactionCount > 0) ...[
                                SizedBox(width: 4.w),
                                Text(
                                  comment.reactionCount.toString(),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        GestureDetector(
                          onTap: () => _startReply(
                            comment.id,
                            comment.userName ?? 'Unknown User',
                          ),
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showCommentOptions(comment),
                          child: Icon(
                            Icons.more_horiz,
                            size: 20.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Show replies if any
          if (comment.replies.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.only(left: 44.w),
              child: Column(
                children: comment.replies
                    .map((reply) => _buildReplyItem(reply))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyItem(CommentModel reply) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserAvatar(
            reply.avatar?.url ?? '',
            reply.userName ?? 'Unknown User',
            isSmall: true,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.userName ?? 'Unknown User',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        reply.commentText,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      _formatDate(reply.createdAt ?? DateTime.now()),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    GestureDetector(
                      onTap: () => _reactToComment(reply.id, 'like'),
                      child: Row(
                        children: [
                          Icon(
                            reply.myReaction?.reactionType == 'like'
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            size: 14.sp,
                            color: reply.myReaction?.reactionType == 'like'
                                ? Colors.blue
                                : Colors.grey[600],
                          ),
                          if (reply.reactionCount > 0) ...[
                            SizedBox(width: 2.w),
                            Text(
                              reply.reactionCount.toString(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showCommentOptions(reply),
                      child: Icon(
                        Icons.more_horiz,
                        size: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(
    String? avatarUrl,
    String? userName, {
    bool isSmall = false,
  }) {
    final size = isSmall ? 16.r : 20.r;
    final iconSize = isSmall ? 12.sp : 16.sp;

    return CircleAvatar(
      radius: size,
      backgroundColor: Colors.grey[200],
      child: CircleAvatar(
        radius: size - 2.r,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child: _buildAvatarContent(avatarUrl, userName, iconSize),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(
    String? avatarUrl,
    String? userName,
    double iconSize,
  ) {
    if (avatarUrl == null ||
        avatarUrl.trim().isEmpty ||
        !_isValidUrl(avatarUrl.trim())) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[300],
        child: Icon(Icons.person, size: iconSize, color: Colors.grey[600]),
      );
    }

    return CachedNetworkImage(
      imageUrl: avatarUrl.trim(),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: Center(
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[300],
        child: Icon(Icons.person, size: iconSize, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyingToUserName != null)
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16.sp, color: Colors.blue),
                  SizedBox(width: 8.w),
                  Text(
                    'Replying to $_replyingToUserName',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReplyOrEdit,
                    child: Icon(Icons.close, size: 16.sp, color: Colors.blue),
                  ),
                ],
              ),
            ),
          if (_editingCommentId != null)
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16.sp, color: Colors.orange),
                  SizedBox(width: 8.w),
                  Text(
                    'Editing comment',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReplyOrEdit,
                    child: Icon(Icons.close, size: 16.sp, color: Colors.orange),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: _replyingToUserName != null
                        ? 'Write a reply...'
                        : _editingCommentId != null
                        ? 'Edit your comment...'
                        : 'Write a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: BorderSide(color: Colors.blue, width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                decoration: BoxDecoration(
                  color: _isSubmitting ? Colors.grey[400] : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(Icons.send, color: Colors.white, size: 20.sp),
                ),
              ),
            ],
          ),
        ],
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

  String _formatDate(DateTime dateTime) {
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
