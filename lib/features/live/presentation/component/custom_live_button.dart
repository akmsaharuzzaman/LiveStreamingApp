import 'package:flutter/material.dart';

class CustomLiveButton extends StatelessWidget {
  const CustomLiveButton({
    super.key,
    required this.iconPath,
    required this.onTap,
    this.width = 40,
    this.height = 40,
  });

  final String iconPath;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(iconPath, width: width, height: height),
    );
  }
}
