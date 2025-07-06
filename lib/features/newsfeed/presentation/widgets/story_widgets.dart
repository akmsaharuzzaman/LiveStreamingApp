import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StoryTextOverlay extends StatefulWidget {
  final String text;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final Offset position;
  final VoidCallback? onTap;
  final Function(Offset)? onPositionChanged;

  const StoryTextOverlay({
    super.key,
    required this.text,
    this.textColor = Colors.white,
    this.fontSize = 24.0,
    this.fontWeight = FontWeight.bold,
    this.position = const Offset(0.5, 0.5),
    this.onTap,
    this.onPositionChanged,
  });

  @override
  State<StoryTextOverlay> createState() => _StoryTextOverlayState();
}

class _StoryTextOverlayState extends State<StoryTextOverlay> {
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = widget.position;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx * MediaQuery.of(context).size.width,
      top: _position.dy * MediaQuery.of(context).size.height,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx * MediaQuery.of(context).size.width +
                      details.delta.dx) /
                  MediaQuery.of(context).size.width,
              (_position.dy * MediaQuery.of(context).size.height +
                      details.delta.dy) /
                  MediaQuery.of(context).size.height,
            );
          });
          widget.onPositionChanged?.call(_position);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.textColor,
              fontSize: widget.fontSize.sp,
              fontWeight: widget.fontWeight,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

class StoryControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const StoryControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? Colors.white, size: 24.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}

class StoryColorPicker extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const StoryColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: colors.map((color) => _buildColorOption(color)).toList(),
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () => onColorSelected(color),
      child: Container(
        width: 32.w,
        height: 32.h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class StoryLoadingOverlay extends StatelessWidget {
  final String message;

  const StoryLoadingOverlay({super.key, this.message = 'Processing...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
