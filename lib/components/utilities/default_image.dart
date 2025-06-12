// Flutter imports:
import 'package:flutter/material.dart';
// Project imports:

// Project imports:

class DefaultImage extends StatelessWidget {
  final double height;
  final double width;
  final EdgeInsetsGeometry? margin;
  final BoxShape shape;
  final BorderRadiusGeometry? borderRadius;
  final Widget? childInAvatar;
  const DefaultImage({
    super.key,
    required this.height,
    required this.width,
    required this.margin,
    required this.shape,
    this.borderRadius,
    this.childInAvatar,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: borderRadius,
        image: DecorationImage(
          image: const AssetImage(
            '',
          ),
          fit: shape == BoxShape.circle ? BoxFit.fitHeight : BoxFit.contain,
        ),
      ),
      alignment: Alignment.bottomRight,
      child: childInAvatar,
    );
  }
}
