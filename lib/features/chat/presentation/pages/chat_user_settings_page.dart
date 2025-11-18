import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../data/services/chat_api_service.dart';
import '../../../../core/auth/auth_bloc.dart';

class ChatUserSettingsPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userAvatar;
  final int userLevel;

  const ChatUserSettingsPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.userLevel = 15,
  });

  @override
  State<ChatUserSettingsPage> createState() => _ChatUserSettingsPageState();
}

class _ChatUserSettingsPageState extends State<ChatUserSettingsPage> {
  bool isBlocked = false;
  bool isLoading = true;
  final ChatApiService _chatApiService = GetIt.instance<ChatApiService>();

  @override
  void initState() {
    super.initState();
    _loadBlockStatus();
  }

  Future<void> _loadBlockStatus() async {
    setState(() => isLoading = true);

    final result = await _chatApiService.getBlockStatus(userId: widget.userId);

    result.fold(
      (isBlockedStatus) {
        setState(() {
          isBlocked = isBlockedStatus;
          isLoading = false;
        });
      },
      (error) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load block status: $error')),
          );
        }
      },
    );
  }

  Future<void> _toggleBlockStatus(bool value) async {
    setState(() => isLoading = true);

    final result = value
        ? await _chatApiService.blockUser(userId: widget.userId)
        : await _chatApiService.unblockUser(userId: widget.userId);

    result.fold(
      (data) {
        setState(() {
          isBlocked = value;
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBlocked ? 'User has been blocked' : 'User has been unblocked',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: isBlocked ? Colors.red : Colors.green,
            ),
          );
        }
      },
      (error) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Chat Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 32.h),

                  // User profile section
                  _buildUserProfile(),

                  SizedBox(height: 40.h),

                  // Block user option
                  _buildBlockUserOption(),

                  Divider(height: 1, color: Colors.grey[300]),

                  // Report option
                  _buildReportOption(),
                ],
              ),
            ),
          ),

          // Delete Chat button at bottom
          _buildDeleteChatButton(),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32.r,
            backgroundImage: NetworkImage(widget.userAvatar),
          ),

          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  widget.userName,
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                // Level badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Level ${widget.userLevel}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockUserOption() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Block User',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                isBlocked
                    ? 'Unblock to receive messages'
                    : 'Block to stop receiving messages',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: isBlocked,
                  onChanged: _toggleBlockStatus,
                  activeColor: Theme.of(context).primaryColor,
                ),
        ],
      ),
    );
  }

  Widget _buildReportOption() {
    return InkWell(
      onTap: () {
        // Handle report action
        _showReportDialog();
      },
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Report spam or abuse',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteChatButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            _showDeleteChatDialog();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outlined, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Delete Chat',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why are you reporting ${widget.userName}?'),
            SizedBox(height: 16.h),
            _buildReportOptionItem('Spam'),
            _buildReportOptionItem('Harassment'),
            _buildReportOptionItem('Inappropriate content'),
            _buildReportOptionItem('Other'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOptionItem(String reason) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report submitted: $reason'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, size: 20.sp, color: Colors.grey[600]),
            SizedBox(width: 12.w),
            Text(
              reason,
              style: TextStyle(fontSize: 15.sp, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteChatDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text(
          'Are you sure you want to delete this conversation with ${widget.userName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Capture the necessary values BEFORE closing the dialog
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final currentUserId = context.read<AuthBloc>().currentUser?.id;

              // Close dialog
              Navigator.pop(dialogContext);

              if (currentUserId == null) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Unable to delete: User not logged in'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Construct conversationId in format: userId1-userId2
              final conversationId = '$currentUserId-${widget.userId}';

              // Show loading indicator
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Deleting conversation...'),
                    ],
                  ),
                  duration: Duration(seconds: 3),
                ),
              );

              // Call delete conversation API
              final result = await _chatApiService.deleteConversation(
                conversationId: conversationId,
              );

              result.fold(
                (success) {
                  // Go back to chat list
                  navigator.pop(); // Close settings page
                  navigator.pop(); // Close chat detail page

                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Conversation deleted successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                (error) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $error'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
