import 'package:flutter/material.dart';

class CustomLiveButton extends StatelessWidget {
  const CustomLiveButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: Color(0xff888686),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}
