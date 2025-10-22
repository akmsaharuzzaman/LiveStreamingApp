import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import '../../data/models/chat_models.dart';
import '../../data/services/chat_api_service.dart';
import '../../data/services/chat_utils.dart';
import '../bloc/chat_detail_bloc.dart';
import 'chat_user_settings_page.dart';

class ChatDetailPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? userInfo;

  const ChatDetailPage({super.key, required this.userId, this.userInfo});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatUser chatUser;
  bool _isSending = false; // Track if a message is currently being sent
  bool _isBlocked = false; // Track if user is blocked
  final ChatApiService _chatApiService = GetIt.instance<ChatApiService>();
  Timer? _autoRefreshTimer; // Timer for auto-refresh
  late final String roomId;

  @override
  void initState() {
    super.initState();
    roomId = ChatUtils.roomIdFromUserIds(
      context.read<AuthBloc>().currentUser!.id,
      widget.userId,
    );

    // Use passed user info if available, otherwise create a basic ChatUser
    if (widget.userInfo != null) {
      chatUser = ChatUser(
        id: widget.userId,
        name: widget.userInfo!['userName'] ?? 'Unknown User',
        email: widget.userInfo!['userEmail'] ?? 'unknown@example.com',
        avatar:
            widget.userInfo!['userAvatar'] ?? 'https://i.pravatar.cc/150?img=8',
        isOnline: true, // Assume online when coming from profile
      );
    } else {
      // Create a basic ChatUser when no user info is passed
      chatUser = ChatUser(
        id: widget.userId,
        name: 'Unknown User',
        email: 'unknown@example.com',
        avatar: 'https://i.pravatar.cc/150?img=8',
      );
    }

    // Load block status
    _loadBlockStatus();

    // Load messages for this user
    context.read<ChatDetailBloc>().add(LoadMessagesEvent(otherUserId: roomId));

    // Mark messages as seen when entering the chat
    final currentUserId = context.read<AuthBloc>().currentUser?.id;
    if (currentUserId != null) {
      context.read<ChatDetailBloc>().add(
        MarkMessagesSeenEvent(
          senderId: widget.userId, // The other user (sender)
          receiverId: currentUserId, // Current user (receiver)
        ),
      );
    }

    // Start auto-refresh timer (refresh every 5 seconds)
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel(); // Cancel any existing timer
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        // Refresh messages in background without showing loading
        context.read<ChatDetailBloc>().add(
          RefreshMessagesEvent(otherUserId: roomId),
        );
      }
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  Future<void> _loadBlockStatus() async {
    final result = await _chatApiService.getBlockStatus(userId: widget.userId);

    result.fold(
      (isBlocked) {
        if (mounted) {
          setState(() {
            _isBlocked = isBlocked;
          });
        }
      },
      (error) {
        // Handle error silently
      },
    );
  }

  @override
  void dispose() {
    _stopAutoRefresh(); // Stop the timer
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (!_isSending && text.trim().isNotEmpty) {
      setState(() {
        _isSending = true;
      });
      context.read<ChatDetailBloc>().add(
        SendMessageEvent(receiverId: widget.userId, text: text.trim()),
      );
    }
  }

  void _showDeleteMessageDialog(String messageId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
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
              final chatDetailBloc = context.read<ChatDetailBloc>();

              // Close dialog
              Navigator.pop(dialogContext);

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
                      Text('Deleting message...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );

              // Call delete API
              final result = await _chatApiService.deleteMessage(
                messageId: messageId,
              );

              result.fold(
                (success) {
                  // Refresh messages after deletion
                  chatDetailBloc.add(RefreshMessagesEvent(otherUserId: roomId));

                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Message deleted successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                (error) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete message: $error'),
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

  Widget _buildMessagesArea(List<ChatMessage> messages) {
    // Get current user ID from AuthBloc instead of dummy data
    final currentUserId = context.read<AuthBloc>().currentUser?.id;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, int index) {
          final message = messages[index];
          // Use actual current user ID instead of dummy currentUser
          bool isMe = message.sender?.id == currentUserId;
          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: isMe
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMe)
                      Container(
                        margin: EdgeInsets.only(right: 8.w),
                        child: CircleAvatar(
                          radius: 16.r,
                          backgroundImage: NetworkImage(chatUser.avatar),
                        ),
                      ),
                    GestureDetector(
                      onLongPress: isMe
                          ? () => _showDeleteMessageDialog(message.id)
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.r),
                            topRight: Radius.circular(20.r),
                            bottomLeft: isMe
                                ? Radius.circular(20.r)
                                : Radius.circular(4.r),
                            bottomRight: isMe
                                ? Radius.circular(4.r)
                                : Radius.circular(20.r),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.time,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                // Show tick indicators only for messages sent by current user
                                if (isMe) ...[
                                  SizedBox(width: 4.w),
                                  Icon(
                                    message.seen
                                        ? Icons
                                              .done_all // Double tick when seen
                                        : Icons
                                              .done, // Single tick when sent but not seen
                                    size: 14.sp,
                                    color: message.seen
                                        ? Colors
                                              .blue // Blue when seen
                                        : Colors
                                              .grey[600], // Grey when not seen
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isMe)
                      Container(
                        margin: EdgeInsets.only(left: 8.w),
                        child: CircleAvatar(
                          radius: 16.r,
                          backgroundImage: NetworkImage(
                            context.read<AuthBloc>().currentUser?.avatar ??
                                'https://i.pravatar.cc/150?img=1',
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundImage: NetworkImage(chatUser.avatar),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatUser.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    chatUser.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: chatUser.isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {
              // Handle video call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call not implemented yet')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // Handle voice call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call not implemented yet')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () async {
              // Navigate to chat user settings page
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatUserSettingsPage(
                    userId: widget.userId,
                    userName: chatUser.name,
                    userAvatar: chatUser.avatar,
                    userLevel:
                        15, // You can pass actual level from chatUser if available
                  ),
                ),
              );
              // Reload block status when returning from settings
              _loadBlockStatus();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: BlocBuilder<ChatDetailBloc, ChatDetailState>(
              builder: (context, state) {
                if (state is ChatDetailLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ChatDetailMessagesLoaded) {
                  return _buildMessagesArea(state.messages);
                } else if (state is ChatDetailError) {
                  // Handle different error scenarios
                  if (state.message.contains('Conversation not found') ||
                      state.message.contains('404')) {
                    // Show "no messages yet" for 404 errors
                    return Center(child: SizedBox.shrink());
                  } else {
                    // Show generic error for other types of errors
                    return Center(child: SizedBox.shrink());
                  }
                } else {
                  // Initial state - show empty state
                  return Center(child: SizedBox.shrink());
                }
              },
            ),
          ),
          BlocListener<ChatDetailBloc, ChatDetailState>(
            listener: (context, state) {
              if (state is ChatDetailSendingMessage) {
                // Message is being sent - keep _isSending true
              } else if (state is ChatDetailMessageSent) {
                setState(() {
                  _isSending = false;
                });
                _messageController.clear();
                // ScaffoldMessenger.of(
                //   context,
                // ).showSnackBar(const SnackBar(content: Text('Message sent!')));
              } else if (state is ChatDetailError) {
                setState(() {
                  _isSending = false;
                });
                // Show error message to user
                if (kDebugMode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send message: ${state.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: _isBlocked ? _buildBlockedMessage() : _buildMessageInput(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedMessage() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.block, color: Colors.red[700], size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'You cannot send messages to this user because they are blocked.',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.attach_file, color: Colors.grey),
          onPressed: () {
            // Handle file attachment
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File attachment not implemented yet'),
              ),
            );
          },
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.h,
                  horizontal: 0,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              enabled: !_isSending, // Disable input while sending
              onSubmitted: (text) {
                if (text.trim().isNotEmpty && !_isSending) {
                  _sendMessage(text.trim());
                }
              },
              textInputAction: TextInputAction.send,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          decoration: BoxDecoration(
            color: _isSending ? Colors.grey : Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: IconButton(
            icon: _isSending
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white),
            onPressed: _isSending
                ? null
                : () {
                    final text = _messageController.text.trim();
                    if (text.isNotEmpty) {
                      _sendMessage(text);
                    }
                  },
          ),
        ),
      ],
    );
  }
}
