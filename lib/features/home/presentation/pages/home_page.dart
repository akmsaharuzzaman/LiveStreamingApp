import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:dlstarlive/core/network/socket_service.dart';
import 'package:dlstarlive/core/network/api_clients.dart';
import 'package:dlstarlive/features/live_audio/service/socket_service_audio.dart';
import 'package:dlstarlive/injection/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import '../../data/models/category_model.dart';
import '../../data/models/user_model.dart';
import '../../../live_audio/data/models/audio_room_details.dart';
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
  late final AudioSocketService _audioSocketService;
  final GenericApiClient _genericApiClient = getIt<GenericApiClient>();
  List<GetRoomModel>? _availableRooms;
  List<AudioRoomDetails>? _availableAudioRooms;

  // Stream subscriptions for proper cleanup
  StreamSubscription? _connectionStatusSubscription;
  StreamSubscription? _getRoomListSubscription;
  StreamSubscription? _audioGetRoomListSubscription;
  StreamSubscription? _errorSubscription;

  // Tab controller for horizontal sliding tabs
  late TabController _tabController;

  // Banner URLs - will be populated from API
  List<String> _bannerUrls = [];
  bool _isBannersLoading = true;

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

      // Connect to audio socket
      debugPrint('Connecting to audio socket with user ID: $userId');
      final audioConnected = await _audioSocketService.connect(userId);

      if (audioConnected) {
        debugPrint('✅ Audio socket connected successfully');
        _setupAudioSocketListeners();
        // Get list of available audio rooms
        debugPrint('Fetching audio rooms...');
        await _audioSocketService.getRooms();
      } else {
        debugPrint('❌ Failed to connect to audio server');
      }
    } catch (e) {
      debugPrint('Connection error: $e');
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    // Connection status
    debugPrint("Setting up socket listeners");
    _connectionStatusSubscription = _socketService.connectionStatusStream.listen((isConnected) {
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
          // debugPrint("Available rooms: ${rooms.map((room) => room.roomId)} from Frontend");
        });
      }
    });
  }

  /// Setup audio socket event listeners
  void _setupAudioSocketListeners() {
    debugPrint("🔧 Setting up audio socket listeners...");
    debugPrint("🔧 Audio socket connected: ${_audioSocketService.isConnected}");

    // Audio room list updates
    _audioGetRoomListSubscription = _audioSocketService.getAllRoomsStream.listen(
      (rooms) {
        debugPrint("📡 Audio rooms stream triggered with ${rooms.length} rooms");
        if (mounted) {
          debugPrint("✅ Updating UI with ${rooms.length} audio rooms");
          setState(() {
            _availableAudioRooms = rooms;
            debugPrint("Available audio rooms: ${rooms.map((room) => room.roomId)} from Frontend");
            debugPrint("Audio rooms count: ${rooms.length}");
          });
        } else {
          debugPrint("❌ Widget not mounted, skipping UI update");
        }
      },
      onError: (error) {
        debugPrint("❌ Audio rooms stream error: $error");
      },
      onDone: () {
        debugPrint("🔚 Audio rooms stream completed");
      },
    );

    debugPrint("✅ Audio socket listeners setup complete");
  }

  /// Handle pull-to-refresh action
  Future<void> _handleRefresh() async {
    try {
      debugPrint('🔄 Home page refresh triggered - fetching latest rooms and banners');

      // Refresh both rooms and banners simultaneously
      await Future.wait([
        // Check if socket is connected and get rooms
        () async {
          if (!_socketService.isConnected) {
            debugPrint('Socket not connected, attempting to reconnect...');
            await _initializeSocket();
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
      debugPrint('Error during refresh: $e');
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

  /// Handle audio pull-to-refresh action
  Future<void> _handleAudioRefresh() async {
    try {
      debugPrint('🔄 Audio page refresh triggered - fetching latest audio rooms');
      if (!_audioSocketService.isConnected) {
        debugPrint('Audio socket not connected, attempting to reconnect...');
        await _initializeSocket().then((value) {
          debugPrint('✅ Audio socket connected successfully');
          _setupAudioSocketListeners();
          debugPrint('📡 Calling getRooms on audio socket...');
          _audioSocketService.getRooms();
        }); // This will reconnect both
      } else {
        debugPrint('Audio socket already connected, calling getRooms...');
        debugPrint('📡 Calling getRooms on audio socket...');
        await _audioSocketService.getRooms();
      }
    } catch (e) {
      debugPrint('Error during audio refresh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh audio content. Please try again.'),
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
      debugPrint('🎨 Fetching banners from API');

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

          debugPrint('✅ Loaded ${urls.length} banners from API');
        } else {
          throw Exception('API response indicates failure');
        }
      } else {
        throw Exception('Failed to get banners: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching banners: $e');
      // Use fallback banners if API fails
      if (mounted) {
        setState(() {
          _isBannersLoading = false;
        });
      }
      debugPrint('🔄 Using fallback banners');
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

    // Get AudioSocketService from dependency injection
    _audioSocketService = context.read<AudioSocketService>();

    _initializeSocket();
    _fetchBanners(); // Fetch banners from API

    // Trigger refresh each time HomePage is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🏠 HomePage created - triggering auto-refresh');
      _handleRefresh();
      _handleAudioRefresh();
    });

    // Removed duplicate _setupSocketListeners() call - it's already called in _initializeSocket()
    super.initState();
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions to prevent setState calls after disposal
    _connectionStatusSubscription?.cancel();
    _getRoomListSubscription?.cancel();
    _audioGetRoomListSubscription?.cancel();
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
          ListLiveStream(availableRooms: _availableRooms ?? []),
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
    return RefreshIndicator(
      onRefresh: _handleAudioRefresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 18.sp),
          ListAudioRooms(availableAudioRooms: _availableAudioRooms ?? []),
        ],
      ),
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
