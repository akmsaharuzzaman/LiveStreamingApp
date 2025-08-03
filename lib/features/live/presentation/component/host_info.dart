import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Color(0xFF888686),
            borderRadius: BorderRadius.circular(100),
            gradient: LinearGradient(
              colors: [Color(0xFF000000), Color(0xFFD5FBFB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            spacing: 5,
            children: [
              // holds the image of the user
              imageUrl.isEmpty
                  ? CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[400],
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    )
                  : CircleAvatar(
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
                  Text(
                    name,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    "ID: $id",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(width: 6.w), 
            ],
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 6,
          child:Image.asset(
            'assets/images/general/add_icon.png',
            width: 26.w,
            height: 26.h,
          ),
        ),
      ],
    );
  }
}
