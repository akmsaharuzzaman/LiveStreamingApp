import 'dart:async';
import 'dart:ui';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:dlstarlive/core/network/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/category_model.dart';
import '../../data/models/user_model.dart';
import '../widgets/custom_networkimage.dart';
import '../widgets/touchable_opacity_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final SocketService _socketService = SocketService.instance;
  List<GetRoomModel>? _availableRooms;

  // Stream subscriptions for proper cleanup
  StreamSubscription? _connectionStatusSubscription;
  StreamSubscription? _getRoomListSubscription;
  StreamSubscription? _errorSubscription;

  // Tab controller for horizontal sliding tabs
  late TabController _tabController;

  List<String> imageUrls = [
    'assets/images/general/banners/banner_1.jpg',
    'assets/images/general/banners/banner_2.jpg',
  ];

  /// Initialize socket connection when entering live streaming page
  Future<void> _initializeSocket() async {
    try {
      // Get user ID from AuthBloc instead of SharedPreferences
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;

      String? userId;
      if (authState is AuthAuthenticated) {
        userId = authState.user.id;
      } else if (authState is AuthProfileIncomplete) {
        userId = authState.user.id;
      }

      if (userId == null || userId.isEmpty) {
        debugPrint('User ID is null or empty, cannot connect to socket');
        return;
      }

      debugPrint('Connecting to socket with user ID: $userId');
      final connected = await _socketService.connect(userId);

      if (connected) {
        _setupSocketListeners();
        // Get list of available rooms
        await _socketService.getRooms();
      } else {
        debugPrint('Failed to connect to server');
      }
    } catch (e) {
      debugPrint('Connection error: $e');
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    // Connection status
    debugPrint("Setting up socket listeners");
    _connectionStatusSubscription = _socketService.connectionStatusStream
        .listen((isConnected) {
          if (mounted) {
            if (isConnected) {
              // _showSnackBar('✅ Connected to server', Colors.green);
              debugPrint("Connected to server");
            } else {
              // _showSnackBar('❌ Disconnected from server', Colors.red);
              debugPrint("Disconnected from server");
            }
          }
        }); // Room list updates
    _getRoomListSubscription = _socketService.getRoomsStream.listen((rooms) {
      if (mounted) {
        setState(() {
          _availableRooms = rooms;
          debugPrint(
            "Available rooms: ${rooms.map((room) => room.roomId)} from Frontend",
          );
        });
      }
    });
  }

  @override
  void initState() {
    // Initialize tab controller with 4 tabs
    _tabController = TabController(length: 4, vsync: this);

    _initializeSocket();
    // Removed duplicate _setupSocketListeners() call - it's already called in _initializeSocket()
    super.initState();
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions to prevent setState calls after disposal
    _connectionStatusSubscription?.cancel();
    _getRoomListSubscription?.cancel();
    _errorSubscription?.cancel();

    // Dispose tab controller
    _tabController.dispose();

    debugPrint("HomePage disposed - stream subscriptions canceled");
    super.dispose();
  }

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
        centerTitle: false,
        titleSpacing: 16.w,
        title: Row(
          children: [
            // Logo
            SvgPicture.asset(
              'assets/icons/dl_star_logo.svg',
              height: 16,
              width: 40,
            ),
            SizedBox(width: 12.w),
            // Tab Bar
            Expanded(
              child: SizedBox(
                height: 36.h,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 3.0,
                      color: Color(0xFFFE82A7),
                    ),
                    insets: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.symmetric(horizontal: 0.w),
                  tabs: const [
                    Tab(text: 'Popular'),
                    Tab(text: 'Live'),
                    Tab(text: 'Party'),
                    Tab(text: 'PK'),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Search and notification icons
            SvgPicture.asset(
              'assets/icons/search_icon.svg',
              height: 22.sp,
              width: 22.sp,
            ),
            SizedBox(width: 12.sp),
            Icon(
              Icons.notifications_active_rounded,
              size: 22.sp,
              color: Colors.black,
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Popular Tab - Current homepage content
            _buildPopularTab(),
            // Live Tab - Dummy content
            _buildDummyTab('Live', Icons.live_tv),
            // Party Tab - Dummy content
            _buildDummyTab('Party', Icons.party_mode),
            // PK Tab - Dummy content
            _buildDummyTab('PK', Icons.sports_kabaddi),
          ],
        ),
      ),
    );
  }

  // Popular tab with current homepage content
  Widget _buildPopularTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 7.sp),
        const ListUserFollow(),
        SizedBox(height: 12.sp),
        Padding(
          padding: EdgeInsets.only(right: 8.sp, left: 8.sp),
          child: SizedBox(
            height: 132.sp,
            width: double.infinity,
            child: FlutterCarousel(
              options: FlutterCarouselOptions(
                height: 132.sp,
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
        // SizedBox(height: 18.sp),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 18.0),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       Image.asset(
        //         'assets/images/general/top_sender.png',
        //         height: MediaQuery.of(context).size.height * 0.08,
        //       ),
        //       Image.asset(
        //         'assets/images/general/top_host.png',
        //         height: MediaQuery.of(context).size.height * 0.08,
        //       ),
        //       Image.asset(
        //         'assets/images/general/top_agency.png',
        //         height: MediaQuery.of(context).size.height * 0.08,
        //       ),
        //     ],
        //   ),
        // ),
        SizedBox(height: 18.sp),
        ListLiveStream(availableRooms: _availableRooms ?? []),
      ],
    );
  }

  // Dummy tab content for other tabs
  Widget _buildDummyTab(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80.sp, color: Colors.grey.shade400),
          SizedBox(height: 20.h),
          Text(
            '$title Page',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Coming Soon!',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class ListLiveStream extends StatelessWidget {
  final List<GetRoomModel> availableRooms;
  const ListLiveStream({super.key, required this.availableRooms});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: 16.sp,
        ).add(EdgeInsets.only(bottom: 80.sp)),
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 0.sp,
          crossAxisSpacing: 10.sp,
          childAspectRatio: 0.70,
        ),
        // itemCount: listLiveStreamFake.length,
        itemCount: availableRooms.length,
        itemBuilder: (context, index) {
          return LiveStreamCard(
            liveStreamModel: availableRooms[index],
            onTap: () {
              // Navigate to the live stream screen with the room ID using the named route
              context.pushNamed(
                'onGoingLive',
                queryParameters: {
                  'roomId': availableRooms[index].roomId,
                  'hostName':
                      availableRooms[index].hostDetails?.name ?? 'Unknown Host',
                  'hostUserId':
                      availableRooms[index].hostDetails?.id ?? 'Unknown User',
                  'hostAvatar':
                      availableRooms[index].hostDetails?.avatar ??
                      'Unknown Avatar',
                },
                extra: {
                  'existingViewers': availableRooms[index].membersDetails,
                },
              );
            },
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
    return Row(
      children: [
        SizedBox(
          height: 90.sp,
          width: MediaQuery.of(context).size.width * 0.80,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.sp),
            itemCount: listUserFake.length,
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemBuilder: ((context, index) {
              return UserWidget(userModel: listUserFake[index]);
            }),
          ),
        ),
        Spacer(),
        InkWell(
          onTap: () {
            // Navigate to the leaderboard page
            // context.pushNamed('leaderBoard');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Leaderboard feature coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  bottom: 8.sp,
                  top: 8.sp,
                  left: 8.sp,
                  right: 8.sp,
                ),

                child: Image.asset(
                  'assets/images/general/rank_icon.png',
                  height: 40.sp,
                  width: 40.sp,
                ),
              ),
              SizedBox(height: 24.sp),
            ],
          ),
        ),
        SizedBox(width: 20.sp),
      ],
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
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.sp),
          color: isCheck ? Colors.green : Colors.white,
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
            ),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  child: CustomNetworkImage(
                    height: 45.sp,
                    width: 45.sp,
                    urlToImage: userModel.urlToImage,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(height: 6.sp),
                Text(
                  userModel.fullName,
                  style: TextStyle(color: Colors.black, fontSize: 14.sp),
                ),
              ],
            ),
          ),
          Visibility(
            visible: userModel.isLiveStream,
            child: Positioned(
              top: 0,
              child: Container(
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10.sp),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveStreamCard extends StatelessWidget {
  final GetRoomModel liveStreamModel;
  final Function() onTap;
  const LiveStreamCard({
    super.key,
    required this.liveStreamModel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TouchableOpacity(
      onTap: onTap,
      child: Stack(
        children: [
          CustomNetworkImage(
            urlToImage:
                liveStreamModel.hostDetails?.avatar ??
                'https://cdn.dribbble.com/users/3245638/screenshots/15628559/media/21f20574f74b6d6f8e74f92bde7de2fd.png?compress=1&resize=400x300&vertical=top',
            height: 180.sp,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(13.sp),
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
                      Colors.black.withOpacity(0.89),
                    ],
                    end: Alignment.bottomCenter,
                    begin: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(13.sp),
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
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 10),
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
                                    Icons.voice_chat,
                                    size: 17.sp,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 5.sp),
                                  Text(
                                    '${liveStreamModel.members.length}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
                            color:
                                Colors.redAccent, // Always red for live streams
                            borderRadius: BorderRadius.circular(9.sp),
                          ),
                          child: Text(
                            'Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${liveStreamModel.hostDetails?.name ?? 'Unknown Host'} is live now',
                      style: TextStyle(color: Colors.white, fontSize: 11.sp),
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
                        liveStreamModel.hostDetails?.avatar ??
                        'https://cdn.dribbble.com/users/3245638/screenshots/15628559/media/21f20574f74b6d6f8e74f92bde7de2fd.png?compress=1&resize=400x300&vertical=top',
                    height: 30.sp,
                    width: 30.sp,
                    shape: BoxShape.circle,
                  ),
                  SizedBox(width: 5.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveStreamModel.hostDetails?.name ?? 'Unknown Host',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'ID: ${liveStreamModel.hostDetails?.uid.substring(0, 6) ?? 'Unknown ID'}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                                  ),
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
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
