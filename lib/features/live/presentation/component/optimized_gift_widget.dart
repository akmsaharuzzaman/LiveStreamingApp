import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/network/models/gift_model.dart';

/// Optimized gift display widget with two-stage loading:
/// 1. Fast preview image loading using CachedNetworkImage
/// 2. SVGA animation loading only when selected
class OptimizedGiftWidget extends StatefulWidget {
  final Gift gift;
  final bool isSelected;
  final VoidCallback? onTap;
  final Set<String> preloadedAnimations;
  final Function(String giftId)? onAnimationPreload;

  const OptimizedGiftWidget({
    super.key,
    required this.gift,
    required this.isSelected,
    this.onTap,
    required this.preloadedAnimations,
    this.onAnimationPreload,
  });

  @override
  State<OptimizedGiftWidget> createState() => _OptimizedGiftWidgetState();
}

class _OptimizedGiftWidgetState extends State<OptimizedGiftWidget> {
  bool _showAnimation = false;

  @override
  void didUpdateWidget(OptimizedGiftWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If gift becomes selected and animation is preloaded, show animation
    if (widget.isSelected &&
        !oldWidget.isSelected &&
        widget.preloadedAnimations.contains(widget.gift.id)) {
      setState(() {
        _showAnimation = true;
      });
    }

    // If gift becomes unselected, hide animation
    if (!widget.isSelected && oldWidget.isSelected) {
      setState(() {
        _showAnimation = false;
      });
    }

    // Preload animation when selected
    if (widget.isSelected &&
        !oldWidget.isSelected &&
        !widget.preloadedAnimations.contains(widget.gift.id)) {
      widget.onAnimationPreload?.call(widget.gift.id);

      // Show animation after a short delay to allow preloading
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && widget.isSelected) {
          setState(() {
            _showAnimation = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
              : null,
          borderRadius: BorderRadius.circular(12.r),
          border: widget.isSelected
              ? Border.all(color: const Color(0xFFE91E63), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Optimized gift image display
            SizedBox(
              height: 52.h,
              width: 52.w,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: _buildGiftImage(),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              widget.gift.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.diamond, color: Colors.blue, size: 10.sp),
                SizedBox(width: 2.w),
                Text(
                  widget.gift.coinPrice.toString(),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftImage() {
    // Show SVGA animation if selected and preloaded/ready
    if (widget.isSelected &&
        _showAnimation &&
        widget.gift.svgaImage.isNotEmpty) {
      return SVGAEasyPlayer(resUrl: widget.gift.svgaImage, fit: BoxFit.cover);
    }

    // Otherwise show cached preview image for fast loading
    final imageUrl = widget.gift.previewImage.isNotEmpty
        ? widget.gift.previewImage
        : widget.gift.svgaImage; // Fallback to SVGA if no preview

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[700],
        child: Icon(
          Icons.card_giftcard,
          color: Colors.white54,
          size: 24.sp,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[700],
        child: Icon(
          Icons.card_giftcard,
          color: Colors.white54,
          size: 24.sp,
        ),
      ),
    );
  }
}
