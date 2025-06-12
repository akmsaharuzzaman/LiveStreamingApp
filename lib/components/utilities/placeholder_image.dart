// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:

import '../custom_widgets/fade_shmmer.dart';

class PlaceHolderImage extends StatelessWidget {
  final double height;
  final double width;
  final BoxShape shape;
  final BorderRadiusGeometry? borderRadius;
  const PlaceHolderImage({
    super.key,
    required this.height,
    required this.width,
    required this.shape,
    required this.borderRadius,
  });
  @override
  Widget build(BuildContext context) {
    return shape == BoxShape.circle
        ? FadeShimmer.round(
            size: height,
            highlightColor: Colors.pink,
            baseColor: Colors.black,
          )
        : FadeShimmer(
            width: width,
            height: height,
            highlightColor: Colors.pink,
            baseColor: Colors.black,
            borderRadius: borderRadius,
          );
  }
}
