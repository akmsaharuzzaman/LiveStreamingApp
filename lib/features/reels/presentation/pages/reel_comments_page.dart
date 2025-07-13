import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/reel_entity.dart';
import '../../injection_container.dart';
import '../../domain/usecases/reels_usecases.dart';

class ReelCommentsPage extends StatefulWidget {
  final String reelId;
  final String reelTitle;

  const ReelCommentsPage({
    super.key,
    required this.reelId,
    required this.reelTitle,
  });

  @override
  State<ReelCommentsPage> createState() => _ReelCommentsPageState();
}

class _ReelCommentsPageState extends State<ReelCommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  // Use cases
  late GetReelCommentsUseCase _getCommentsUseCase;
  late AddCommentUseCase _addCommentUseCase;
  late ReactToCommentUseCase _reactToCommentUseCase;
  late ReplyToCommentUseCase _replyToCommentUseCase;

  List<ReelCommentEntity> _comments = [];
  bool _isLoading = false;
  String? _replyingToCommentId;

  @override
  void initState() {
    super.initState();

    // Initialize use cases from dependency container
    final repository = ReelsDependencyContainer.createRepository();
    _getCommentsUseCase = GetReelCommentsUseCase(repository);
    _addCommentUseCase = AddCommentUseCase(repository);
    _reactToCommentUseCase = ReactToCommentUseCase(repository);
    _replyToCommentUseCase = ReplyToCommentUseCase(repository);

    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await _getCommentsUseCase.call(widget.reelId);
      setState(() {
        _comments = comments ?? [];
        _isLoading = false;
      });
    } catch (e) {
      log('Error loading comments: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading comments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final success = await _addCommentUseCase.call(
        widget.reelId,
        _commentController.text.trim(),
      );

      if (success) {
        _commentController.clear();
        _loadComments(); // Reload comments
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      log('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _replyToComment(String commentId) async {
    if (_replyController.text.trim().isEmpty) return;

    try {
      final success = await _replyToCommentUseCase.call(
        commentId,
        widget.reelId,
        _replyController.text.trim(),
      );

      if (success) {
        _replyController.clear();
        setState(() {
          _replyingToCommentId = null;
        });
        _loadComments(); // Reload comments
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add reply'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      log('Error adding reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _reactToComment(String commentId, String reactionType) async {
    try {
      final success = await _reactToCommentUseCase.call(
        commentId,
        reactionType,
      );

      if (success) {
        _loadComments(); // Reload to show updated reaction count
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reacted with $reactionType!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to react to comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      log('Error reacting to comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Comments',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 64.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return _buildCommentItem(comment);
                    },
                  ),
          ),

          // Reply Input (shown when replying)
          if (_replyingToCommentId != null) ...[
            Container(
              padding: EdgeInsets.all(16.w),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: () => _replyToComment(_replyingToCommentId!),
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _replyingToCommentId = null;
                      });
                      _replyController.clear();
                    },
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ],

          // Comment Input
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(ReelCommentEntity comment) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Comment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 16.r,
                backgroundColor: Colors.grey[300],
                backgroundImage: comment.commentedByInfo.avatar != null
                    ? NetworkImage(comment.commentedByInfo.avatar!)
                    : null,
                child: comment.commentedByInfo.avatar == null
                    ? Icon(Icons.person, size: 16.sp, color: Colors.grey[600])
                    : null,
              ),
              SizedBox(width: 12.w),
              // Comment Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username and Time
                    Row(
                      children: [
                        Text(
                          comment.commentedByInfo.name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _formatTime(comment.createdAt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    // Comment Text
                    Text(comment.article, style: TextStyle(fontSize: 14.sp)),
                    SizedBox(height: 8.h),
                    // Action Buttons
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _reactToComment(comment.id, 'like'),
                          child: Row(
                            children: [
                              Icon(
                                Icons.thumb_up_outlined,
                                size: 14.sp,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${comment.reactionsCount}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyingToCommentId = comment.id;
                            });
                          },
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        GestureDetector(
                          onTap: () => _reactToComment(comment.id, 'love'),
                          child: Icon(
                            Icons.favorite_outline,
                            size: 14.sp,
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

          // Replies
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

  Widget _buildReplyItem(ReelCommentEntity reply) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 12.r,
            backgroundColor: Colors.grey[300],
            backgroundImage: reply.commentedByInfo.avatar != null
                ? NetworkImage(reply.commentedByInfo.avatar!)
                : null,
            child: reply.commentedByInfo.avatar == null
                ? Icon(Icons.person, size: 12.sp, color: Colors.grey[600])
                : null,
          ),
          SizedBox(width: 8.w),
          // Reply Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.commentedByInfo.name,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      _formatTime(reply.createdAt),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(reply.article, style: TextStyle(fontSize: 12.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return 'now';
    }
  }
}
