// Flutter imports:
// Package imports:
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CustomNetworkImage extends StatelessWidget {
  final String? urlToImage;
  final double? height;
  final double? width;
  final BoxShape shape;
  final BoxFit? fit;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final Widget? placeholderWidget;
  final ColorFilter? colorFilter;
  final Widget? childInAvatar;
  // ignore: use_key_in_widget_constructors
  const CustomNetworkImage({
    Key? key,
    required this.urlToImage,
    this.height,
    this.width,
    this.shape = BoxShape.circle,
    this.fit = BoxFit.cover,
    this.margin,
    this.borderRadius,
    this.placeholderWidget,
    this.colorFilter,
    this.childInAvatar,
  }) : assert(height != null || width != null);
  @override
  Widget build(BuildContext context) {
    return urlToImage == null
        ? placeholderWidget ??
              Container(
                height: height ?? width!,
                width: width ?? height!,
                margin: margin,
                decoration: BoxDecoration(
                  shape: shape,
                  borderRadius: borderRadius,
                  color: Colors.grey[300],
                ),
              )
        : CachedNetworkImage(
            cacheKey: urlToImage,
            memCacheHeight: 1024 * 200,
            memCacheWidth: 1024 * 200,
            maxWidthDiskCache: 1024 * 1024,
            maxHeightDiskCache: 1024 * 1024,
            placeholderFadeInDuration: const Duration(milliseconds: 10),
            fadeInDuration: const Duration(milliseconds: 10),
            fadeOutDuration: const Duration(milliseconds: 10),
            imageUrl: urlToImage!,
            imageBuilder: (context, imageProvider) => Container(
              height: height ?? width!,
              width: width ?? height!,
              margin: margin,
              decoration: BoxDecoration(
                shape: shape,
                borderRadius: borderRadius,
                image: DecorationImage(
                  colorFilter: colorFilter,
                  image: imageProvider,
                  fit: fit,
                  filterQuality: FilterQuality.low,
                ),
              ),
              alignment: Alignment.bottomRight,
              child: childInAvatar,
            ),
            placeholder: (context, url) =>
                placeholderWidget ??
                Container(
                  height: height ?? width!,
                  width: width ?? height!,
                  margin: margin,
                  decoration: BoxDecoration(
                    shape: shape,
                    borderRadius: borderRadius,
                    color: Colors.grey[300],
                  ),
                ),
            errorWidget: (context, url, error) =>
                placeholderWidget ??
                Container(
                  height: height ?? width!,
                  width: width ?? height!,
                  margin: margin,
                  decoration: BoxDecoration(
                    shape: shape,
                    borderRadius: borderRadius,
                    color: Colors.grey[300],
                  ),
                ),
          );
  }
}
