import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showMenuBottomSheet(
  BuildContext context, {
  String? userId,
  bool isHost = false,
  bool? isMuted,
  bool? isAdminMuted,
  VoidCallback? onToggleMute,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return MenuBottomSheet(
        userId: userId,
        isHost: isHost,
        isMuted: isMuted,
        isAdminMuted: isAdminMuted,
        onToggleMute: onToggleMute,
      );
    },
  );
}

class MenuBottomSheet extends StatefulWidget {
  final String? userId;
  final bool isHost;
  final bool? isMuted;
  final bool? isAdminMuted;
  final VoidCallback? onToggleMute;

  const MenuBottomSheet({
    super.key,
    this.userId,
    required this.isHost,
    this.isMuted,
    this.isAdminMuted,
    this.onToggleMute,
  });

  @override
  State<MenuBottomSheet> createState() => _MenuBottomSheetState();
}

class _MenuBottomSheetState extends State<MenuBottomSheet> {
  double modalHeight = 0.7;
  late double modalHight;

  @override
  void initState() {
    super.initState();
    modalHight = widget.isHost ? 0.7 : 0.20;
  }

  /// Get the appropriate mute icon based on current state
  String _getMuteIconPath() {
    if (widget.isMuted == true) {
      return "assets/icons/unmute_icon.png"; // Show unmute icon when muted
    } else {
      return "assets/icons/mute_icon.png"; // Show mute icon when not muted
    }
  }

  /// Get the appropriate label based on current state
  String _getMuteLabel() {
    if (widget.isAdminMuted == true) {
      return 'Muted by Admin'; // Show admin muted status
    } else if (widget.isMuted == true) {
      return 'Unmute'; // Show unmute option when muted
    } else {
      return 'Mute'; // Show mute option when not muted
    }
  }

  /// Handle mute toggle with admin mute check
  void _handleMuteToggle() {
    if (widget.isAdminMuted == true && widget.isMuted == true) {
      // Show snackbar if trying to unmute when admin muted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🔇 You cannot unmute yourself - you have been muted by an admin',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Call the toggle mute callback if available
    widget.onToggleMute?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: widget.isHost
              ? MediaQuery.of(context).size.height * .55
              : MediaQuery.of(context).size.height * modalHight,
          decoration: BoxDecoration(
            // color: const Color(0xFF1A1A2E),
            gradient: const LinearGradient(
              colors: [Color(0xFFEDE5FE), Color(0xFFFFFFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),

              // Control Options Grid
              if (widget.isHost)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: GridView.count(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 0.8,
                      children: [
                        _buildControlOption(
                          iconPath: "assets/icons/share_grid_icon.png",
                          label: 'Share',
                          onTap: () {
                            Navigator.pop(context);
                            // Handle share
                          },
                        ),
                        _buildControlOption(
                          iconPath: "assets/icons/coin_grid_icon.png",
                          label: 'Coin Bag',
                          onTap: () {
                            Navigator.pop(context);
                            // Handle coin bag
                          },
                        ),

                        _buildControlOption(
                          iconPath: "assets/icons/camera_flip_grid_icon.png",
                          label: 'Flip Camera',
                          onTap: () {
                            Navigator.pop(context);
                            // Handle flip camera
                          },
                        ),

                        _buildControlOption(
                          iconPath: "assets/icons/beauty_cam_grid_icon.png",
                          label: 'Beauty Camera',
                          onTap: () {
                            Navigator.pop(context);
                            // Handle beauty camera
                          },
                        ),
                        _buildControlOption(
                          iconPath: "assets/icons/music_grid_icon.png",
                          label: 'Music',
                          onTap: () {
                            Navigator.pop(context);
                            // Handle music
                          },
                        ),
                        _buildControlOption(
                          iconPath: "assets/icons/chat_clear_grid_icon.png",
                          label: 'Chat Clear',
                          onTap: () {
                            Navigator.pop(context);
                            // Handle chat clear
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: GridView.count(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 0.8,
                      children: [
                        _buildControlOption(
                          iconPath: _getMuteIconPath(),
                          label: _getMuteLabel(),
                          onTap: () {
                            Navigator.pop(context);
                            _handleMuteToggle();
                          },
                          isDisabled:
                              widget.isAdminMuted == true &&
                              widget.isMuted == true,
                        ),
                        _buildControlOption(
                          iconPath: "assets/icons/coin_grid_icon.png",
                          label: 'Coin Bag',
                          onTap: () {
                            Navigator.pop(context);
                            // Handle coin bag
                          },
                        ),

                        _buildControlOption(
                          iconPath: "assets/icons/camera_flip_grid_icon.png",
                          label: 'Flip Camera',
                          onTap: () {
                            Navigator.pop(context);
                            // Handle flip camera
                          },
                        ),

                        _buildControlOption(
                          iconPath: "assets/icons/sound_off_icon.png",
                          label: 'Sound Off',
                          onTap: () {
                            Navigator.pop(context);
                            // Handle sound off
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlOption({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              // color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Opacity(
              opacity: isDisabled ? 0.5 : 1.0,
              child: Image.asset(iconPath, width: 25.w, height: 25.h),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: isDisabled
                  ? const Color(0xFF202020).withOpacity(0.5)
                  : const Color(0xFF202020),
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
