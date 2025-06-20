import 'package:flutter/material.dart';

import '../pages/golive_screen.dart';

class LiveScreenMenuButton extends StatelessWidget {
  final VoidCallback? onDisconnect;
  final VoidCallback? onMuteCall;
  final VoidCallback? onViewProfile;

  const LiveScreenMenuButton({
    super.key,
    this.onDisconnect,
    this.onMuteCall,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xff888686),
        borderRadius: BorderRadius.circular(100),
      ),
      padding: EdgeInsets.all(8),
      child: Center(
        child: PopupMenuButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: LiveScreenLeaveOptions.disconnect,
              child: Row(
                children: [
                  Icon(Icons.call_end, color: Color(0xff888686)),
                  SizedBox(width: 6),
                  Text(
                    "Disconnect",
                    style: TextStyle(color: Color(0xff888686)),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: LiveScreenLeaveOptions.muteCall,
              child: Row(
                children: [
                  Icon(Icons.mic_off),
                  SizedBox(width: 6),
                  Text("Mute Call"),
                ],
              ),
            ),
            PopupMenuItem(
              value: LiveScreenLeaveOptions.viewProfile,
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 6),
                  Text("View Profile"),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == LiveScreenLeaveOptions.disconnect) {
              if (onDisconnect != null) onDisconnect!();
            } else if (value == LiveScreenLeaveOptions.muteCall) {
              if (onMuteCall != null) onMuteCall!();
            } else if (value == LiveScreenLeaveOptions.viewProfile) {
              if (onViewProfile != null) onViewProfile!();
            }
          },
          child: Icon(Icons.logout, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
