import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EndStreamOverlay extends StatelessWidget {
  final VoidCallback onKeepStream;
  final VoidCallback onEndStream;

  const EndStreamOverlay({
    super.key,
    required this.onKeepStream,
    required this.onEndStream,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onKeepStream,
    required VoidCallback onEndStream,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (BuildContext context) {
        return EndStreamOverlay(
          onKeepStream: onKeepStream,
          onEndStream: onEndStream,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: 0.8.sw,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Keep button
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // Close dialog
                onKeepStream();
              },
              child: Container(
                width: 80.w,
                height: 80.w,
                margin: EdgeInsets.only(bottom: 30.h),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF69B4), Color(0xFFFF8FA3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF69B4).withValues(alpha: 0.3),
                      spreadRadius: 2.r,
                      blurRadius: 8.r,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white,
                  size: 40.sp,
                ),
              ),
            ),
            Text(
              'Keep',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 40.h),
            // Exit button
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // Close dialog
                onEndStream();
              },
              child: Container(
                width: 80.w,
                height: 80.w,
                margin: EdgeInsets.only(bottom: 30.h),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF69B4), Color(0xFFFF8FA3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF69B4).withValues(alpha: 0.3),
                      spreadRadius: 2.r,
                      blurRadius: 8.r,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.power_settings_new,
                  color: Colors.white,
                  size: 40.sp,
                ),
              ),
            ),
            Text(
              'Exit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
