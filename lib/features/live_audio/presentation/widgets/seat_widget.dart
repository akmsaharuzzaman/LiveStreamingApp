import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/models/audio_member_model.dart';
import '../../data/models/seat_model.dart';
import '../../data/models/audio_room_details.dart';

class SeatWidget extends StatefulWidget {
  final int numberOfSeats;
  final String? currentUserId;
  final String? currentUserName;
  final String? currentUserAvatar;
  final AudioMember? hostDetails;
  final PremiumSeat? premiumSeat;
  final SeatsData? seatsData;
  final Function(String seatId)? onTakeSeat;
  final Function(String seatId)? onLeaveSeat;
  final Function(String seatId, String targetId)? onRemoveUserFromSeat;
  final bool isHost;
  final String? activeSpeakerUserId;

  const SeatWidget({
    super.key,
    required this.numberOfSeats,
    this.currentUserId,
    this.currentUserName,
    this.currentUserAvatar,
    this.hostDetails,
    this.premiumSeat,
    this.seatsData,
    this.onTakeSeat,
    this.onLeaveSeat,
    this.onRemoveUserFromSeat,
    this.isHost = false,
    this.activeSpeakerUserId,
  });

  @override
  State<SeatWidget> createState() => _SeatWidgetState();
}

class _SeatWidgetState extends State<SeatWidget> {
  late SeatModel hostSeatData; // Host Seat data
  late SeatModel specialSeatData; // Special Seat data
  final List<SeatModel> broadcasterSeatData = []; // Broadcaster Seat data

  int? selectedSeatIndex; // Selected seat for context menu

  void _uiLog(String message) {
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';
    debugPrint('\n$cyan[AUDIO_ROOM] : SeatWidget - $reset $message\n');
  }

  @override
  void initState() {
    super.initState();
    _initializeSeats();
  }

  @override
  void didUpdateWidget(SeatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update seats when room data becomes available or changes
    if ((oldWidget.hostDetails != widget.hostDetails) ||
        (oldWidget.premiumSeat != widget.premiumSeat) ||
        (oldWidget.seatsData != widget.seatsData)) {
      _initializeSeats();
    }
  }

  void _initializeSeats() {
    // Initialize host seat
    if (widget.isHost) {
      hostSeatData = SeatModel(
        id: 'host',
        name: widget.currentUserName,
        avatar: widget.currentUserAvatar,
        userId: widget.currentUserId,
        isLocked: false,
      );
    } else {
      hostSeatData = SeatModel(
        id: 'host',
        name: widget.hostDetails?.name,
        avatar: widget.hostDetails?.avatar,
        userId: widget.hostDetails?.id,
        isLocked: false,
      );
    }

    // Initialize special seat (premium seat)
    specialSeatData = SeatModel(
      id: 'special',
      name: widget.premiumSeat?.member?.name,
      avatar: widget.premiumSeat?.member?.avatar,
      userId: widget.premiumSeat?.member?.id,
      isLocked: !(widget.premiumSeat?.available ?? true),
    );

    broadcasterSeatData.clear();
    // Initialize seats from seatsData
    if (widget.seatsData?.seats != null) {
      for (int i = 1; i < widget.numberOfSeats + 1; i++) {
        broadcasterSeatData.add(SeatModel(id: 'seat-$i', name: null, avatar: null, isLocked: false));
      }
      for (int i = 1; i < widget.seatsData!.seats!.length + 1; i++) {
        _uiLog("Seat-$i is updating with user ${widget.seatsData!.seats!['seat-$i']!.member?.name}");
        if (widget.seatsData!.seats!['seat-$i']!.member != null) {
          broadcasterSeatData[i - 1] = SeatModel(
            id: 'seat-$i',
            name: widget.seatsData!.seats!['seat-$i']!.member!.name,
            avatar: widget.seatsData!.seats!['seat-$i']!.member!.avatar,
            userId: widget.seatsData!.seats!['seat-$i']!.member!.id,
            isLocked: !(widget.seatsData!.seats!['seat-$i']!.available ?? true),
          );
        }
      }
    } else {
      // Fallback: Initialize empty seats based on totalSeats configuration
      for (int i = 1; i < widget.numberOfSeats + 1; i++) {
        broadcasterSeatData.add(SeatModel(id: 'seat-$i', name: null, avatar: null, isLocked: false));
      }
    }
    setState(() {});
  }

  // Get number of columns based on total seats
  int _getGridColumns() {
    switch (widget.numberOfSeats) {
      case 6: // 6 people
        return 3; // 3x2 grid for 6 regular seats
      case 8: // 8 people
        return 4; // 4x2 grid for 8 regular seats
      case 12: // 12 people
        return 4; // 4x3 grid for 12 regular seats
      default:
        return 3; // Default to 3 columns
    }
  }

