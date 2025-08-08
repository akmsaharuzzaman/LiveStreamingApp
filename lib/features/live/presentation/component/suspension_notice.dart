import 'dart:ui';

import 'package:flutter/material.dart';

class SuspensionNotice extends StatelessWidget {
  const SuspensionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    // ClipRRect is essential for the rounded corners on the blur effect
    return ClipRRect(
      borderRadius: BorderRadius.circular(5.0), // From your design spec
      child: BackdropFilter(
        // This is what creates the blur
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          // Constrain the size of the notice
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(12.0),
          // Decoration for the semi-transparent background color
          decoration: BoxDecoration(
            // The opacity is from your design spec (56%), but you can adjust it
            color: Colors.black.withValues(alpha: 0.56), 
            borderRadius: BorderRadius.circular(5.0),
          ),
          // Use RichText to style "Notice:" differently
          child: RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.white, fontSize: 14),
              children: <TextSpan>[
                TextSpan(
                  text: 'Notice: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: 'If you come live and do anything obscene, vulgar, or sexual, your ID will be suspended.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}