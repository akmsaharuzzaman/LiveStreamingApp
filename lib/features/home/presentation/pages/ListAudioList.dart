import 'dart:ui';
import 'package:dlstarlive/core/auth/auth_bloc.dart';
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

class ListAudioRooms extends StatelessWidget {
  final List<AudioRoomDetails> availableAudioRooms;
  // Use GetIt to get the properly initialized instance of AudioSocketService
  final AudioSocketService socketService = GetIt.instance<AudioSocketService>();
  final Function() onRefreshCallback;
  ListAudioRooms({super.key, required this.availableAudioRooms, required this.onRefreshCallback});

  @override
  Widget build(BuildContext context) {
    if (availableAudioRooms.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note, size: 80.sp, color: Colors.grey.shade400),
              SizedBox(height: 20.h),
              Text(
                'No Audio Rooms Available',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
              ),
              SizedBox(height: 8.h),
              Text(
                'No one has started an audio room yet',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
              ),
              SizedBox(height: 8.h),
              ElevatedButton(
                onPressed: onRefreshCallback,
                child: Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    debugPrint(" #### ListAudioRooms: building with ${availableAudioRooms.length} rooms  ####");
    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.sp).add(EdgeInsets.only(bottom: 80.sp)),
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 0.sp,
          crossAxisSpacing: 10.sp,
          childAspectRatio: 0.70,
        ),
        itemCount: availableAudioRooms.length,
        itemBuilder: (context, index) {
          return AudioRoomCard(
            audioRoomModel: availableAudioRooms[index],
            onTap: () async {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthUnauthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User is not authenticated')));
                return;
              }
              if (authState is AuthAuthenticated) {
                if (authState.user.id.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User ID is empty')));
                  return;
                }
                final userId = authState.user.id;
                debugPrint(
                  "🚀 Navigating to audio room with userId: $userId as Viewer with roomId: ${availableAudioRooms[index].roomId}",
                );

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loading room details...')));

                // context.push(
                //   AppRoutes.audioLive,
                //   extra: {
                //     'isHost': false,
                //     // Pass fresh room data
                //     'roomId': availableAudioRooms[index].roomId,
                //     'numberOfSeats': availableAudioRooms[index].numberOfSeats,
                //     'title': availableAudioRooms[index].title,
                //     'roomDetails': availableAudioRooms[index],
                //     // userId
                //     'userId': userId,
                //   },
                // );

                try {
                  // Ensure socket is connected before making API calls
                  if (!socketService.isConnected) {
                    await socketService.connect(userId);
                  }
                  
                  // Fetch fresh room details
                  AudioRoomDetails? roomDetails = await socketService.getRoomDetails(availableAudioRooms[index].roomId);
                  debugPrint("Room details for room ${availableAudioRooms[index].roomId}: $roomDetails");

                  if (roomDetails == null || roomDetails.roomId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room details not found')));
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
                      'roomDetails': roomDetails,
                      // userId
                      'userId': userId,
                    },
                  );
                } catch (e) {
                  // Fallback to original navigation on error
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e, using cached data')));
                }
              }
            },
          );
        },
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
