import 'dart:math';

import 'package:flutter/material.dart';

class ChatBadge {
  final String type; // 'level', 'vip', 'crown', 'fire', etc.
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  ChatBadge({
    required this.type,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });
}

class ChatMessage {
  final String id;
  final String userName;
  final String message;
  final DateTime timestamp;
  final String? userAvatar;
  final List<ChatBadge> badges;

  ChatMessage({
    required this.id,
    required this.userName,
    required this.message,
    required this.timestamp,
    this.userAvatar,
    this.badges = const [],
  });

  // Check if user is premium based on having badges
  bool get isPremium => badges.isNotEmpty;
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
  final Map<String, Color> _userColorCache = {};

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

  // Generate consistent random color for each user
  Color _getRandomColorForUser(String userName) {
    if (_userColorCache.containsKey(userName)) {
      return _userColorCache[userName]!;
    }

    // Use username hash for consistent color generation
    final hash = userName.hashCode;
    final random = Random(hash);

    // Premium color palettes
    final colorPalettes = [
      [const Color(0xFF1B1E48), const Color(0xFF825CB3)], // Purple gradient
      [const Color(0xFF2D1B69), const Color(0xFF11998E)], // Teal gradient
      [const Color(0xFF834D9B), const Color(0xFFD04ED6)], // Pink gradient
      [
        const Color(0xFF667EEA),
        const Color(0xFF764BA2),
      ], // Blue-purple gradient
      [const Color(0xFFE44D26), const Color(0xFFF16529)], // Orange gradient
      [const Color(0xFF11998E), const Color(0xFF38EF7D)], // Green gradient
      [
        const Color(0xFF3A1C71),
        const Color(0xFFD76D77),
      ], // Purple-pink gradient
      [const Color(0xFF1E3C72), const Color(0xFF2A5298)], // Dark blue gradient
      [const Color(0xFFFF512F), const Color(0xFFDD2476)], // Red-pink gradient
      [const Color(0xFF6A3093), const Color(0xFFA044FF)], // Purple gradient
    ];

    final selectedPalette = colorPalettes[random.nextInt(colorPalettes.length)];
    _userColorCache[userName] =
        selectedPalette[0]; // Store first color as reference

    return selectedPalette[0];
  }

  List<Color> _getGradientColorsForUser(String userName) {
    // Use username hash for consistent color generation
    final hash = userName.hashCode;
    final random = Random(hash);

    // Premium color palettes
    final colorPalettes = [
      [const Color(0xFF1B1E48), const Color(0xFF825CB3)], // Purple gradient
      [const Color(0xFF2D1B69), const Color(0xFF11998E)], // Teal gradient
      [const Color(0xFF834D9B), const Color(0xFFD04ED6)], // Pink gradient
      [
        const Color(0xFF667EEA),
        const Color(0xFF764BA2),
      ], // Blue-purple gradient
      [const Color(0xFFE44D26), const Color(0xFFF16529)], // Orange gradient
      [const Color(0xFF11998E), const Color(0xFF38EF7D)], // Green gradient
      [
        const Color(0xFF3A1C71),
        const Color(0xFFD76D77),
      ], // Purple-pink gradient
      [const Color(0xFF1E3C72), const Color(0xFF2A5298)], // Dark blue gradient
      [const Color(0xFFFF512F), const Color(0xFFDD2476)], // Red-pink gradient
      [const Color(0xFF6A3093), const Color(0xFFA044FF)], // Purple gradient
    ];

    return colorPalettes[random.nextInt(colorPalettes.length)];
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: message.isPremium
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColorsForUser(message.userName),
                )
              : null,
          color: message.isPremium ? null : Colors.transparent,
          boxShadow: message.isPremium
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Badges (Level, VIP, etc.)
            ...message.badges.map((badge) => _buildBadge(badge)),
            if (message.badges.isNotEmpty) const SizedBox(width: 8),

            // User Avatar
            CircleAvatar(
              radius: 14,
              backgroundImage: message.userAvatar != null
                  ? NetworkImage(message.userAvatar!)
                  : null,
              backgroundColor: message.isPremium
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey[600],
              child: message.userAvatar == null
                  ? Text(
                      message.userName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: message.isPremium ? Colors.white : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),

            // Message content
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${message.userName}: ",
                      style: TextStyle(
                        color: message.isPremium
                            ? Colors.white
                            : Colors.grey[300],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: message.message,
                      style: TextStyle(
                        color: message.isPremium
                            ? Colors.white.withOpacity(0.95)
                            : Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(ChatBadge badge) {
    Widget badgeContent;

    switch (badge.type) {
      case 'level':
        badgeContent = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badge.backgroundColor ?? const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Text(
            badge.text,
            style: TextStyle(
              color: badge.textColor ?? Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        break;

      case 'vip':
        badgeContent = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Text(
            badge.text,
            style: TextStyle(
              color: badge.textColor ?? Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        break;

      case 'crown':
        badgeContent = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: badge.backgroundColor ?? const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Icon(
            Icons.star,
            color: badge.textColor ?? Colors.white,
            size: 16,
          ),
        );
        break;

      case 'fire':
        badgeContent = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: badge.backgroundColor ?? const Color(0xFFFF6B6B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Icon(
            Icons.local_fire_department,
            color: badge.textColor ?? Colors.white,
            size: 16,
          ),
        );
        break;

      default:
        badgeContent = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badge.backgroundColor ?? Colors.grey[600],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Text(
            badge.text,
            style: TextStyle(
              color: badge.textColor ?? Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }

    return badgeContent;
  }
}
