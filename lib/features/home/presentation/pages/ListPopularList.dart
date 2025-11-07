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
import 'package:get_it/get_it.dart';

import '../../../live_audio/data/models/audio_room_details.dart';
import '../../../live_audio/service/socket_service_audio.dart';

class ListPopularRooms extends StatefulWidget {
  final List<GetRoomModel> availableVideoRooms;
  final VoidCallback handleVideoRefresh;
  const ListPopularRooms({super.key, required this.availableVideoRooms, required this.handleVideoRefresh});

  @override
  State<ListPopularRooms> createState() => _ListPopularRoomsState();
}

class _ListPopularRoomsState extends State<ListPopularRooms> {
  // Use room data service for audio rooms
  final AudioSocketService _audioSocket = GetIt.instance<AudioSocketService>();

  // Stream subscriptions for proper cleanup
  StreamSubscription? _audioRoomsSubscription;

  // Available audio rooms list
  List<dynamic> _availableAudioRooms = [];

  @override
  void initState() {
    super.initState();
    _log('🎬 ListPopularRooms initialized');

    // Initialize service first (sets up listeners in service)
    AudioAllRoomService().initialize();

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
    _audioRoomsSubscription = AudioAllRoomService().audioRoomsStream.listen(
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
    
    // Refresh video rooms when dependencies change (e.g., tab switch)
    widget.handleVideoRefresh();
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
    widget.handleVideoRefresh();
    _handleAudioRefresh();
  }

  Future<void> _handleAudioRefresh() async {
    _log('🔄 Pull-to-refresh triggered');
    try {
      // Request refresh from room data service
      AudioAllRoomService().requestAudioRooms();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rooms refreshed successfully'),
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

                              try {
                                // Ensure socket is connected before making API calls
                                if (!_audioSocket.isConnected) {
                                  await _audioSocket.connect(userId);
                                }

                                // Fetch fresh room details
                                AudioRoomDetails? roomDetails = await _audioSocket.getRoomDetails(
                                  _availableAudioRooms[audioIndex].roomId,
                                );
                                debugPrint(
                                  "Room details for room ${_availableAudioRooms[audioIndex].roomId}: $roomDetails",
                                );

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
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
