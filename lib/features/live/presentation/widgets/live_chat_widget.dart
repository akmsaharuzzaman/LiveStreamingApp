import 'dart:math';
import 'dart:ui';

import 'package:dlstarlive/core/network/models/chat_model.dart';
import 'package:dlstarlive/features/profile/presentation/pages/view_user_profile.dart';
import 'package:dlstarlive/features/profile/presentation/widgets/user_profile_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LiveChatWidget extends StatefulWidget {
  final List<ChatModel> messages;
  final bool? isCallingNow;
  final VoidCallback? onSendMessage;

  const LiveChatWidget({super.key, required this.messages, this.onSendMessage, this.isCallingNow});

  @override
  State<LiveChatWidget> createState() => _LiveChatWidgetState();
}

class _LiveChatWidgetState extends State<LiveChatWidget> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, Color> _userColorCache = {};
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _lastMessageCount = widget.messages.length;
    // If there are already messages, ensure we start scrolled to bottom
    if (_lastMessageCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void didUpdateWidget(LiveChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detect growth even if the same List instance was mutated
    if (widget.messages.length > _lastMessageCount) {
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
    _lastMessageCount = widget.messages.length;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * (widget.isCallingNow == true ? 0.65 : 0.95),
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

  Widget _buildChatMessage(ChatModel message) {
    // New design rules:
    // 1. Premium messages: solid (non-gradient) colored background + blur(5) + subtle radius (8)
    // 2. Normal messages: transparent (no background) just text (first line style in screenshot)
    // 3. If you later want a subtle glass background for normal, add a semi–transparent white here.

    final bool isPremium =
        message.id == "premium"; // Replace with actual premium check logic
    final BorderRadius radius = BorderRadius.circular(
      8,
    ); // simplified radius like screenshot

    // Derive a deterministic color for premium user (slightly warm / badge based) with opacity
    Color premiumBase = _getRandomColorForUser(message.name);
    // Ensure it's not too dark; blend with a warm accent
    premiumBase = Color.alphaBlend(
      const Color(0xFFCD985F).withValues(alpha: 0.5),
      premiumBase.withValues(alpha: 0.5),
    );
    final Color premiumBackground = premiumBase.withValues(alpha: 0.5);

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Spacing before name/message
        const SizedBox(width: 6),

        const SizedBox(width: 8),

        // Message content with flexible width
        Flexible(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "${message.name}: ",
                  style: TextStyle(
                    color: isPremium ? Colors.white : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700, // bolder like screenshot
                  ),
                ),
                TextSpan(
                  text: message.text,
                  style: TextStyle(
                    color: isPremium
                        ? Colors.white.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.visible,
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
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => UserProfileBottomSheet(userId: message.id),
          );
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: IntrinsicWidth(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width * 0.8, // Max 80% width
                minHeight: 40.h,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  // Badge builder removed (unused in current design)
}
