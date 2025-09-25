import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svga/flutter_svga.dart';

import '../../../../core/network/models/gift_model.dart';

class AnimatedLayer extends StatefulWidget {
  const AnimatedLayer({
    super.key,
    required this.gifts,
    this.customAnimationUrl,
    this.customTitle,
    this.customSubtitle,
  });
  final List<GiftModel> gifts;
  final String? customAnimationUrl;
  final String? customTitle;
  final String? customSubtitle;

  @override
  State<AnimatedLayer> createState() => _AnimatedLayerState();
}

class _AnimatedLayerState extends State<AnimatedLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000), // 7 seconds duration
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Start the animation
    _controller.forward();

    // Auto-hide after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Start fade out animation
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCustomAnimation =
        (widget.customAnimationUrl != null &&
        widget.customAnimationUrl!.isNotEmpty);

    if (!hasCustomAnimation && widget.gifts.isEmpty) {
      return const SizedBox.shrink();
    }

    final GiftModel? lastGift = widget.gifts.isNotEmpty
        ? widget.gifts.last
        : null;
    final String animationUrl = hasCustomAnimation
        ? widget.customAnimationUrl!
        : (lastGift?.gift.svgaImage ?? '');

    if (animationUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final String? titleText = hasCustomAnimation
        ? widget.customTitle
        : (lastGift != null
              ? '${lastGift.name} sent ${lastGift.gift.name}'
              : null);
    final String? subtitleText = hasCustomAnimation
        ? widget.customSubtitle
        : (lastGift != null ? '${lastGift.diamonds} diamonds' : null);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _opacityAnimation.value,
          child: Stack(
            children: [
              // Fullscreen SVGA animation
              Positioned.fill(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SVGAEasyPlayer(
                    resUrl: animationUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Text overlay on top
              if (titleText != null || subtitleText != null)
                Positioned(
                  top:
                      MediaQuery.of(context).size.height * 0.40, // 40% from top
                  left: 20.w,
                  right: 20.w,
                  child: Column(
                    children: [
                      if (titleText != null)
                        Text(
                          titleText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 6,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      if (subtitleText != null) ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            subtitleText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.yellow,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              shadows: const [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
