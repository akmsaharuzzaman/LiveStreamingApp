import 'package:flutter/material.dart';

class BonusStatus extends StatelessWidget {
  const BonusStatus({super.key, required this.bonusCount});

  final String bonusCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xff111111).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 5),
          Image.asset(
            'assets/icons/bonus_icon.png',
            width: 18,
            height: 18,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to a default icon if bonus_icon.png doesn't exist
              return const Icon(
                Icons.star,
                size: 18,
                color: Color(0xFFFFD700), // Gold color for bonus
              );
            },
          ),
          const SizedBox(width: 5),
          Text(
            bonusCount,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}
