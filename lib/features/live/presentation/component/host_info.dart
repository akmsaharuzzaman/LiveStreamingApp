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
          height: 50.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: Color(0xFF111111).withValues(alpha: .85),
            borderRadius: BorderRadius.circular(100.r),
            // gradient: LinearGradient(
            //   colors: [Color(0xFF000000), Color(0xFFD5FBFB)],
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            // ),
          ),
          child: Row(
            // Use SizedBox for spacing, since Row doesn't have spacing property
            children: [
              // holds the image of the user
              imageUrl.isEmpty
                  ? CircleAvatar(
                      radius: 18.r,
                      backgroundColor: Colors.grey[400],
                      child: Icon(Icons.person, color: Colors.white, size: 24.sp),
                    )
                  : CircleAvatar(
                      radius: 18.r,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100.r),
                        child: Image.network(imageUrl),
                      ),
                    ),
              SizedBox(width: 5.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 16.sp, color: Colors.white),
                  ),
                  Text(
                    "ID: $id",
                    style: TextStyle(fontSize: 12.sp, color: Colors.white),
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
          right: 6.w,
          child: Image.asset(
            'assets/images/general/add_icon.png',
            width: 26.w,
            height: 26.h,
          ),
        ),
      ],
    );
  }
}
