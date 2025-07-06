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
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Color(0xff888686),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.network(
                  height: 40,
                  width: 40,
                  "https://thispersondoesnotexist.com/",
                ),
              ),
              Text(
                diamonCount,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Color(0xff888686),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 18),
              Text(
                starCount,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
