import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MyTheme {
  MyTheme._();
  static Color kPrimaryColor = const Color(0xff2c3968);
  static Color kBackgroundColor = const Color(0xfff5f5f5);
  static Color kPrimaryColorVariant = Color(0xff686795);
  static Color kAccentColor = Color(0xffFCAAAB);
  static Color kAccentColorVariant = Color(0xffF7A3A2);
  static Color kUnreadChatBG = Color(0xffEE1D1D);

  static final TextStyle kAppTitle = GoogleFonts.aBeeZee(
    fontSize: 24,
    color: const Color(0xff2c3968),
  );

  static final TextStyle heading1 = TextStyle(
    color: Colors.black,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5.sp,
  );
  static final TextStyle heading2 = TextStyle(
    color: const Color(0xff686795),
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5.sp,
  );

  static final TextStyle chatSenderName = TextStyle(
    overflow: TextOverflow.ellipsis,
    color: Colors.black,
    fontSize: 15.sp,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5.sp,
  );

  static final TextStyle bodyText1 = TextStyle(
      color: Color(0xffAEABC9),
      fontSize: 12.sp,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w500);

  static final TextStyle bodyTextMessage = TextStyle(
      fontSize: 13.sp, letterSpacing: 1.5, fontWeight: FontWeight.w600);

  static final TextStyle bodyTextTime = TextStyle(
    color: Color(0xffAEABC9),
    fontSize: 11.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );
}
