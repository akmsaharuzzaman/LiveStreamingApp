import 'dart:async';
import 'dart:ui';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/features/home/service/audio_all_room_service.dart';
import 'package:dlstarlive/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../live_audio/data/models/audio_room_details.dart';
import '../../../live_audio/service/socket_service_audio.dart';
import '../widgets/custom_networkimage.dart';
import '../widgets/touchable_opacity_widget.dart';

class ListAudioRooms extends StatefulWidget {
  const ListAudioRooms({super.key});

  @override
  State<ListAudioRooms> createState() => _ListAudioRoomsState();
}

class _ListAudioRoomsState extends State<ListAudioRooms> {
  // Use audio room service
  final AudioAllRoomService _audioRoomService = AudioAllRoomService();
  final AudioSocketService _audioSocket = GetIt.instance<AudioSocketService>();

  // Stream subscriptions for proper cleanup
  StreamSubscription? _audioRoomsSubscription;

  // Available audio rooms list
  List<AudioRoomDetails> _availableAudioRooms = [];

  // Refresh controller
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _log('🎬 ListAudioRooms initialized');

    // Initialize service first (sets up listeners in service)
    _audioRoomService.initialize();

    // Setup stream subscription (listens to already-initialized service)
    _setupAudioRoomListener();

    // Get user ID and connect audio socket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final userId = authState.user.id;
        if (userId.isNotEmpty) {
          _log('🔌 Connecting audio socket with user: $userId');
          _audioSocket.connect(userId).then((_) {
            _log('✅ Audio socket connected');
            // Request rooms after socket connection
            _audioSocket.getRooms();
          });
        }
      }
    });
  }

  /// Setup audio room listener
  void _setupAudioRoomListener() {
    _audioRoomsSubscription = _audioRoomService.audioRoomsStream.listen(
      (rooms) {
        _log('📡 Audio rooms received: ${rooms.length}');
        if (mounted) {
          setState(() {
            _availableAudioRooms = rooms;
            _isRefreshing = false;
          });
        }
      },
      onError: (error) {
        _log('❌ Audio rooms error: $error');
      },
      cancelOnError: false,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Reconnect audio socket if needed (after dispose or disconnect)
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final userId = authState.user.id;
      if (userId.isNotEmpty && !_audioSocket.isConnected) {
        _log('🔌 Reconnecting audio socket in didChangeDependencies');
        _audioSocket.connect(userId).then((_) {
          _audioSocket.getRooms();
        });
      } else if (_audioSocket.isConnected) {
        // Already connected, just refresh
        _audioSocket.getRooms();
      }
    }
  }

  @override
  void dispose() {
    _audioRoomsSubscription?.cancel();
    super.dispose();
  }

  void _log(String message) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';
    debugPrint('\n$yellow[AUDIO_LIST_PAGE] - $reset $message\n');
  }

  /// Handle refresh action
  Future<void> _handleRefresh() async {
    _log('🔄 Pull-to-refresh triggered');
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Request refresh from room data service
      AudioAllRoomService().requestAudioRooms();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio rooms refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      _log('❌ Error during audio refresh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh audio content: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.pink,
            backgroundColor: Colors.white,
            strokeWidth: 3.0,
            displacement: 50.0,
            child: _availableAudioRooms.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.music_note, size: 80.sp, color: Colors.grey.shade400),
                            SizedBox(height: 20.h),
                            Text(
                              'No Audio Rooms Available',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'No one has started an audio room yet',
                              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.sp).add(EdgeInsets.only(bottom: 80.sp)),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 0.sp,
                      crossAxisSpacing: 10.sp,
                      childAspectRatio: 0.70,
                    ),
                    itemCount: _availableAudioRooms.length,
                    itemBuilder: (context, index) {
                      return AudioRoomCard(
                        audioRoomModel: _availableAudioRooms[index],
                        onTap: () async {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthUnauthenticated) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('User is not authenticated')));
                            return;
                          }
                          if (authState is AuthAuthenticated) {
                            if (authState.user.id.isEmpty) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text('User ID is empty')));
                              return;
                            }
                            final userId = authState.user.id;
                            debugPrint(
                              "🚀 Navigating to audio room with userId: $userId as Viewer with roomId: ${_availableAudioRooms[index].roomId}",
                            );

                            try {
                              // Ensure socket is connected before making API calls
                              if (!_audioSocket.isConnected) {
                                await _audioSocket.connect(userId);
                              }

                              // Fetch fresh room details
                              AudioRoomDetails? roomDetails = await _audioSocket.getRoomDetails(
                                _availableAudioRooms[index].roomId,
                              );
                              debugPrint("Room details for room ${_availableAudioRooms[index].roomId}: $roomDetails");

                              if (roomDetails == null || roomDetails.roomId.isEmpty) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(const SnackBar(content: Text('Room details not found')));
                                return;
                              }

                              // Navigate to the audio room screen with updated room data
                              context.push(
                                AppRoutes.audioLive,
                                extra: {
                                  'isHost': false,
                                  // Pass fresh room data
                                  'roomId': roomDetails.roomId,
                                  'numberOfSeats': roomDetails.numberOfSeats,
                                  'title': roomDetails.title,
                                  //'userId': userId,
                                  'roomDetails': roomDetails,
                                },
                              );
                            } catch (e) {
                              // Fallback to original navigation on error
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('Error: $e, using cached data')));
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
          if (_isRefreshing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class AudioRoomCard extends StatelessWidget {
  final AudioRoomDetails audioRoomModel;
  final Function() onTap;
  const AudioRoomCard({super.key, required this.audioRoomModel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TouchableOpacity(
      onTap: onTap,
      child: Stack(
        children: [
          CustomNetworkImage(
            urlToImage:
                audioRoomModel.hostDetails.avatar ??
                'https://cdn.dribbble.com/users/3245638/screenshots/15628559/media/21f20574f74b6d6f8e74f92bde7de2fd.png?compress=1&resize=400x300&vertical=top',
            height: 180.sp,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(13.sp),
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
                                  Icon(Icons.mic, size: 17.sp, color: Colors.white),
                                  SizedBox(width: 5.sp),
                                  Text(
                                    '${audioRoomModel.members.length}',
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
                            color: Colors.blueAccent, // Blue for audio rooms
                            borderRadius: BorderRadius.circular(9.sp),
                          ),
                          child: Text(
                            'Audio',
                            style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${audioRoomModel.hostDetails.name} is live now',
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
                        audioRoomModel.hostDetails.avatar ??
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
                          audioRoomModel.hostDetails.name ?? 'Unknown Host',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black, fontSize: 11.sp, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'ID: ${audioRoomModel.hostDetails.uid?.substring(0, 6) ?? 'Unknown ID'}',
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
