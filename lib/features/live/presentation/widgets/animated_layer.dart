import 'package:flutter/material.dart';
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
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
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
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gift animation
                  SVGAEasyPlayer(
                    resUrl: lastGift.gift.svgaImage,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 10),

                  // Gift details - simple text overlay
                  Text(
                    '${lastGift.name} sent ${lastGift.gift.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lastGift.diamonds} diamonds',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