  void _showHostSeatOptions(SeatModel seat, int index) {
    _uiLog('\n\n_showSeatOptions called for seat: ${seat.id}');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          height: 200.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (seat.isLocked == false && seat.userId == null)
                ListTile(
                  leading: Icon(Icons.lock),
                  title: Text("Seat Lock"),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement seat lock functionality
                    _uiLog("Seat Lock functionality not implemented");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Seat lock functionality not implemented")),
                    );
                  },
                ),
              if (seat.userId != null)
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text("Remove from seat"),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onRemoveUserFromSeat?.call(seat.id, seat.userId!);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showViewerSeatOptions(SeatModel seat, int index) {
    _uiLog('\n\n_showSeatOptions called for seat: ${seat.id}');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          height: 200.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (seat.name == null) ...[
                // Seat is empty
                ListTile(
                  leading: Icon(Icons.event_seat),
                  title: Text("Take Seat"),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onTakeSeat?.call(seat.id);
                  },
                ),
              ] else if (seat.userId == widget.currentUserId) ...[
                // Seat is user's own
                ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text("Leave Seat"),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onLeaveSeat?.call(seat.id);
                  },
                ),
              ] else ...[
                // Seat occupied by others, no options
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // Top row: Host + Special seat (always 2 seats)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: _buildHostSeat(hostSeatData)),
              SizedBox(width: 16.w),
              Expanded(child: _buildPremiumSeat(specialSeatData)),
            ],
          ),

          // Remaining seats in grid
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getGridColumns(),
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 0.h,
              childAspectRatio: 0.8,
            ),
            itemCount: broadcasterSeatData.length, // Exclude host and special seat
            itemBuilder: (context, index) {
              return _buildSeatItem(broadcasterSeatData[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHostSeat(SeatModel hostSeatData) {
    final isActiveSpeaker = widget.activeSpeakerUserId != null && hostSeatData.userId == widget.activeSpeakerUserId;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Glow background when speaking
            if (isActiveSpeaker)
              Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            // Seat circle
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hostSeatData.name != null ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                color: hostSeatData.name != null ? Colors.transparent : Colors.white.withOpacity(0.1),
              ),
              child: ClipOval(
                child: (hostSeatData.avatar != null && hostSeatData.avatar!.isNotEmpty
                    ? Image.network(
                        hostSeatData.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: Icon(Icons.person, color: Colors.white54, size: 28.sp),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.person, color: Colors.white54, size: 28.sp),
                      )),
              ),
            ),

            // Crown badge for all occupied seats
            if (hostSeatData.name != null)
              Positioned(
                top: -25,
                child: Image.asset("assets/icons/audio_room/crown_badge.png", width: 120.w, height: 120.h),
              ),

            // Microphone icon if seat is not muted
            if (hostSeatData.isMuted == false)
              Positioned(
                bottom: -3,
                right: -3,
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Icon(Icons.mic, color: Colors.grey[700], size: 14.sp),
                ),
              )
            else
              Positioned(
                bottom: -3,
                right: -3,
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Icon(Icons.mic_off, color: Colors.grey[700], size: 14.sp),
                ),
              ),
          ],
        ),

        SizedBox(height: 6.h),

        // User name or seat number
        Text(
          hostSeatData.name ?? "Host Seat",
          style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPremiumSeat(SeatModel premiumSeatData) {
    final isActiveSpeaker = widget.activeSpeakerUserId != null && premiumSeatData.userId == widget.activeSpeakerUserId;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Glow background when speaking
            if (isActiveSpeaker)
              Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            // Seat circle
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: premiumSeatData.name != null ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                color: premiumSeatData.name != null ? Colors.transparent : Colors.white.withOpacity(0.1),
              ),
              child: ClipOval(
                child: premiumSeatData.name != null
                    ? (premiumSeatData.avatar != null && premiumSeatData.avatar!.isNotEmpty
                          ? Image.network(
                              premiumSeatData.avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: Icon(Icons.person, color: Colors.white54, size: 28.sp),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: Icon(Icons.person, color: Colors.white54, size: 28.sp),
                            ))
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage("assets/icons/audio_room/special_seat.png"),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
              ),
            ),

            // Crown badge for all occupied seats
            if (premiumSeatData.name != null)
              Positioned(
                top: -25,
                child: Image.asset(
                  "assets/icons/audio_room/crown_badge.png",
                  width: 110.w,
                  height: 110.h,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 110.w,
                      height: 110.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 3),
                      ),
                    );
                  },
                ),
              ),

            // Microphone icon if seat is occupied
            if (premiumSeatData.name != null)
              Positioned(
                bottom: -3,
                right: -3,
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Icon(Icons.mic, color: Colors.grey[700], size: 14.sp),
                ),
              ),
          ],
        ),

        SizedBox(height: 6.h),

        // User name or seat number
        Text(
          premiumSeatData.name ?? "Premium Seat",
          style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSeatItem(SeatModel seat, int index) {
    final isActiveSpeaker = widget.activeSpeakerUserId != null && seat.userId == widget.activeSpeakerUserId;
    return GestureDetector(
      onTap: () {
        _uiLog("\n\n\n Selected seat index: $index");
        setState(() {
          selectedSeatIndex = index;
        });
        if (widget.isHost) {
          _showHostSeatOptions(seat, index);
        } else {
          _showViewerSeatOptions(seat, index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Glow background when speaking
              if (isActiveSpeaker)
                Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              // Seat circle
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  color: Colors.transparent, // Add transparent background for InkWell
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: seat.name != null ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: seat.name != null
                      ? (seat.avatar != null && seat.avatar!.isNotEmpty
                            ? Image.network(
                                seat.avatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: Icon(Icons.person, color: Colors.white54, size: 28.sp),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[800],
                                child: Icon(Icons.person, color: Colors.white54, size: 28.sp),
                              ))
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(
                                seat.isLocked
                                    ? "assets/icons/audio_room/lock_seat.png"
                                    : "assets/icons/audio_room/empty_seat.png",
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                ),
              ),

              // Crown badge for all occupied seats
              if (seat.name != null)
                Positioned(
                  top: -25,
                  child: Image.asset("assets/icons/audio_room/crown_badge.png", width: 120.w, height: 120.h),
                ),

              // Microphone icon if seat is occupied
              if (seat.userId != null) ...[
                if (seat.isMuted == false)
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Icon(Icons.mic, color: Colors.grey[700], size: 14.sp),
                    ),
                  )
                else
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Icon(Icons.mic_off, color: Colors.grey[700], size: 14.sp),
                    ),
                  ),
              ],
            ],
          ),

          SizedBox(height: 6.h),

          // User name or seat number
          Text(
            seat.name ?? "Seat ${index + 1}",
            style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
