import 'dart:math';
import 'dart:ui';

import 'package:dlstarlive/features/profile/presentation/widgets/user_profile_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svga/flutter_svga.dart';

import '../../data/models/chat_model.dart';

const String _defaultLevelBackgroundUrl =
    'https://res.cloudinary.com/dmpktzr0m/image/upload/v1758734670/level_tag_bg_assets/level_tag_bg_assets/e339ac59362bffeb805c4db58db2086e3494ace8b4670728f00748d7896dfc74.png';

const String _defaultLevelTagUrl =
    'https://res.cloudinary.com/dmpktzr0m/image/upload/v1758734667/level_tag_bg_assets/level_tag_bg_assets/20bbcd089e3948a2a5137dacd0af08cefcfe9c12ad0169014439022d68a4789a.png';

class AudioChatWidget extends StatefulWidget {
  final List<AudioChatModel> messages;
  final VoidCallback? onSendMessage;

  const AudioChatWidget({
    super.key,
    required this.messages,
    this.onSendMessage,
  });

  @override
  State<AudioChatWidget> createState() => _AudioChatWidgetState();
}

class _AudioChatWidgetState extends State<AudioChatWidget> {
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
  void didUpdateWidget(AudioChatWidget oldWidget) {
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
      // width: MediaQuery.of(context).size.width * 0.95,
      // height: MediaQuery.of(context).size.height * 0.20,
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

  Widget _buildChatMessage(AudioChatModel message) {
    // New design rules:
    // 1. Premium messages: solid (non-gradient) colored background + blur(5) + subtle radius (8)
    // 2. Normal messages: transparent (no background) just text (first line style in screenshot)
    // 3. If you later want a subtle glass background for normal, add a semi–transparent white here.

    final bool isPremium =
        message.equipedStoreItems?.isNotEmpty ??
        false; // Replace with actual premium check logic
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

    final levelBadge = _buildLevelBadge(message);

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Spacing before name/message
        const SizedBox(width: 8),
        if (levelBadge != null) ...[levelBadge, SizedBox(width: 8.w)],

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

  Widget? _buildLevelBadge(AudioChatModel message) {
    final int level = message.currentLevel ?? 0;
    if (level <= 0) {
      return null;
    }

    final double badgeHeight = 24.h;
    final double badgeWidth = 62.w;
    final double tagSize = 24.w;

    Widget buildBackground() {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Image.network(
          _defaultLevelBackgroundUrl,
          height: badgeHeight,
          width: badgeWidth,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) => Container(
            height: badgeHeight,
            width: badgeWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: const Color(0xFF5166C6),
            ),
          ),
        ),
      );
    }

    Widget buildTag() {
      return Image.network(
        _defaultLevelTagUrl,
        height: tagSize,
        width: tagSize,
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          height: tagSize,
          width: tagSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.r),
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: badgeHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          buildBackground(),
          Positioned(
            left: -12.w,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildTag(),
                SizedBox(width: 4.w),
                Text(
                  'Lv.$level',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EquippedItemBadge extends StatefulWidget {
  const _EquippedItemBadge({required this.url});

  final String url;

  @override
  State<_EquippedItemBadge> createState() => _EquippedItemBadgeState();
}

class _EquippedItemBadgeState extends State<_EquippedItemBadge>
    with SingleTickerProviderStateMixin {
  static const List<String> _imageExtensions = <String>[
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
    '.bmp',
  ];

  static const double _badgeSize = 18;

  SVGAAnimationController? _svgaController;
  bool _isImage = false;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  @override
  void didUpdateWidget(covariant _EquippedItemBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _isLoading = true;
      _hasError = false;
      _loadAsset();
    }
  }

  Future<void> _loadAsset() async {
    final String lowerUrl = widget.url.toLowerCase();
    _isImage = _imageExtensions.any(lowerUrl.endsWith);

    if (_isImage) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final SVGAAnimationController controller = SVGAAnimationController(
        vsync: this,
      );
      final movie = await SVGAParser.shared.decodeFromURL(widget.url);

      if (!mounted) {
        controller.dispose();
        return;
      }

      controller.videoItem = movie;
      controller.repeat();
      _svgaController = controller;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading SVGA equipped item: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    _svgaController?.stop();
    _svgaController?.dispose();
    _svgaController = null;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child = SizedBox(
        height: _badgeSize,
        width: _badgeSize,
        child: const Center(
          child: SizedBox(
            height: 12,
            width: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      );
    } else if (_hasError) {
      child = Container(
        height: _badgeSize,
        width: _badgeSize,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Icon(Icons.error_outline, size: 12, color: Colors.white54),
      );
    } else if (_isImage) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.network(
          widget.url,
          height: _badgeSize,
          width: _badgeSize,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              height: _badgeSize,
              width: _badgeSize,
              child: const Center(
                child: SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading equipped image item: $error');
            return Container(
              height: _badgeSize,
              width: _badgeSize,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 12,
                color: Colors.white54,
              ),
            );
          },
        ),
      );
    } else if (_svgaController != null) {
      child = SizedBox(
        height: _badgeSize,
        width: _badgeSize,
        child: SVGAImage(
          _svgaController!,
          fit: BoxFit.cover,
          clearsAfterStop: false,
        ),
      );
    } else {
      child = Container(
        height: _badgeSize,
        width: _badgeSize,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Icon(
          Icons.image_not_supported,
          size: 12,
          color: Colors.white54,
        ),
      );
    }

    return SizedBox(height: _badgeSize, width: _badgeSize, child: child);
  }
}
