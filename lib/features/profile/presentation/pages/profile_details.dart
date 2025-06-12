import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../components/custom_widgets/quick_help.dart';
import '../../../../components/utilities/chat_theme.dart';
import '../bloc/profile_bloc.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
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

  final List<Map<String, dynamic>> moments = List.generate(
    20,
    (index) => {
      'imageUrl': 'https://picsum.photos/id/${index + 10}/300/300',
      'watchingCount': (1000 + index * 23).toString(),
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProfileBloc, ProfileState>(builder: (context, state) {
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
            padding: EdgeInsets.all(16.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 26.sp),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    GestureDetector(
                      onTap: () {
                        context.push('/edit-profile');
                      },
                      child: Icon(
                        Iconsax.edit,
                        color: Colors.black,
                        size: 22.sp,
                      ),
                    )
                  ],
                ),
                SizedBox(height: 8.sp),
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
                                    'assets/images/new_images/profile.png'),
                              ),
                      ),
                      Text(
                        state.userProfile.result?.name ?? "",
                        style: GoogleFonts.openSans(
                            color: Color(0xff202020),
                            fontWeight: FontWeight.w600,
                            fontSize: 20.sp),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 75,
                            child: Text(
                              'ID: ${state.userProfile.result?.uid.toString() ?? ""}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.openSans(
                                  color: Color(0xff202020),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12.sp),
                            ),
                          ),
                          SizedBox(width: 3.sp),
                          Text(
                            '|',
                            style: GoogleFonts.openSans(
                                color: Color(0xff202020),
                                fontWeight: FontWeight.w500,
                                fontSize: 12.sp),
                          ),
                          SizedBox(width: 3.sp),
                          Text(
                            state.userProfile.result?.country.toString() ?? "",
                            style: GoogleFonts.openSans(
                                color: Color(0xff202020),
                                fontWeight: FontWeight.w500,
                                fontSize: 12.sp),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.sp),
                      Text(
                        "Hey! WhatsApp",
                        style: GoogleFonts.openSans(
                            color: Color(0xff808080),
                            fontWeight: FontWeight.w500,
                            fontSize: 16.sp),
                      ),
                      SizedBox(height: 5.sp),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 5,
                          ),
                          Image.asset(
                            QuickHelp.levelVipBanner(currentCredit: 5000),
                            scale: 2.2,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                              child: Image.asset(
                                QuickHelp.levelImage(
                                  pointsInApp: 50000,
                                ),
                                width: 37,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Visibility(
                            // visible: QuickHelp.isMvpUser(user),
                            visible: true,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Image.asset(
                                "assets/images/new_images/vip_member.png",
                                width: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.sp),
                Padding(
                  padding: EdgeInsets.only(right: 8.sp, left: 8.sp),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            "1.3K",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp),
                          ),
                          SizedBox(
                            height: 2.sp,
                          ),
                          Text(
                            "Follow",
                            style: TextStyle(
                                color: MyTheme.kPrimaryColorVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.sp),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            "7.3K",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp),
                          ),
                          SizedBox(
                            height: 2.sp,
                          ),
                          Text(
                            "Followers",
                            style: TextStyle(
                                color: MyTheme.kPrimaryColorVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.sp),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            "2.5K",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp),
                          ),
                          SizedBox(
                            height: 2.sp,
                          ),
                          Text(
                            "Visitors",
                            style: TextStyle(
                                color: MyTheme.kPrimaryColorVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.sp),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Iconsax.user_octagon,
                                color: Colors.pinkAccent,
                                size: 17.sp,
                              ),
                              SizedBox(
                                width: 2.sp,
                              ),
                              Text(
                                "300",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16.sp),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 2.sp,
                          ),
                          Text(
                            "Friends",
                            style: TextStyle(
                                color: MyTheme.kPrimaryColorVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.sp),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.sp),
                Container(
                  height: 60.sp,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          "assets/images/new_images/profile_etc.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 65.sp),
                      Container(
                        width: 150.sp,
                        child: Text(
                          "*${state.userProfile.result?.name ?? ""}*",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.openSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.sp),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/new_images/bagpack.png',
                          height: 25.sp,
                          width: 25.sp,
                        ),
                        SizedBox(width: 8.sp),
                        Text(
                          "Baggage",
                          style: GoogleFonts.openSans(
                              color: Color(0xff202020),
                              fontWeight: FontWeight.w500,
                              fontSize: 17.sp),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xff202020),
                      size: 20.sp,
                    )
                  ],
                ),
                SizedBox(height: 5.sp),
                Divider(
                  color: Color(0xffF1F1F1),
                  thickness: 2,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/new_images/badge.png',
                          height: 25.sp,
                          width: 25.sp,
                        ),
                        SizedBox(width: 8.sp),
                        Text(
                          "Badges",
                          style: GoogleFonts.openSans(
                              color: Color(0xff202020),
                              fontWeight: FontWeight.w500,
                              fontSize: 17.sp),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xff202020),
                      size: 20.sp,
                    )
                  ],
                ),
                SizedBox(height: 5.sp),
                Divider(
                  color: Color(0xffF1F1F1),
                  thickness: 2,
                ),
                SizedBox(height: 18.sp),
                Text(
                  "Moments",
                  style: GoogleFonts.openSans(
                      color: Color(0xff202020),
                      fontWeight: FontWeight.w500,
                      fontSize: 18.sp),
                ),
                SizedBox(height: 18.sp),
                SizedBox(
                  height: 500.sp,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 9 / 16,
                    ),
                    itemCount: moments.length,
                    itemBuilder: (context, index) {
                      final moment = moments[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.network(
                                moment['imageUrl'],
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              left: 6,
                              bottom: 6,
                              child: Row(
                                children: [
                                  Icon(Icons.play_arrow_outlined,
                                      size: 24.sp, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    moment['watchingCount'],
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12.sp),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
