import 'package:flutter/material.dart';

import '../widgets/all_chats.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AllChats(),
        ],
      ),
    );
  }
}
