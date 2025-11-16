import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/get_room_model.dart';
import '../../service/video_all_room_service.dart';
import '../widgets/custom_networkimage.dart';
import '../widgets/touchable_opacity_widget.dart';

class ListLiveStream extends StatefulWidget {
  final List<GetRoomModel> availableRooms;
  const ListLiveStream({super.key, required this.availableRooms});

  @override
  State<ListLiveStream> createState() => _ListLiveStreamState();
}

class _ListLiveStreamState extends State<ListLiveStream> {
  // Use video room service (read-only)
  final VideoAllRoomService _videoRoomService = VideoAllRoomService();

  // Stream subscriptions
  StreamSubscription? _videoRoomsSubscription;
  StreamSubscription? _loadingSubscription;

  // Local rooms list (synced with service)
  List<GetRoomModel> _localRooms = [];

  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _log('🎬 ListLiveStream initialized');

    // Initialize with passed rooms
    _localRooms = widget.availableRooms;

    // Setup stream subscriptions to listen to service
    _setupVideoRoomListener();
    _setupLoadingListener();
  }

  /// Setup video room listener
  void _setupVideoRoomListener() {
    _videoRoomsSubscription = _videoRoomService.videoRoomsStream.listen(
      (rooms) {
        _log('📺 Video rooms received: ${rooms.length}');
        if (mounted) setState(() => _localRooms = rooms);
      },
      onError: (error) {
        _log('❌ Video rooms error: $error');
      },
      cancelOnError: false,
    );
  }

  /// Setup loading state listener
  void _setupLoadingListener() {
    _loadingSubscription = _videoRoomService.loadingStream.listen(
      (loading) {
        if (mounted) setState(() => _isLoading = loading);
      },
      onError: (error) {
        _log('❌ Loading state error: $error');
      },
      cancelOnError: false,
    );
  }

  @override
  void didUpdateWidget(ListLiveStream oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local rooms when parent passes new data
    if (widget.availableRooms != oldWidget.availableRooms) {
      setState(() => _localRooms = widget.availableRooms);
    }
  }

  @override
  void dispose() {
    _videoRoomsSubscription?.cancel();
    _loadingSubscription?.cancel();
    super.dispose();
  }

  void _log(String message) {
    const blue = '\x1B[34m';
    const reset = '\x1B[0m';
    debugPrint('\n$blue[LIVE_STREAM_PAGE] - $reset $message\n');
  }

  @override
  Widget build(BuildContext context) {
    if (_localRooms.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.live_tv, size: 80.sp, color: Colors.grey.shade400),
              SizedBox(height: 20.h),
              Text(
                'No Live Streams Available',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
              ),
              SizedBox(height: 8.h),
              Text(
                'No one has started live streaming yet',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Stack(
        children: [
          GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.sp).add(EdgeInsets.only(bottom: 80.sp)),
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 0.sp,
              crossAxisSpacing: 10.sp,
              childAspectRatio: 0.70,
            ),
            itemCount: _localRooms.length,
            itemBuilder: (context, index) {
              return LiveStreamCard(
                liveStreamModel: _localRooms[index],
                onTap: () {
                  // Navigate to the live stream screen with the room ID using the named route
                  context.pushNamed(
                    'onGoingLive',
                    queryParameters: {
                      'roomId': _localRooms[index].roomId,
                      'hostName': _localRooms[index].hostDetails?.name ?? 'Unknown Host',
                      'hostUserId': _localRooms[index].hostDetails?.id ?? 'Unknown User',
                      'hostAvatar': _localRooms[index].hostDetails?.avatar ?? 'Unknown Avatar',
                    },
                    extra: {
                      'existingViewers': _localRooms[index].membersDetails,
                      'hostCoins': _localRooms[index].hostCoins,
                      'roomData': _localRooms[index], // Pass complete room data
                    },
                  );
                },
              );
            },
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.pink)),
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
  const LiveStreamCard({super.key, required this.liveStreamModel, required this.onTap});

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
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.89)],
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
                              padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.voice_chat, size: 17.sp, color: Colors.white),
                                  SizedBox(width: 5.sp),
                                  Text(
                                    '${liveStreamModel.members.length}',
                                    style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 2.sp),
                          decoration: BoxDecoration(
                            color: Colors.redAccent, // Always red for live streams
                            borderRadius: BorderRadius.circular(9.sp),
                          ),
                          child: Text(
                            'Live',
                            style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w500),
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
                          style: TextStyle(color: Colors.black, fontSize: 11.sp, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'ID: ${liveStreamModel.hostDetails?.uid.substring(0, 6) ?? 'Unknown ID'}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black, fontSize: 9.sp, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: Colors.white,
                    position: PopupMenuPosition.under,
                    icon: Container(
                      color: Colors.transparent,
                      child: Icon(Icons.more_horiz, size: 20.sp, color: Colors.black),
                    ),
                    onSelected: (String result) {
                      // Handle your menu selection here
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
