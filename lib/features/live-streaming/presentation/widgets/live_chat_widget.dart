import 'package:flutter/material.dart';

class ChatMessage {
  final String id;
  final String userName;
  final String message;
  final DateTime timestamp;
  final String? userAvatar;
  final int level;
  final bool isVip;

  ChatMessage({
    required this.id,
    required this.userName,
    required this.message,
    required this.timestamp,
    this.userAvatar,
    this.level = 1,
    this.isVip = false,
  });
}

class LiveChatWidget extends StatefulWidget {
  final List<ChatMessage> messages;
  final VoidCallback? onSendMessage;

  const LiveChatWidget({super.key, required this.messages, this.onSendMessage});

  @override
  State<LiveChatWidget> createState() => _LiveChatWidgetState();
}

class _LiveChatWidgetState extends State<LiveChatWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(LiveChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      // Auto-scroll to bottom when new message is added
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.95,
      height: MediaQuery.of(context).size.height * 0.35,
      child: widget.messages.isEmpty
          ? const SizedBox.shrink()
          : ListView.builder(
              controller: _scrollController,
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final message = widget.messages[index];
                return _buildChatMessage(message);
              },
            ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          // Linear gradient matching Figma properties
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B1E48), // #1B1E48
              Color(0xFF825CB3), // #825CB3
            ],
          ),
          // Background blur effect (Figma shows blur: 5)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar
              CircleAvatar(
                radius: 12,
                backgroundImage: message.userAvatar != null
                    ? NetworkImage(message.userAvatar!)
                    : null,
                backgroundColor: Colors.grey[600],
                child: message.userAvatar == null
                    ? Text(
                        message.userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),

              // Message content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User name with level and VIP indicators
                    Row(
                      children: [
                        // Level indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor(message.level),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Lv${message.level}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // VIP indicator
                        if (message.isVip)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'SVIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),

                        // User name
                        Flexible(
                          child: Text(
                            "${message.userName}:",
                            style: TextStyle(
                              color: message.isVip
                                  ? const Color(0xFFFFD700)
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Message text
                        Text(
                          message.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level >= 20) return const Color(0xFFFF6B6B); // Red for high levels
    if (level >= 15) return const Color(0xFFFF8E53); // Orange
    if (level >= 10) return const Color(0xFF4ECDC4); // Teal
    if (level >= 5) return const Color(0xFF45B7D1); // Blue
    return const Color(0xFF96CEB4); // Green for low levels
  }
}
