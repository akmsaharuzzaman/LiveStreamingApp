import 'package:flutter/material.dart';

class DiamondStarStatus extends StatelessWidget {
  const DiamondStarStatus({
    super.key,
    required this.diamonCount,
    required this.starCount,
  });

  final String starCount;
  final String diamonCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Color(0xff888686),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              const SizedBox(width: 5),
              Image.asset(
                'assets/icons/dymond_icon_live.png',
                width: 18,
                height: 18,
              ),
              SizedBox(width: 5),
              Text(
                diamonCount,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
