import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../components/utilities/chat_theme.dart';

class DashboardTile extends StatelessWidget {
  final String title;
  final String imagePath;
  final Color backgroundColor;
  final VoidCallback onTap;

  const DashboardTile({
    super.key,
    required this.title,
    required this.imagePath,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40.sp,
            width: 45.sp,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: backgroundColor, width: 7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(2, 4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
          SizedBox(height: 4.sp),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MyTheme.kPrimaryColorVariant,
              fontWeight: FontWeight.w500,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardItem {
  final String? title;
  final String? imagePath;
  final Color? gradientColor;

  DashboardItem({
    required this.title,
    required this.imagePath,
    required this.gradientColor,
  });
}
