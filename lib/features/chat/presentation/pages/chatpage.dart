import 'package:flutter/material.dart';

class ChatPageScreen extends StatelessWidget {
  const ChatPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: const Center(
        child: Text(
          'This feature will be implemented soon.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
