import 'package:flutter/material.dart';

class EndStreamOverlay extends StatelessWidget {
  final VoidCallback onKeepStream;
  final VoidCallback onEndStream;

  const EndStreamOverlay({
    super.key,
    required this.onKeepStream,
    required this.onEndStream,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onKeepStream,
    required VoidCallback onEndStream,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return EndStreamOverlay(
          onKeepStream: onKeepStream,
          onEndStream: onEndStream,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Keep button
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // Close dialog
                onKeepStream();
              },
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF69B4), Color(0xFFFF8FA3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF69B4).withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const Text(
              'Keep',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            // Exit button
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // Close dialog
                onEndStream();
              },
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF69B4), Color(0xFFFF8FA3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF69B4).withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.power_settings_new,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const Text(
              'Exit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
