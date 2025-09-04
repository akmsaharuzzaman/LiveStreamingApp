import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/chat_models.dart';
import '../bloc/chat_detail_bloc.dart';

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
  @override
  void initState() {
    super.initState();

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

    // Load messages for this user
    context.read<ChatDetailBloc>().add(
      LoadMessagesEvent(otherUserId: widget.userId),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    context.read<ChatDetailBloc>().add(
      SendMessageEvent(receiverId: widget.userId, text: text),
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
                    Container(
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
                          Text(
                            message.time,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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
          icon: const Icon(Icons.arrow_back),
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
            onPressed: () {
              // Handle more options
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('More options not implemented yet'),
                ),
              );
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_outlined,
                            size: 80.sp,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Start the conversation by sending a message',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Show generic error for other types of errors
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 16.h),
                          Text(
                            'No messages available',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            state.message,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ChatDetailBloc>().add(
                                LoadMessagesEvent(otherUserId: widget.userId),
                              );
                            },
                            child: const Text('Refresh Messages'),
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  // Initial state - show empty state
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 80.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Start the conversation by sending a message',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          BlocListener<ChatDetailBloc, ChatDetailState>(
            listener: (context, state) {
              if (state is ChatDetailMessageSent) {
                _messageController.clear();
                // ScaffoldMessenger.of(
                //   context,
                // ).showSnackBar(const SnackBar(content: Text('Message sent!')));
              } else if (state is ChatDetailError) {
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(content: Text('Error: ${state.message}')),
                // );
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
              child: Row(
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
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
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
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        final text = _messageController.text.trim();
                        if (text.isNotEmpty) {
                          _sendMessage(text);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
