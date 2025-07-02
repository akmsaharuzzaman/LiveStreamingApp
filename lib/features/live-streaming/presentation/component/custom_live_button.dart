import 'package:flutter/material.dart';

class CustomLiveButton extends StatelessWidget {
  const CustomLiveButton({
    super.key,
    required this.iconPath,
    required this.onTap,
  });

  final String iconPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: Color(0xff888686),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Image.asset(
          iconPath,
          width: 40,
          height: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}
