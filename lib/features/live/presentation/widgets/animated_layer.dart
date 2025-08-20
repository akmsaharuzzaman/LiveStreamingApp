import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svga/flutter_svga.dart';

import '../../../../core/network/models/gift_model.dart';

class AnimatedLayer extends StatefulWidget {
  const AnimatedLayer({super.key, required this.gifts});
  final List<GiftModel> gifts;

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
    // Only show the animation layer if there are gifts
    if (widget.gifts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the last gift sent
    final lastGift = widget.gifts.last;

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
                    resUrl: lastGift.gift.svgaImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Text overlay on top
              Positioned(
                top: 100.h, // Adjust position as needed
                left: 20.w,
                right: 20.w,
                child: Column(
                  children: [
                    Text(
                      '${lastGift.name} sent ${lastGift.gift.name}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${lastGift.diamonds} diamonds',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
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
