import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dlstarlive/components/utilities/chat_theme.dart';
import 'package:dlstarlive/features/core/services/login_provider.dart';
import 'package:dlstarlive/features/profile/presentation/bloc/profile_bloc.dart';

import '../../../../components/custom_widgets/quick_help.dart';
import '../widgets/asset_widget.dart';
import '../widgets/dashboardItemWidget.dart';

class MainProfileScreen extends StatefulWidget {
  const MainProfileScreen({super.key});

  @override
  State<MainProfileScreen> createState() => _MainProfileScreenState();
}

class _MainProfileScreenState extends State<MainProfileScreen> {
  List<String> imageUrls = [
    'assets/images/new_images/banners1.jpg',
    'assets/images/new_images/banners1.jpg',
    "assets/images/new_images/banners2.jpg",
    "assets/images/new_images/banners3.jpg",
    "assets/images/new_images/banners4.jpg",
    "assets/images/new_images/banners5.jpg",
  ];

  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUidAndDispatchEvent();
    });
    super.initState();
  }

  Future<void> _loadUidAndDispatchEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final String? uid = prefs.getString('uid');

    if (uid != null && uid.isNotEmpty) {
      print("Userid: $uid");
      context.read<ProfileBloc>().add(ProfileEvent.userDataLoaded(uid: uid));
    } else {
      print("No UID found");
    }
  }

  final List<DashboardItem> items = [
    DashboardItem(
      title: 'Invitation',
      imagePath: 'assets/images/new_images/invitation.png',
      gradientColor: const Color(0xFFD7E0EF),
    ),
    DashboardItem(
      title: 'My Wallet',
      imagePath: 'assets/images/new_images/wallet.png',
      gradientColor: const Color(0xFFFCE6CC),
    ),
    DashboardItem(
      title: 'Task Center',
      imagePath: 'assets/images/new_images/task_center.png',
      gradientColor: const Color(0xFFFFE9E9),
    ),
    DashboardItem(
      title: 'Store',
      imagePath: 'assets/images/new_images/shop.png',
      gradientColor: const Color(0xFFD7EFDB),
    ),
    DashboardItem(
      title: 'My Level',
      imagePath: 'assets/images/new_images/level.png',
      gradientColor: const Color(0xFFD7E0EF),
    ),
    DashboardItem(
      title: 'Family',
      imagePath: 'assets/images/new_images/family.png',
      gradientColor: const Color(0xFFD7E0EF),
    ),
    DashboardItem(
      title: 'Logout',
      imagePath: 'assets/images/new_images/family.png',
      gradientColor: const Color(0xFFD7E0EF),
    ),
  ];

  final List<DashboardItem> items1 = [
    DashboardItem(
      imagePath: 'assets/images/new_images/live.png',
      title: 'Live data',
      gradientColor: const Color(0xFFD7E0EF),
    ),
    DashboardItem(
      imagePath: 'assets/images/new_images/bagpack.png',
      title: 'Backpack',
      gradientColor: const Color(0xFFD7E0EF),
    ),
    DashboardItem(
      imagePath: 'assets/images/new_images/watch_history.png',
      title: 'Watch History',
      gradientColor: const Color(0xFFD7E0EF),
    ),
    DashboardItem(
      imagePath: 'assets/images/new_images/auth_verified.png',
      title: 'Auth',
      gradientColor: const Color(0xFFD7E0EF),
    ),
    DashboardItem(
      imagePath: 'assets/images/new_images/agency.png',
      title: 'My Agency',
      gradientColor: const Color(0xFFD7E0EF),
    ),
    DashboardItem(
      imagePath: 'assets/images/new_images/setting.png',
      title: 'Settings',
      gradientColor: const Color(0xFFD7E0EF),
    ),
  ];

  final List<DashboardItem> items2 = [
    DashboardItem(
      imagePath: 'assets/images/new_images/about.png',
      title: 'About DJLive',
      gradientColor: const Color(0xFFD7E0EF),
    ),
    DashboardItem(
      imagePath: 'assets/images/new_images/blacklist.png',
      title: 'Room Blacklist',
      gradientColor: const Color(0xFFD7E0EF),
    ),
    DashboardItem(
      imagePath: 'assets/images/new_images/my_room.png',
      title: 'My Room',
      gradientColor: const Color(0xFFD7E0EF),
    ),
    DashboardItem(
      imagePath: 'assets/images/new_images/feedback.png',
      title: 'FeedBack',
      gradientColor: const Color(0xFFD7E0EF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/leaderboard_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 35.sp),
                  Padding(
                    padding: EdgeInsets.only(right: 18.sp, left: 18.sp),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            context.push('/profile-details');
                          },
                          child: Icon(
                            Iconsax.edit,
                            color: Colors.black,
                            size: 22.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.sp),
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 38.r,
                          backgroundColor: Colors.white,
                          child: state.userProfile.result?.avatar?.url != null
                              ? CircleAvatar(
                                  radius: 36.r,
                                  // Size of the avatar
                                  backgroundImage: NetworkImage(
                                    state.userProfile.result?.avatar?.url ?? '',
                                  ),
                                  // Image URL
                                  backgroundColor: Colors
                                      .grey[200], // Fallback background color
                                )
                              : CircleAvatar(
                                  radius: 36.r, // Size of the avatar
                                  backgroundImage: const AssetImage(
                                    'assets/images/new_images/profile.png',
                                  ),
                                ),
                        ),
                        Text(
                          state.userProfile.result?.name ?? "",
                          style: GoogleFonts.openSans(
                            color: Color(0xff202020),
                            fontWeight: FontWeight.w600,
                            fontSize: 20.sp,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              child: Text(
                                'ID: ${state.userProfile.result?.uid.toString() ?? ""}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.openSans(
                                  color: Color(0xff202020),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.sp),
                            GestureDetector(
                              onTap: () {
                                QuickHelp.copyText(
                                  textToCopy:
                                      "${state.userProfile.result?.uid}",
                                );
                              },
                              child: Icon(
                                Icons.copy_all_rounded,
                                color: Colors.grey,
                                size: 15.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.sp),
                        Text(
                          "Hey! WhatsApp",
                          style: GoogleFonts.openSans(
                            color: Color(0xff808080),
                            fontWeight: FontWeight.w500,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 8.sp),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              QuickHelp.levelVipBanner(currentCredit: 5000),
                              height: 20.sp,
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: ClipRRect(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15),
                                ),
                                child: Image.asset(
                                  QuickHelp.levelImage(pointsInApp: 50000),
                                  height: 20.sp,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Visibility(
                              // visible: QuickHelp.isMvpUser(user),
                              visible: true,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Image.asset(
                                  "assets/images/new_images/vip_member.png",
                                  height: 20.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 45.sp),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AssetWidget(type: AssetWidgetType.dymond, value: 100),
                        AssetWidget(type: AssetWidgetType.gold, value: 100),
                      ],
                    ),
                  ),
                  //Divider
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 20.sp,
                      vertical: 10.sp,
                    ),
                    height: 1.sp,
                    color: Colors.grey.shade300,
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 25.sp, left: 25.sp),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              "0",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(height: 2.sp),
                            Text(
                              "Friends",
                              style: TextStyle(
                                color: MyTheme.kPrimaryColorVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              "0",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(height: 2.sp),
                            Text(
                              "Followers",
                              style: TextStyle(
                                color: MyTheme.kPrimaryColorVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              "0",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(height: 2.sp),
                            Text(
                              "Following",
                              style: TextStyle(
                                color: MyTheme.kPrimaryColorVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              "0",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(height: 2.sp),
                            Text(
                              "Likes",
                              style: TextStyle(
                                color: MyTheme.kPrimaryColorVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.sp),
                  Padding(
                    padding: EdgeInsets.only(right: 8.sp, left: 8.sp),
                    child: SizedBox(
                      height: 65.sp,
                      width: double.infinity,
                      child: FlutterCarousel(
                        options: FlutterCarouselOptions(
                          height: 60.sp,
                          autoPlay: true,
                          viewportFraction: 1.0,
                          enlargeCenterPage: false,
                          showIndicator: true,
                          indicatorMargin: 8,
                          slideIndicator: CircularSlideIndicator(
                            slideIndicatorOptions: SlideIndicatorOptions(
                              alignment: Alignment.bottomCenter,
                              currentIndicatorColor: Colors.white,
                              indicatorBackgroundColor: Colors.white
                                  .withOpacity(0.5),
                              indicatorBorderColor: Colors.transparent,
                              indicatorBorderWidth: 0.5,
                              indicatorRadius: 3.8,
                              itemSpacing: 15,
                              padding: const EdgeInsets.only(top: 10.0),
                              enableHalo: false,
                              enableAnimation: true,
                            ),
                          ),
                        ),
                        items: imageUrls.map((url) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.asset(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.red,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 11.sp),
                    child: Container(
                      height: 195.sp,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 0.sp,
                          left: 20.sp,
                          right: 20.sp,
                        ),
                        child: GridView.count(
                          crossAxisCount: 4,
                          crossAxisSpacing: 20.sp,
                          mainAxisSpacing: 20.sp,
                          physics: const NeverScrollableScrollPhysics(),
                          children: items.map((item) {
                            return DashboardTile(
                              title: item.title ?? "",
                              imagePath: item.imagePath ?? "",
                              backgroundColor:
                                  item.gradientColor ?? Colors.grey,
                              onTap: () async {
                                if (item.title == 'Sign Out') {
                                  try {
                                    // Clear shared preferences
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.clear();

                                    // Update the login provider
                                    if (context.mounted) {
                                      context.read<LoginInfo>().logout();
                                      // Use go instead of pushReplacement to completely reset navigation
                                      context.go('/welcome-screen');
                                    }
                                  } catch (e) {
                                    debugPrint('Error during logout: $e');
                                    // Still try to navigate even if there's an error
                                    if (context.mounted) {
                                      context.go('/welcome-screen');
                                    }
                                  }
                                } else {
                                  // Handle other taps
                                  print("Tapped on ${item.title}");
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 11.sp),
                    child: Container(
                      height: 195.sp,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 0.sp,
                          left: 20.sp,
                          right: 20.sp,
                        ),
                        child: GridView.count(
                          crossAxisCount: 4,
                          crossAxisSpacing: 20.sp,
                          mainAxisSpacing: 20.sp,
                          physics: const NeverScrollableScrollPhysics(),
                          children: items1.map((item) {
                            return DashboardTile(
                              title: item.title ?? "",
                              imagePath: item.imagePath ?? "",
                              backgroundColor:
                                  item.gradientColor ?? Colors.grey,
                              onTap: () {},
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.sp),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 11.sp),
                    child: Container(
                      height: 110.sp,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 0.sp,
                          left: 20.sp,
                          right: 20.sp,
                        ),
                        child: GridView.count(
                          crossAxisCount: 4,
                          crossAxisSpacing: 20.sp,
                          mainAxisSpacing: 20.sp,
                          physics: const NeverScrollableScrollPhysics(),
                          children: items2.map((item) {
                            return DashboardTile(
                              title: item.title ?? "",
                              imagePath: item.imagePath ?? "",
                              backgroundColor:
                                  item.gradientColor ?? Colors.grey,
                              onTap: () {},
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.sp),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
