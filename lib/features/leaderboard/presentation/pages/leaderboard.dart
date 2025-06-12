import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderBoardScreen extends StatefulWidget {
  const LeaderBoardScreen({super.key});

  @override
  State<LeaderBoardScreen> createState() => _LeaderBoardScreenState();
}

class _LeaderBoardScreenState extends State<LeaderBoardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/leaderboard_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(right: 16.sp, left: 16.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.sp),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.pop();
                    },
                    child: Image.asset(
                      "assets/images/new_images/arrow_back.png",
                      height: 18.sp,
                      width: 18.sp,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 20.sp),
                  Text(
                    'Leader board',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 18.sp),
                  )
                ],
              ),
              SizedBox(height: 30.sp),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 210,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/topuser_bg.png'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Top User",
                            style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                                color: Color(0xffFFFFFF)),
                          ),
                          SizedBox(height: 5.sp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 20.r,
                                backgroundImage: AssetImage(
                                    'assets/images/new_images/person.png'),
                              ),
                              SizedBox(
                                width: 10.sp,
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 22..sp),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Transform.translate(
                                      offset: Offset(0, 4),
                                      child: Image.asset(
                                        'assets/images/crown.png',
                                        height: 24.sp,
                                        width: 32.sp,
                                      ),
                                    ),
                                    CircleAvatar(
                                      radius: 28.r,
                                      backgroundImage: AssetImage(
                                          'assets/images/new_images/profile.png'),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 10.sp,
                              ),
                              CircleAvatar(
                                radius: 20.r,
                                backgroundImage: AssetImage(
                                    'assets/images/new_images/person.png'),
                              ),
                            ],
                          ),
                          SizedBox(height: 5.sp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Opacity(
                                opacity: 0.5,
                                child: Text(
                                  "2",
                                  style: TextStyle(
                                      fontSize: 26.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xffFFFFFF)),
                                ),
                              ),
                              SizedBox(
                                width: 5.sp,
                              ),
                              Opacity(
                                opacity: 0.5,
                                child: Text(
                                  "1",
                                  style: TextStyle(
                                      fontSize: 30.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xffFFFFFF)),
                                ),
                              ),
                              SizedBox(
                                width: 5.sp,
                              ),
                              Opacity(
                                opacity: 0.5,
                                child: Text(
                                  "3",
                                  style: GoogleFonts.openSans(
                                      fontSize: 26.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xffFFFFFF)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 14.sp),
                  Expanded(
                    child: Container(
                      height: 210,
                      decoration: BoxDecoration(
                        color: Color(0xff9A38FF),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Top Talents",
                            style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                                color: Color(0xffFFFFFF)),
                          ),
                          SizedBox(height: 5.sp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 20.r,
                                backgroundImage: AssetImage(
                                    'assets/images/new_images/person.png'),
                              ),
                              SizedBox(
                                width: 10.sp,
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 22..sp),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Transform.translate(
                                      offset: Offset(0, 4),
                                      child: Image.asset(
                                        'assets/images/crown.png',
                                        height: 24.sp,
                                        width: 32.sp,
                                      ),
                                    ),
                                    CircleAvatar(
                                      radius: 28.r,
                                      backgroundImage: AssetImage(
                                          'assets/images/new_images/profile.png'),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 10.sp,
                              ),
                              CircleAvatar(
                                radius: 20.r,
                                backgroundImage: AssetImage(
                                    'assets/images/new_images/person.png'),
                              ),
                            ],
                          ),
                          SizedBox(height: 5.sp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Opacity(
                                opacity: 0.5,
                                child: Text(
                                  "2",
                                  style: TextStyle(
                                      fontSize: 26.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xffFFFFFF)),
                                ),
                              ),
                              SizedBox(
                                width: 5.sp,
                              ),
                              Opacity(
                                opacity: 0.5,
                                child: Text(
                                  "1",
                                  style: TextStyle(
                                      fontSize: 30.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xffFFFFFF)),
                                ),
                              ),
                              SizedBox(
                                width: 5.sp,
                              ),
                              Opacity(
                                opacity: 0.5,
                                child: Text(
                                  "3",
                                  style: GoogleFonts.openSans(
                                      fontSize: 26.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xffFFFFFF)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.sp),
              Container(
                height: 90.sp,
                width: 385.sp,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/weekly_gift_bg.png'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 15..sp),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/gift.png',
                        height: 32.sp,
                        width: 32.sp,
                      ),
                      SizedBox(width: 10.sp),
                      Text(
                        "Weekly Star",
                        style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: Color(0xffFFFFFF)),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.sp),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 210,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/short_star_bg.png'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/star.png',
                                height: 24.sp,
                                width: 24.sp,
                              ),
                              SizedBox(width: 10.sp),
                              Text(
                                "Hour Star",
                                style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xffFFFFFF)),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.sp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: CircleAvatar(
                                  radius: 20.r,
                                  backgroundImage: AssetImage(
                                      'assets/images/new_images/person.png'),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 22..sp),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Transform.translate(
                                      offset: Offset(0, 4),
                                      child: Image.asset(
                                        'assets/images/crown.png',
                                        height: 24.sp,
                                        width: 32.sp,
                                      ),
                                    ),
                                    CircleAvatar(
                                      radius: 28.r,
                                      backgroundImage: AssetImage(
                                          'assets/images/new_images/profile.png'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5.sp),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 14.sp),
                  Expanded(
                    child: Container(
                      height: 210,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/short_star_bg.png'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/star.png',
                                height: 24.sp,
                                width: 24.sp,
                              ),
                              SizedBox(width: 10.sp),
                              Text(
                                "Short Star",
                                style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xffFFFFFF)),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.sp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 20.r,
                                backgroundImage: AssetImage(
                                    'assets/images/new_images/person.png'),
                              ),
                              SizedBox(
                                width: 10.sp,
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 22..sp),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Transform.translate(
                                      offset: Offset(0, 4),
                                      child: Image.asset(
                                        'assets/images/crown.png',
                                        height: 24.sp,
                                        width: 32.sp,
                                      ),
                                    ),
                                    CircleAvatar(
                                      radius: 28.r,
                                      backgroundImage: AssetImage(
                                          'assets/images/new_images/profile.png'),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 10.sp,
                              ),
                              CircleAvatar(
                                radius: 20.r,
                                backgroundImage: AssetImage(
                                    'assets/images/new_images/person.png'),
                              ),
                            ],
                          ),
                          SizedBox(height: 5.sp),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
