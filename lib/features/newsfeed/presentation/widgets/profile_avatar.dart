import 'package:flutter/material.dart';
import 'package:dlstarlive/components/utilities/chat_theme.dart';

class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final bool isActive;
  final bool hasBorder;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    this.isActive = false,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20.0,
          backgroundColor: MyTheme.kPrimaryColor,
          child: CircleAvatar(
            radius: hasBorder ? 17.0 : 20.0,
            backgroundColor: Colors.grey[200],
            backgroundImage: (imageUrl.isNotEmpty)
                ? NetworkImage(imageUrl)
                : null,
            child: (imageUrl.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey, size: 22)
                : null,
          ),
        ),
        isActive
            ? Positioned(
                bottom: 0.0,
                right: 0.0,
                child: Container(
                  height: 15.0,
                  width: 15.0,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(width: 2.0, color: Colors.white),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
