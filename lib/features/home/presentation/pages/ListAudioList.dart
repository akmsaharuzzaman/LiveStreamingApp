import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../live_audio/models/audio_room_details.dart';
import '../../../live_audio/service/socket_service_audio.dart';
import '../widgets/custom_networkimage.dart';
import '../widgets/touchable_opacity_widget.dart';

class ListAudioRooms extends StatelessWidget {
  final List<AudioRoomDetails> availableAudioRooms;
  final AudioSocketService socketService;
  const ListAudioRooms({super.key, required this.availableAudioRooms, required this.socketService});

  @override
  Widget build(BuildContext context) {
    debugPrint("ListAudioRooms building with ${availableAudioRooms.length} rooms");
    if (availableAudioRooms.isEmpty) {
      debugPrint("No audio rooms available - showing empty state");
      return Expanded(
        child: Center(
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
              SizedBox(height: 8.h),
              ElevatedButton(
                onPressed: () async {
                  await socketService.getRooms();
                },
                child: Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    debugPrint("Rendering audio rooms grid with ${availableAudioRooms.length} rooms");
    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: 16.sp,
        ).add(EdgeInsets.only(bottom: 80.sp)),
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
            onTap: () {
              // Navigate to the audio room screen with the room ID using the named route
              context.pushNamed(
                'audioLive', // You'll need to define this route
                queryParameters: {
                  'roomId': availableAudioRooms[index].roomId,
                  'hostName':
                      availableAudioRooms[index].hostDetails?.name ?? 'Unknown Host',
                  'hostUserId':
                      availableAudioRooms[index].hostDetails?.id ?? 'Unknown User',
                  'hostAvatar':
                      availableAudioRooms[index].hostDetails?.avatar ??
                      'Unknown Avatar',
                },
                extra: {
                  'existingViewers': availableAudioRooms[index].membersDetails,
                  'hostCoins': availableAudioRooms[index].hostGifts,
                  'roomData': availableAudioRooms[index], // Pass complete room data
                },
              );
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
  const AudioRoomCard({
    super.key,
    required this.audioRoomModel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TouchableOpacity(
      onTap: onTap,
      child: Stack(
        children: [
          CustomNetworkImage(
            urlToImage:
                audioRoomModel.hostDetails?.avatar ??
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
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.89),
                    ],
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.sp,
                                vertical: 2.sp,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.mic,
                                    size: 17.sp,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 5.sp),
                                  Text(
                                    '${audioRoomModel.members?.length ?? 0}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.sp,
                            vertical: 2.sp,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent, // Blue for audio rooms
                            borderRadius: BorderRadius.circular(9.sp),
                          ),
                          child: Text(
                            'Audio',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${audioRoomModel.hostDetails?.name ?? 'Unknown Host'} is in audio room',
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
                        audioRoomModel.hostDetails?.avatar ??
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
                          audioRoomModel.hostDetails?.name ?? 'Unknown Host',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'ID: ${audioRoomModel.hostDetails?.uid?.substring(0, 6) ?? 'Unknown ID'}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: Colors.white,
                    position: PopupMenuPosition.under,
                    icon: Container(
                      color: Colors.transparent,
                      child: Icon(
                        Icons.more_horiz,
                        size: 20.sp,
                        color: Colors.black,
                      ),
                    ),
                    onSelected: (String result) {
                      // Handle your menu selection here
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
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