import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:dlstarlive/core/network/socket_service.dart';
import 'package:dlstarlive/core/network/api_clients.dart';
import 'package:dlstarlive/features/home/presentation/pages/ListPopularList.dart';
import 'package:dlstarlive/injection/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import '../../data/models/category_model.dart';
import '../../data/models/user_model.dart';
import '../widgets/custom_networkimage.dart';
import '../widgets/touchable_opacity_widget.dart';
import 'ListAudioList.dart';
import 'ListLiveStram.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final SocketService _socketService = SocketService.instance;
  final GenericApiClient _genericApiClient = getIt<GenericApiClient>();
  List<GetRoomModel>? _availableRooms;

  // Stream subscriptions for proper cleanup
  StreamSubscription? _connectionStatusSubscription;
  StreamSubscription? _getRoomListSubscription;
  StreamSubscription? _errorSubscription;

  // Tab controller for horizontal sliding tabs
  late TabController _tabController;

  // Banner URLs - will be populated from API
  List<String> _bannerUrls = [];
  bool _isBannersLoading = true;

  void _log(String message) {
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';
    debugPrint('\n$cyan[HOME_PAGE] - $reset $message\n');
  }

  /// Initialize video socket connection when entering live streaming page
  /// Returns true if the video socket is connected successfully
  Future<bool> _initializeVideoSocket() async {
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
        _log('User ID is null or empty, cannot connect to socket');
        return false;
      }

      // Initialize video socket
      _log('🔌 Connecting to video socket with user ID: $userId');
      bool videoConnected = false;
      if (!_socketService.isConnected) {
        videoConnected = await _socketService.connect(userId);
        if (videoConnected) {
          _log('✅ Video socket connected successfully');
          _setupSocketListeners();
          // Get list of available rooms
          await _socketService.getRooms();
        } else {
          _log('❌ Failed to connect to video server');
        }
      } else {
        _log('✅ Video socket already connected');
        videoConnected = true;
      }

      // Audio socket is now handled in ListAudioRooms widget

      return videoConnected;
    } catch (e) {
      _log('❌ Connection error: $e');
      return false;
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    // Connection status
    _log("Setting up socket listeners");
    _connectionStatusSubscription = _socketService.connectionStatusStream.listen((isConnected) {
      if (mounted) {
        if (isConnected) {
          // _showSnackBar('✅ Connected to server', Colors.green);
          _log("Connected to server");
        } else {
          // _showSnackBar('❌ Disconnected from server', Colors.red);
          _log("Disconnected from server");
        }
      }
    }); // Room list updates
    _getRoomListSubscription = _socketService.getRoomsStream.listen((rooms) {
      if (mounted) {
        setState(() {
          _availableRooms = rooms;
          // _log("Available rooms: ${rooms.map((room) => room.roomId)} from Frontend");
        });
      }
    });
  }

  /// Handle pull-to-refresh action
  Future<void> _handleRefresh() async {
    try {
      _log('🔄 Home page refresh triggered - fetching latest rooms and banners');

      // Refresh both rooms and banners simultaneously
      await Future.wait([
        // Check if socket is connected and get rooms
        () async {
          if (!_socketService.isConnected) {
            _log('Socket not connected, attempting to reconnect...');
            bool connected = await _initializeVideoSocket();
            if (!connected) {
              _log('⚠️ Failed to reconnect video socket during refresh');
            }
          } else {
            // If already connected, just get the rooms
            await _socketService.getRooms();
          }
        }(),
        // Refresh banners
        _fetchBanners(),
      ]);

      // Add a small delay to ensure the refresh indicator shows
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      _log('Error during refresh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh content. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Audio-related functionality has been moved to ListAudioList.dart

  /// Fetch banner images from API
  Future<void> _fetchBanners() async {
    try {
      _log('🎨 Fetching banners from API');

      final response = await _genericApiClient.get<Map<String, dynamic>>('/api/admin/banners');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        if (data['success'] == true && data['result'] != null) {
          final List<dynamic> bannerList = data['result'] as List<dynamic>;
          final List<String> urls = bannerList.cast<String>();

          if (mounted) {
            setState(() {
              _bannerUrls = urls;
              _isBannersLoading = false;
            });
          }

          _log('✅ Loaded ${urls.length} banners from API');
        } else {
          throw Exception('API response indicates failure');
        }
      } else {
        throw Exception('Failed to get banners: ${response.message}');
      }
    } catch (e) {
      _log('❌ Error fetching banners: $e');
      // Use fallback banners if API fails
      if (mounted) {
        setState(() {
          _isBannersLoading = false;
        });
      }
      _log('🔄 Using fallback banners');
    }
  }

  /// Helper method to check if URL is a network URL
  bool _isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  void initState() {
    // Initialize tab controller with 4 tabs
    _tabController = TabController(length: 4, vsync: this);

    // Initialize video socket and fetch initial data
    _initializeVideoSocket().then((connected) {
      if (connected) {
        _log('✅ Video socket connected successfully');
      } else {
        _log('⚠️ Video socket failed to connect');
      }
    });

    _fetchBanners(); // Fetch banners from API

    // Trigger refresh each time HomePage is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _log('🏠 HomePage created - triggering auto-refresh');
      _handleRefresh();
    });

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

    _log("HomePage disposed - all resources released");
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
            SvgPicture.asset('assets/icons/dl_star_logo.svg', height: 16, width: 40),
            SizedBox(width: 12.w),
            // Tab Bar
            Expanded(
              child: SizedBox(
                height: 36.h,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(width: 3.0, color: Color(0xFFFE82A7)),
                    insets: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.symmetric(horizontal: 0.w),
                  tabs: const [
                    Tab(text: 'Popular'),
                    Tab(text: 'Live'),
                    Tab(text: 'Audio'),
                    Tab(text: 'PK'),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Search and notification icons
            SvgPicture.asset('assets/icons/search_icon.svg', height: 22.sp, width: 22.sp),
            SizedBox(width: 12.sp),
            Icon(Icons.notifications_active_rounded, size: 22.sp, color: Colors.black),
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
            // Live Tab - Live stream grid only
            _buildLiveTab(),
            // Audio Tab - Audio rooms grid
            _buildAudioTab(),
            // PK Tab - Dummy content
            _buildDummyTab('PK', Icons.sports_kabaddi),
          ],
        ),
      ),
    );
  }

  // Popular tab with current homepage content
  Widget _buildPopularTab() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 7.sp),
          const ListUserFollow(),
          SizedBox(height: 12.sp),
          //Banner Section
          Padding(
            padding: EdgeInsets.only(right: 8.sp, left: 8.sp),
            child: SizedBox(
              height: 132.sp,
              width: double.infinity,
              child: _isBannersLoading
                  ? Container(
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8.0)),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : _bannerUrls.isEmpty
                  ? Container(
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8.0)),
                      child: const Center(
                        child: Text('No banners available', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ),
                    )
                  : FlutterCarousel(
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
                            indicatorBackgroundColor: Colors.white.withValues(alpha: 0.5),
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
                      items: _bannerUrls.map((url) {
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
                                child: _isNetworkUrl(url)
                                    ? CachedNetworkImage(
                                        imageUrl: url,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) =>
                                            const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.red)),
                                      )
                                    : Image.asset(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(Icons.broken_image, size: 50, color: Colors.red),
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
          ListPopularRooms(availableVideoRooms: _availableRooms ?? [], handleVideoRefresh: _handleRefresh),
        ],
      ),
    );
  }

  // Live tab with only live stream grid
  Widget _buildLiveTab() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 18.sp),
          ListLiveStream(availableRooms: _availableRooms ?? []),
        ],
      ),
    );
  }

  // Audio tab with audio rooms grid
  Widget _buildAudioTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 18.sp),
        ListAudioRooms(),
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
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Leaderboard feature coming soon!'), duration: Duration(seconds: 2)));
          },
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 8.sp, top: 8.sp, left: 8.sp, right: 8.sp),

                child: Image.asset('assets/images/general/rank_icon.png', height: 40.sp, width: 40.sp),
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
  const CategoryCard({super.key, required this.categoryModel, required this.onTap, required this.isCheck});

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
              style: TextStyle(color: isCheck ? Colors.white : Colors.black, fontSize: 10.sp),
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
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10.sp)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Live',
                      style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500),
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
