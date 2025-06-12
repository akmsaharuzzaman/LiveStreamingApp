import 'package:flutter/material.dart';

import '../widgets/all_chats.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({
    Key? key,
  }) : super(key: key);

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
