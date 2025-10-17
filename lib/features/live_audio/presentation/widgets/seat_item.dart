import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/seat_model.dart';

class SeatItem extends StatelessWidget {
  final SeatModel seat;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const SeatItem({
    Key? key,
    required this.seat,
    required this.index,
    this.isSelected = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: CircleBorder(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Seat circle
                Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
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
                if (seat.name != null && !seat.isLocked)
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
                if (seat.name != null && !seat.isLocked)
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
              seat.name ?? "Seat ${index + 1}",
              style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
