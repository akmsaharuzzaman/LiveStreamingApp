import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum WhoAmI { user, admin, host, myself }

class CallOverlayWidget extends StatefulWidget {
  final String? userImage;
  final String? userName;
  final String? userId;
  final VoidCallback? onDisconnect;
  final VoidCallback? onMute;
  final VoidCallback? onManage;
  // Manage actions
  final ValueChanged<String>? onSetAdmin; // userId
  final ValueChanged<String>? onMuteUser; // userId
  final ValueChanged<String>? onKickOut; // userId (alias of ban)
  final ValueChanged<String>? onBanUser; // userId
  final WhoAmI whoAmI;

  const CallOverlayWidget({
    super.key,
    this.userImage,
    this.userName,
    this.userId,
    this.onDisconnect,
    this.onMute,
    this.onManage,
    this.onSetAdmin,
    this.onMuteUser,
    this.onKickOut,
    this.onBanUser,
    required this.whoAmI,
  });

  @override
  State<CallOverlayWidget> createState() => _CallOverlayWidgetState();
}

class _CallOverlayWidgetState extends State<CallOverlayWidget> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _optionsOverlay;

  void _hideOptionsOverlay() {
    _optionsOverlay?.remove();
    _optionsOverlay = null;
  }

  void _showOptionsOverlay() {
    if (_optionsOverlay != null) return; // prevent duplicates

    final overlay = Overlay.of(context);

    _optionsOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent barrier to dismiss on outside tap
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideOptionsOverlay,
              child: const SizedBox.expand(),
            ),
          ),

          // Anchored popover next to the widget
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            // Position the card to the left of the 100x100 widget with slight vertical alignment
            offset: Offset(-180.w, 30.h),
            child: Material(
              color: Colors.transparent,
              child: _buildOptionsCard(context),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_optionsOverlay!);
  }

  Widget _buildOptionsCard(BuildContext context) {
    // Popover card matching screenshot with rounded corners and subtle shadow
    return Container(
      width: 230.w,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverlayAction(
            context,
            icon: Icons.call_end,
            title: 'Disconnect Call',
            color: const Color(0xFFFF5E8D), // pink like screenshot
            isEmphasis: true,
            onTap: () {
              _hideOptionsOverlay();
              widget.onDisconnect?.call();
            },
          ),
          _buildOverlayAction(
            context,
            icon: Icons.mic_off,
            title: 'Mute Call',
            color: Colors.black87,
            onTap: () {
              _hideOptionsOverlay();
              widget.onMute?.call();
            },
          ),
          _buildOverlayAction(
            context,
            icon: Icons.settings,
            title: 'Manage',
            color: Colors.black87,
            onTap: () {
              _hideOptionsOverlay();
              _showManageBottomSheet();
              widget.onManage?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    bool isEmphasis = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: isEmphasis ? const Color(0xFFFF5E8D) : Colors.black87,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: isEmphasis ? FontWeight.w600 : FontWeight.w500,
                  color: isEmphasis ? const Color(0xFFFF5E8D) : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5ECFF), Colors.white],
            ),
          ),
          padding: EdgeInsets.only(
            top: 16.h,
            bottom: 24.h + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center items horizontally
            children: [
              _manageTile(
                Icons.admin_panel_settings,
                'Set Admin',
                onTap: () {
                  Navigator.pop(context);
                  final id = widget.userId;
                  if (id != null) {
                    widget.onSetAdmin?.call(id);
                  }
                },
              ),
              _manageTile(
                Icons.mic_off,
                'Mute User',
                onTap: () {
                  Navigator.pop(context);
                  final id = widget.userId;
                  if (id != null) {
                    // Prefer explicit manage callback, fallback to quick action
                    if (widget.onMuteUser != null) {
                      widget.onMuteUser!.call(id);
                    } else {
                      widget.onMute?.call();
                    }
                  }
                },
              ),
              _manageTile(
                Icons.call_end,
                'Kick Out',
                onTap: () {
                  Navigator.pop(context);
                  final id = widget.userId;
                  if (id != null) {
                    // Kick out uses the same as ban per requirement
                    if (widget.onKickOut != null) {
                      widget.onKickOut!(id);
                    } else {
                      widget.onBanUser?.call(id);
                    }
                  }
                },
              ),
              _manageTile(
                Icons.block,
                'Add to blocklist',
                onTap: () {
                  Navigator.pop(context);
                  final id = widget.userId;
                  if (id != null) {
                    // Blocklist maps to ban function
                    widget.onBanUser?.call(id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _manageTile(IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87, size: 22.sp),
            SizedBox(width: 12.w),
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideOptionsOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          print("Overlay tapped");
          if (widget.whoAmI == WhoAmI.host || widget.whoAmI == WhoAmI.admin) {
            _showOptionsOverlay();
          }
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 15.h),
          height: 120.h,
          width: 100.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.r),
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: widget.userImage != null
                      ? Image.network(
                          widget.userImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: Icon(
                                Icons.person,
                                color: Colors.white54,
                                size: 40.sp,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: Icon(
                            Icons.person,
                            color: Colors.white54,
                            size: 40.sp,
                          ),
                        ),
                ),

                // Blur Overlay
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(color: Colors.black.withOpacity(0.3)),
                  ),
                ),

                // Center Profile Circle
                Center(
                  child: Container(
                    width: 60.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 2.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.userImage != null
                          ? Image.network(
                              widget.userImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[600],
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 30.sp,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[600],
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30.sp,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
