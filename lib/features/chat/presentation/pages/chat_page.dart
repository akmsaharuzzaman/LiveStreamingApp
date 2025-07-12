import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/chat_models.dart';
import '../bloc/chat_bloc.dart';
import '../../../../core/auth/auth_bloc.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load conversations when page is initialized
    _refreshConversations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh conversations when returning to this page
    _refreshConversations();
  }

  void _refreshConversations() {
    // Only refresh if we're not already loading
    final chatState = context.read<ChatBloc>().state;
    if (chatState is! ChatLoading) {
      context.read<ChatBloc>().add(const LoadConversationsEvent());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search not implemented yet')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              // Implement more options
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('More options not implemented yet'),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'All Chats'),
            Tab(text: 'Groups'),
            Tab(text: 'Calls'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Chats Tab
          _buildAllChatsTab(),
          // Groups Tab
          _buildGroupsTab(),
          // Calls Tab
          _buildCallsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement new chat functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New chat not implemented yet')),
          );
        },
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildAllChatsTab() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ChatError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  'Error Loading Chats',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    context.read<ChatBloc>().add(
                      const LoadConversationsEvent(),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is ChatConversationsLoaded) {
          final conversations = state.conversations;
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ChatBloc>().add(const LoadConversationsEvent());
              // Wait for the loading to complete
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: _buildConversationList(conversations),
          );
        } else {
          // Initial state or other states - load conversations
          _refreshConversations();
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildConversationList(List<Conversation> conversations) {
    // Get current user ID from AuthBloc
    final currentUserId = context.read<AuthBloc>().currentUser?.id;

    // Convert API conversations to display format
    final displayChats = conversations.map((conversation) {
      // Show the OTHER person's information (not the sender)
      // If I'm the sender, show receiver info; if I'm the receiver, show sender info
      final isCurrentUserSender = conversation.sender?.id == currentUserId;
      final otherUser = isCurrentUserSender
          ? conversation.receiver
          : conversation.sender;

      return ChatConversation(
        id: conversation.id,
        sender: otherUser, // Show the other person's info
        text: conversation.lastMessage,
        time: _formatTime(conversation.updatedAt),
        unreadCount: conversation.seenStatus ? 0 : 1,
        avatar: otherUser?.avatar ?? '',
        lastMessageTime: conversation.updatedAt,
      );
    }).toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Chats Section
          Text(
            'Recent',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),

          // Chat List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<ChatBloc>().add(const RefreshConversationsEvent());
              },
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: displayChats.length,
                itemBuilder: (context, index) {
                  final chat = displayChats[index];
                  return _buildChatListItem(chat);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListItem(ChatConversation chat) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.h),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28.r,
              backgroundImage: NetworkImage(chat.avatar),
              onBackgroundImageError: (error, stackTrace) {
                debugPrint('Error loading image: $error');
              },
            ),
            if (chat.sender?.isOnline == true)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          chat.sender?.name ?? "",
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          chat.text ?? "",
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              chat.time ?? "",
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            ),
            SizedBox(height: 4.h),
            if (chat.unreadCount > 0)
              CircleAvatar(
                radius: 10.r,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  chat.unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(Icons.done_all, color: Colors.blue, size: 16.sp),
          ],
        ),
        onTap: () {
          // Pass the other user's ID and their information
          context.push(
            '/chat-details/${chat.sender!.id}',
            extra: {
              'userName': chat.sender!.name,
              'userAvatar': chat.sender!.avatar,
              'userEmail': chat.sender!.email,
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildGroupsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 80.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No Groups Yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Create or join groups to start chatting',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call, size: 80.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No Recent Calls',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your call history will appear here',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
