import 'dart:async';
import 'dart:ui';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
import 'package:dlstarlive/core/network/models/get_room_model.dart';
import 'package:dlstarlive/features/home/presentation/pages/ListAudioList.dart';
import 'package:dlstarlive/features/home/presentation/pages/ListLiveStram.dart';
import 'package:dlstarlive/features/live_audio/service/socket_constants.dart';
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
  // Use GetIt to get the properly initialized instance of AudioSocketService
  final AudioSocketService socketService = GetIt.instance<AudioSocketService>();

  // Stream subscriptions for proper cleanup
  StreamSubscription? _audioGetRoomListSubscription;
  final List<StreamSubscription> _audioSubscriptions = [];

  // Available audio rooms list
  List<dynamic> _availableAudioRooms = [];

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
    widget.handleVideoRefresh();
    _handleAudioRefresh();
  }

  Future<void> _handleAudioRefresh() async {
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
            child: _availableAudioRooms.isEmpty && widget.availableVideoRooms.isEmpty
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
                                if (!socketService.isConnected) {
                                  await socketService.connect(userId);
                                }

                                // Fetch fresh room details
                                AudioRoomDetails? roomDetails = await socketService.getRoomDetails(
                                  _availableAudioRooms[audioIndex].roomId,
                                );
                                debugPrint("Room details for room ${_availableAudioRooms[audioIndex].roomId}: $roomDetails");

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
