import 'dart:async';
import 'dart:ui';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/features/live_audio/service/socket_constants.dart';
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
  // Use GetIt to get the properly initialized instance of AudioSocketService
  final AudioSocketService socketService = GetIt.instance<AudioSocketService>();

  // Stream subscriptions for proper cleanup
  StreamSubscription? _audioGetRoomListSubscription;
  final List<StreamSubscription> _audioSubscriptions = [];

  // Available audio rooms list
  List<AudioRoomDetails> _availableAudioRooms = [];

  // Refresh controller
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Ensure socket is connected before setting up listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ensureConnected().then((connected) {
        if (connected) {
          _log('Socket connected successfully on init');
        } else {
          _log('Failed to connect socket on init, will retry later');
          // Schedule a retry after a delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              ensureConnected();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    // Cancel all audio socket subscriptions
    for (var subscription in _audioSubscriptions) {
      subscription.cancel();
    }
    _audioSubscriptions.clear();
    super.dispose();
  }

  void _log(String message) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';
    debugPrint('\n$yellow[AUDIO_LIST_PAGE] - $reset $message\n');
  }

  /// Safely call getRooms with error handling
  void _safeGetRooms() {
    // Add a small delay to ensure the socket is fully initialized
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        if (socketService.isConnected) {
          socketService.getRooms();
        } else {
          _log("❌ Cannot call getRooms - socket is not connected");
          // Try to reconnect
          ensureConnected();
        }
      } catch (e) {
        _log("❌ Error calling getRooms: $e");
        // Try to reconnect on error
        ensureConnected();
      }
    });
  }

  /// Setup audio socket event listeners
  void _setupAudioSocketListeners() {
    _log("🔧 Setting up audio socket listeners...");
    _log("🔧 Audio socket connected: ${socketService.isConnected}");

    // Audio room list updates
    _audioGetRoomListSubscription = socketService.getAllRoomsStream.listen(
      (rooms) {
        _log("📡 Audio rooms stream triggered with ${rooms.length} rooms");
        if (mounted) {
          _log("✅ Updating UI with ${rooms.length} audio rooms");
          setState(() {
            _availableAudioRooms = rooms;
            _isRefreshing = false;
          });
          _log("Available audio rooms: ${rooms.map((room) => room.roomId)} from Frontend");
          _log("Audio rooms count: ${rooms.length}");
        } else {
          _log("❌ Widget not mounted, skipping UI update");
        }
      },
      onError: (error) {
        _log("❌ Audio rooms stream error: $error");
      },
      onDone: () {
        _log("🔚 Audio rooms stream completed");
      },
    );
    // Also add to the cleanup list
    _audioSubscriptions.add(_audioGetRoomListSubscription!);

    // Listen for connection status changes
    var connectionSub = socketService.connectionStatusStream.listen((isConnected) {
      _log("🔌 Audio socket connection status changed: $isConnected");
      if (isConnected && mounted) {
        // Refresh room list when connection is established or re-established
        // Add a small delay to ensure the socket is fully initialized
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            if (socketService.isConnected) {
              socketService.getRooms();
            } else {
              _log("❌ Socket disconnected before getRooms could be called");
            }
          } catch (e) {
            _log("❌ Error calling getRooms: $e");
          }
        });
      }
    });
    _audioSubscriptions.add(connectionSub);

    // Listen for room creation/deletion events to trigger refresh
    var createRoomSub = socketService.createRoomStream.listen((roomDetails) {
      _log("🏠 Audio room created - refreshing room list. Room ID: ${roomDetails.roomId}");
      if (mounted) {
        _log("🔄 Calling getRooms() after room creation");
        _safeGetRooms();
      }
    });
    _audioSubscriptions.add(createRoomSub);

    var closeRoomSub = socketService.closeRoomStream.listen((roomIds) {
      _log("🏠 Audio room closed - refreshing room list. Room IDs: $roomIds");
      if (mounted) {
        _log("🔄 Calling getRooms() after room closure");
        _safeGetRooms();
      }
    });
    _audioSubscriptions.add(closeRoomSub);

    // Add direct listeners to socket for debugging
    socketService.on(AudioSocketConstants.getAllRoomsEvent, (data) {
      _log("🎯 Direct socket event 'get-all-rooms' received: ${data != null ? 'data present' : 'no data'}");
    });

    socketService.on(AudioSocketConstants.createRoomEvent, (data) {
      _log("🎯 Direct socket event 'create-room' received: ${data != null ? 'data present' : 'no data'}");
    });

    // Force a refresh of the room list to ensure we have the latest data
    _log("🔄 Initial getRooms() call to ensure latest data");
    _safeGetRooms();

    _log("✅ Audio socket listeners setup complete");
  }

  /// Method to ensure socket is connected
  Future<bool> ensureConnected() async {
    _log('🔍 Checking audio socket connection status');

    if (!socketService.isConnected) {
      _log('❌ Audio socket not connected, attempting to reconnect...');

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
        _log('❌ User ID is null or empty, cannot connect to audio socket');
        return false;
      }

      // Connect to audio socket with user ID
      final connected = await socketService.connect(userId);

      if (connected) {
        _log('✅ Audio socket reconnected successfully');

        // Clear existing listeners and set up new ones
        for (var subscription in _audioSubscriptions) {
          subscription.cancel();
        }
        _audioSubscriptions.clear();

        // Add a small delay to ensure the socket is fully initialized before setting up listeners
        await Future.delayed(const Duration(milliseconds: 500));

        _setupAudioSocketListeners();
        return true;
      } else {
        _log('❌ Failed to reconnect audio socket');
        return false;
      }
    } else {
      _log('✅ Audio socket already connected');
      return true;
    }
  }

  /// Handle refresh action
  Future<void> _handleRefresh() async {
    _log('🔄 Pull-to-refresh triggered');
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Ensure socket is connected and listeners are set up
      final socketReady = await ensureConnected();

      if (!socketReady) {
        _log('❌ Failed to ensure audio socket connection');
        throw Exception('Failed to connect to audio socket');
      }

      // Explicitly request the latest rooms
      _log('📡 Calling getRooms on audio socket...');
      _safeGetRooms();

      // Add a small delay to ensure the refresh indicator shows
      await Future.delayed(const Duration(milliseconds: 1000));

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
                              if (!socketService.isConnected) {
                                await socketService.connect(userId);
                              }

                              // Fetch fresh room details
                              AudioRoomDetails? roomDetails = await socketService.getRoomDetails(
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
