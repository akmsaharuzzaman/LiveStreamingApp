import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:dlstarlive/core/network/api_clients.dart';
import 'package:dlstarlive/features/home/service/video_all_room_service.dart';
import 'package:dlstarlive/features/home/service/audio_all_room_service.dart';
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
import '../../../../routing/route_observer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin, RouteAware {
  final GenericApiClient _genericApiClient = getIt<GenericApiClient>();
  final VideoAllRoomService _videoRoomService = VideoAllRoomService();
  final AudioAllRoomService _audioRoomService = AudioAllRoomService();

  List<GetRoomModel> _availableRooms = [];
  bool _isVideoLoading = false;
  bool _servicesInitialized = false;

  // Stream subscriptions for proper cleanup
  StreamSubscription? _videoRoomsSubscription;
  StreamSubscription? _videoLoadingSubscription;

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

  /// Initialize both video and audio services
  Future<void> _initializeServices() async {
    try {
      // Get user ID from AuthBloc
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;

      String? userId;
      if (authState is AuthAuthenticated) {
        userId = authState.user.id;
      } else if (authState is AuthProfileIncomplete) {
        userId = authState.user.id;
      }

      if (userId == null || userId.isEmpty) {
        _log('User ID is null or empty, cannot initialize services');
        return;
      }

      _log('🚀 Initializing services with user ID: $userId');

      setState(() {
        _isVideoLoading = true;
      });

      // Initialize both services
      await Future.wait([_videoRoomService.initialize(userId), _audioRoomService.initialize(userId)]);

      if (mounted) {
        setState(() {
          _availableRooms = _videoRoomService.cachedVideoRooms;
          _isVideoLoading = _videoRoomService.isLoading;
        });
      }

      _setupVideoRoomListener();
      _setupVideoLoadingListener();

      _servicesInitialized = true;
      _triggerPopularRefreshIfActive();

      _log('✅ Services initialized successfully');
    } catch (e) {
      _log('❌ Error initializing services: $e');
    }
  }

  /// Setup video room listener
  void _setupVideoRoomListener() {
    _videoRoomsSubscription?.cancel();
    _videoRoomsSubscription = _videoRoomService.videoRoomsStream.listen(
      (rooms) {
        if (mounted) {
          setState(() {
            _availableRooms = rooms;
          });
        }
      },
      onError: (error) {
        _log('❌ Video rooms error: $error');
      },
      cancelOnError: false,
    );
  }

  /// Setup video loading listener
  void _setupVideoLoadingListener() {
    _videoLoadingSubscription?.cancel();
    _videoLoadingSubscription = _videoRoomService.loadingStream.listen(
      (isLoading) {
        if (mounted) {
          setState(() {
            _isVideoLoading = isLoading;
          });
        }
      },
      onError: (error) {
        _log('❌ Video loading error: $error');
      },
      cancelOnError: false,
    );
  }

  /// Handle pull-to-refresh action
  Future<void> _handleRefresh() async {
    try {
      _log('🔄 Home page refresh triggered - fetching latest rooms and banners');

      // Refresh video rooms, audio rooms, and banners simultaneously
      await Future.wait([
        _videoRoomService.requestVideoRooms(),
        _audioRoomService.requestAudioRooms(),
        _fetchBanners(),
      ]);
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
    super.initState();

    // Initialize tab controller with 4 tabs
    _tabController = TabController(length: 4, vsync: this)..addListener(_handleTabChange);

    // Initialize services and fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _log('🏠 HomePage created - initializing services');
      _initializeServices();
      _fetchBanners();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // Cancel stream subscriptions
    _videoRoomsSubscription?.cancel();
    _videoLoadingSubscription?.cancel();

    // Dispose tab controller
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();

    routeObserver.unsubscribe(this);

    _log("HomePage disposed - all resources released");
    super.dispose();
  }

  @override
  void didPush() {
    _triggerPopularRefreshIfActive();
  }

  @override
  void didPopNext() {
    _triggerPopularRefreshIfActive();
  }

  void _triggerPopularRefreshIfActive() {
    if (!_servicesInitialized) {
      return;
    }
    if (_tabController.index == 0) {
      _refreshPopularTab();
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    if (_tabController.index == 0) {
      _log('📱 Popular tab active - requesting latest rooms');
      _refreshPopularTab();
    }
  }

  Future<void> _refreshPopularTab() async {
    try {
      await Future.wait([_audioRoomService.requestAudioRooms(), _videoRoomService.requestVideoRooms()]);
    } catch (e) {
      _log('❌ Error refreshing popular tab: $e');
    }
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
          ListPopularRooms(availableVideoRooms: _availableRooms, isVideoLoading: _isVideoLoading),
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
          ListLiveStream(availableRooms: _availableRooms),
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
