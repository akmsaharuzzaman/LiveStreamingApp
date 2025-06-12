import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../components/utilities/chat_theme.dart';
import '../../../../components/utilities/custom_networkimage.dart';
import '../../../../components/utilities/touchable_opacity_widget.dart';
import '../../data/models/category_model.dart';
import '../../data/models/live_streaming_model.dart';
import '../../data/models/user_model.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  int _currentIndex = 0;

  List<String> imageUrls = [
    'assets/images/new_images/banners1.jpg',
    'assets/images/new_images/banners1.jpg',
    "assets/images/new_images/banners2.jpg",
    "assets/images/new_images/banners3.jpg",
    "assets/images/new_images/banners4.jpg",
    "assets/images/new_images/banners5.jpg"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          children: [
            Image.asset(
              'assets/images/new_images/ic_logo_white.png',
              height: 40,
              width: 40,
            ),
            SizedBox(width: 8.sp),
            Text(
              "StreamBird",
              style: MyTheme.kAppTitle,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: 110.w,
            // padding: EdgeInsets.symmetric(horizontal: 16.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Iconsax.search_favorite,
                      size: 22.sp,
                      color: Colors.black,
                    ),
                    SizedBox(width: 12.sp),
                    Icon(
                      Iconsax.notification,
                      size: 22.sp,
                      color: Colors.black,
                    ),
                    SizedBox(width: 12.sp),
                    GestureDetector(
                      onTap: () {
                        context.push('/leaderboard');
                      },
                      child: Icon(
                        Iconsax.ranking_1,
                        size: 22.sp,
                        color: Colors.black,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.sp),
            const ListCategoryHome(),
            SizedBox(height: 20.sp),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.sp),
              child: Text(
                'Following',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 7.sp),
            const ListUserFollow(),
            SizedBox(height: 12.sp),
            Padding(
              padding: EdgeInsets.only(right: 8.sp, left: 8.sp),
              child: SizedBox(
                height: 75.sp,
                width: double.infinity,
                child: FlutterCarousel(
                  options: FlutterCarouselOptions(
                    height: 75.sp,
                    autoPlay: true,
                    viewportFraction: 1.0,
                    enlargeCenterPage: false,
                    showIndicator: true,
                    indicatorMargin: 8,
                    slideIndicator: CircularSlideIndicator(
                      slideIndicatorOptions: SlideIndicatorOptions(
                        alignment: Alignment.bottomCenter,
                        currentIndicatorColor: Colors.white,
                        indicatorBackgroundColor: Colors.white.withOpacity(0.5),
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
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
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
                                  child: Icon(Icons.broken_image,
                                      size: 50, color: Colors.red),
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
            SizedBox(height: 18.sp),
            const ListLiveStream(),
          ],
        ),
      ),
    );
  }
}

class ListCategoryHome extends StatefulWidget {
  const ListCategoryHome({super.key});

  @override
  State<ListCategoryHome> createState() => _ListCategoryHomeState();
}

class _ListCategoryHomeState extends State<ListCategoryHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding(
        //   padding: EdgeInsets.symmetric(horizontal: 16.sp),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       Text(
        //         'Categories',
        //         style: TextStyle(
        //           color: Colors.black,
        //           fontSize: 13.sp,
        //           fontWeight: FontWeight.w700,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        SizedBox(height: 8.sp),
        SizedBox(
          height: 32.5.sp,
          width: double.infinity,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.sp),
            itemCount: listCategoryFake.length,
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemBuilder: ((context, index) {
              return CategoryCard(
                categoryModel: listCategoryFake[index],
                isCheck: _currentIndex == index,
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}

class ListLiveStream extends StatelessWidget {
  const ListLiveStream({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: 16.sp,
        ).add(
          EdgeInsets.only(
            bottom: 80.sp,
          ),
        ),
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 0.sp,
          crossAxisSpacing: 10.sp,
          childAspectRatio: 0.70,
        ),
        itemCount: listLiveStreamFake.length,
        itemBuilder: (context, index) {
          return LiveStreamCard(
            liveStreamModel: listLiveStreamFake[index],
            onTap: (() {
              // Navigator.of(context).push(MaterialPageRoute(
              //     builder: (context) => const StreamScreen()));
            }),
          );
        },
      ),
    );
  }
}

class ListUserFollow extends StatelessWidget {
  const ListUserFollow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74.sp,
      width: double.infinity,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.sp),
        itemCount: listUserFake.length,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemBuilder: ((context, index) {
          return UserWidget(
            userModel: listUserFake[index],
          );
        }),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final CategoryModel categoryModel;
  final Function() onTap;
  final bool isCheck;
  const CategoryCard({
    super.key,
    required this.categoryModel,
    required this.onTap,
    required this.isCheck,
  });

  @override
  Widget build(BuildContext context) {
    return TouchableOpacity(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 10.sp),
        padding: EdgeInsets.symmetric(
          horizontal: 16.sp,
          vertical: 4.sp,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.sp),
          color: isCheck ? MyTheme.kPrimaryColor : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              categoryModel.title,
              style: TextStyle(
                color: isCheck ? Colors.white : Colors.black,
                fontSize: 10.sp,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class UserWidget extends StatelessWidget {
  final UserModel userModel;

  const UserWidget({super.key, required this.userModel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(right: 8.sp),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(3.5.sp),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 1.2.sp,
                    color: userModel.isLiveStream ? Colors.pink : Colors.black,
                  ),
                ),
                child: CustomNetworkImage(
                  height: 42.sp,
                  width: 42.sp,
                  urlToImage: userModel.urlToImage,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(height: 6.sp),
              Text(
                userModel.fullName,
                style: TextStyle(
                  color: userModel.isLiveStream ? Colors.black : Colors.blue,
                  fontSize: 10.sp,
                  fontWeight: userModel.isLiveStream ? FontWeight.w500 : null,
                ),
              )
            ],
          ),
        ),
        Visibility(
          visible: userModel.isLiveStream,
          child: Positioned(
            right: 15,
            child: Container(
              padding: const EdgeInsets.only(
                left: 1,
                bottom: 1,
                right: 1,
              ),
              alignment: Alignment.center,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 2.sp, horizontal: 9.sp),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10.sp),
                ),
                child: Text(
                  'Live',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class LiveStreamCard extends StatelessWidget {
  final LiveStreamModel liveStreamModel;
  final Function() onTap;
  const LiveStreamCard(
      {super.key, required this.liveStreamModel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TouchableOpacity(
      onTap: onTap,
      child: Stack(
        children: [
          CustomNetworkImage(
            urlToImage: liveStreamModel.urlToImage,
            height: 180.sp,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(
              13.sp,
            ),
            // fit: BoxFit.cover,
          ),
          Column(
            children: [
              Container(
                height: 180.sp,
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.89)
                    ],
                    end: Alignment.bottomCenter,
                    begin: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(
                    13.sp,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.sp),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 5,
                              sigmaY: 10,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.sp,
                                vertical: 2.sp,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Iconsax.voice_cricle,
                                    size: 17.sp,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 5.sp),
                                  Text(
                                    '${liveStreamModel.peopleParticipant}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.sp,
                            vertical: 2.sp,
                          ),
                          decoration: BoxDecoration(
                            color: liveStreamModel.getColorType,
                            borderRadius: BorderRadius.circular(
                              9.sp,
                            ),
                          ),
                          child: Text(
                            liveStreamModel.getTitleType,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'You are live now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.sp),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomNetworkImage(
                    urlToImage:
                        'https://cdn.dribbble.com/users/3245638/screenshots/15628559/media/21f20574f74b6d6f8e74f92bde7de2fd.png?compress=1&resize=400x300&vertical=top',
                    height: 30.sp,
                  ),
                  SizedBox(width: 5.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wahidur Zaman',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '159K Followers',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: Colors.white,
                    position: PopupMenuPosition.under,
                    icon: Container(
                      color: Colors.transparent,
                      child: Icon(
                        Icons.more_horiz,
                        size: 20.sp,
                        color: Colors.black,
                      ),
                    ),
                    onSelected: (String result) {
                      // Handle your menu selection here
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      /* PopupMenuItem<String>(
              value: 'Option 1',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/profile/share-03.png',
                    width: 20.sp,
                    height: 20.sp,
                  ),
                  SizedBox(
                    width: 12.sp,
                  ),
                  const Text(
                    'Share Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Aeonik',
                      fontWeight: FontWeight.w500,
                      height: 0,
                    ),
                  )
                ],
              ),
            ),*/
                      PopupMenuItem<String>(
                        value: 'Option 3',
                        child: GestureDetector(
                          onTap: () {},
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Follow",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14.sp,
                                  fontFamily: 'Aeonik',
                                  fontWeight: FontWeight.w500,
                                  height: 0,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'Option 2',
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Report',
                              style: TextStyle(
                                color: Color(0xFFDC3030),
                                fontSize: 14.sp,
                                fontFamily: 'Aeonik',
                                fontWeight: FontWeight.w500,
                                height: 0,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  void _showPopupMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    PopupMenuButton<String>(
      color: const Color(0xff1C262A),
      position: PopupMenuPosition.under,
      icon: Image.asset(
        'assets/profile/three_dots.png',
        width: 48.sp,
        height: 48.sp,
      ),
      onSelected: (String result) {
        // Handle your menu selection here
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        /* PopupMenuItem<String>(
              value: 'Option 1',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/profile/share-03.png',
                    width: 20.sp,
                    height: 20.sp,
                  ),
                  SizedBox(
                    width: 12.sp,
                  ),
                  const Text(
                    'Share Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Aeonik',
                      fontWeight: FontWeight.w500,
                      height: 0,
                    ),
                  )
                ],
              ),
            ),*/
        PopupMenuItem<String>(
          value: 'Option 3',
          child: GestureDetector(
            onTap: () {},
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Follow",
                  style: const TextStyle(
                    color: Color(0xFFDC3030),
                    fontSize: 16,
                    fontFamily: 'Aeonik',
                    fontWeight: FontWeight.w500,
                    height: 0,
                  ),
                )
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Option 2',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Report',
                style: TextStyle(
                  color: Color(0xFFDC3030),
                  fontSize: 16,
                  fontFamily: 'Aeonik',
                  fontWeight: FontWeight.w500,
                  height: 0,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
