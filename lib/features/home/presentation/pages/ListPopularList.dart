import 'dart:async';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:dlstarlive/features/home/presentation/pages/ListAudioList.dart';
import 'package:dlstarlive/features/home/presentation/pages/ListLiveStram.dart';
import 'package:dlstarlive/features/home/service/audio_all_room_service.dart';
import 'package:dlstarlive/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../live_audio/data/models/audio_room_details.dart';

class ListPopularRooms extends StatefulWidget {
  final List<GetRoomModel> availableVideoRooms;
  final bool isVideoLoading;
  const ListPopularRooms({super.key, required this.availableVideoRooms, required this.isVideoLoading});

  @override
  State<ListPopularRooms> createState() => _ListPopularRoomsState();
}

class _ListPopularRoomsState extends State<ListPopularRooms> {
  // Use services for room data (read-only)
  final AudioAllRoomService _audioRoomService = AudioAllRoomService();

  // Stream subscriptions for proper cleanup
  StreamSubscription? _audioRoomsSubscription;
  StreamSubscription? _loadingSubscription;

  // Available audio rooms list
  List<AudioRoomDetails> _availableAudioRooms = [];

  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _log('🎬 ListPopularRooms initialized');

    // Initialize with cached data from service (prevents data loss on tab switch)
    _availableAudioRooms = _audioRoomService.cachedAudioRooms;
    _isLoading = _audioRoomService.isLoading;
    _log('📦 Initialized with ${_availableAudioRooms.length} cached audio rooms');

    // Setup stream subscriptions to listen to service for future updates
    _setupAudioRoomListener();
    _setupLoadingListener();
  }

  /// Setup audio room listener
  void _setupAudioRoomListener() {
    _audioRoomsSubscription = _audioRoomService.audioRoomsStream.listen(
      (rooms) {
        _log('📡 Audio rooms received: ${rooms.length}');
        if (mounted) {
          setState(() {
            _availableAudioRooms = rooms;
          });
        }
      },
      onError: (error) {
        _log('❌ Audio rooms error: $error');
      },
      cancelOnError: false,
    );
  }

  /// Setup loading state listener
  void _setupLoadingListener() {
    _loadingSubscription = _audioRoomService.loadingStream.listen(
      (loading) {
        if (mounted) {
          setState(() {
            _isLoading = loading;
          });
        }
      },
      onError: (error) {
        _log('❌ Loading state error: $error');
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _audioRoomsSubscription?.cancel();
    _loadingSubscription?.cancel();
    super.dispose();
  }

  void _log(String message) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';
    debugPrint('\n$yellow[AUDIO_LIST_PAGE] - $reset $message\n');
  }

  /// Handle refresh action
  Future<void> _handleRefresh() async {
    await _handleAudioRefresh();
  }

  Future<void> _handleAudioRefresh() async {
    _log('🔄 Pull-to-refresh triggered');
    await _audioRoomService.requestAudioRooms();
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
            child: (_availableAudioRooms.isEmpty && widget.availableVideoRooms.isEmpty)
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
                              'No Popular Rooms Available',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'No one has started a room yet',
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
                    itemCount: widget.availableVideoRooms.length + _availableAudioRooms.length,
                    itemBuilder: (context, index) {
                      if (index < widget.availableVideoRooms.length) {
                        return LiveStreamCard(
                          liveStreamModel: widget.availableVideoRooms[index],
                          onTap: () {
                            // Navigate to the live stream screen with the room ID using the named route
                            context.pushNamed(
                              'onGoingLive',
                              queryParameters: {
                                'roomId': widget.availableVideoRooms[index].roomId,
                                'hostName': widget.availableVideoRooms[index].hostDetails?.name ?? 'Unknown Host',
                                'hostUserId': widget.availableVideoRooms[index].hostDetails?.id ?? 'Unknown User',
                                'hostAvatar': widget.availableVideoRooms[index].hostDetails?.avatar ?? 'Unknown Avatar',
                              },
                              extra: {
                                'existingViewers': widget.availableVideoRooms[index].membersDetails,
                                'hostCoins': widget.availableVideoRooms[index].hostCoins,
                                'roomData': widget.availableVideoRooms[index], // Pass complete room data
                              },
                            );
                          },
                        );
                      } else {
                        final audioIndex = index - widget.availableVideoRooms.length;
                        return AudioRoomCard(
                          audioRoomModel: _availableAudioRooms[audioIndex],
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
                                "🚀 Navigating to audio room with userId: $userId as Viewer with roomId: ${_availableAudioRooms[audioIndex].roomId}",
                              );

                              // Navigate to the audio room screen with room data
                              context.push(
                                AppRoutes.audioLive,
                                extra: {
                                  'isHost': false,
                                  'roomId': _availableAudioRooms[audioIndex].roomId,
                                  'numberOfSeats': _availableAudioRooms[audioIndex].numberOfSeats,
                                  'title': _availableAudioRooms[audioIndex].title,
                                  'roomDetails': _availableAudioRooms[audioIndex],
                                },
                              );
                            }
                          },
                        );
                      }
                    },
                  ),
          ),
          if (_isLoading || widget.isVideoLoading)
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
