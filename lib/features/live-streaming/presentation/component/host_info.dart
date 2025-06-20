import 'package:flutter/material.dart';

class HostInfo extends StatelessWidget {
  const HostInfo({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.id,
  });
  final String imageUrl;
  final String name;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Color(0xFF888686),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        spacing: 5,
        children: [
          // holds the image of the user
          CircleAvatar(
            radius: 18,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.network(imageUrl),
            ),
          ),
          Column(
            spacing: 2,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 16, color: Colors.white)),
              Text(
                "ID: $id",
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
