import 'dart:math';
import 'dart:ui';

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

  // _getGradientColorsForUser removed (no longer using gradients in new design)

  Widget _buildChatMessage(ChatMessage message) {
    // New design rules:
    // 1. Premium messages: solid (non-gradient) colored background + blur(5) + subtle radius (8)
    // 2. Normal messages: transparent (no background) just text (first line style in screenshot)
    // 3. If you later want a subtle glass background for normal, add a semi–transparent white here.

    final bool isPremium = message.isPremium;
    final BorderRadius radius = BorderRadius.circular(
      8,
    ); // simplified radius like screenshot

    // Derive a deterministic color for premium user (slightly warm / badge based) with opacity
    Color premiumBase = _getRandomColorForUser(message.userName);
    // Ensure it's not too dark; blend with a warm accent
    premiumBase = Color.alphaBlend(
      const Color(0xFFCD985F).withValues(alpha: 0.55),
      premiumBase.withValues(alpha: 0.85),
    );
    final Color premiumBackground = premiumBase.withValues(alpha: 0.85);

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Badges (Level, VIP, etc.)
        ...message.badges.map((badge) => _buildBadge(badge)),
        if (message.badges.isNotEmpty) const SizedBox(width: 6),

        // User Avatar
        CircleAvatar(
          radius: 14,
          backgroundImage: message.userAvatar != null
              ? NetworkImage(message.userAvatar!)
              : null,
          backgroundColor: isPremium
              ? Colors.white.withValues(alpha:0.25)
              : Colors.grey[600]?.withValues(alpha:0.5),
          child: message.userAvatar == null
              ? Text(
                  message.userName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),

        // Message content
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "${message.userName}: ",
                  style: TextStyle(
                    color: isPremium ? Colors.white : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700, // bolder like screenshot
                  ),
                ),
                TextSpan(
                  text: message.message,
                  style: TextStyle(
                    color: isPremium
                        ? Colors.white.withValues(alpha:0.95)
                        : Colors.white.withValues(alpha:0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (isPremium) {
      // Apply blur & background
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: premiumBackground,
              borderRadius: radius,
            ),
            child: content,
          ),
        ),
      );
    } else {
      // Normal message – no background (matches first & normal user rows)
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: content,
    );
  }

  Widget _buildBadge(ChatBadge badge) {
    Widget badgeContent;

    switch (badge.type) {
      case 'level':
        badgeContent = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          // Simplified radius to match chat bubble style
          decoration: BoxDecoration(
            color: badge.backgroundColor ?? const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(6),
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
            color: const Color(0xFFFFB84D),
            borderRadius: BorderRadius.circular(6),
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
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.star,
            color: badge.textColor ?? Colors.white,
            size: 14,
          ),
        );
        break;

      case 'fire':
        badgeContent = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: badge.backgroundColor ?? const Color(0xFFFF6B6B),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.local_fire_department,
            color: badge.textColor ?? Colors.white,
            size: 14,
          ),
        );
        break;

      default:
        badgeContent = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badge.backgroundColor ?? Colors.grey[600],
            borderRadius: BorderRadius.circular(6),
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
