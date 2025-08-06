 import 'package:flutter/material.dart';

void showSendMessageBottomSheet(BuildContext context, {
  VoidCallback? onSendMessage,
}) {
    //show a button sheet with a text field and keyboard for chat input
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ShowMessageBottomsheet(
          onSendMessage: onSendMessage ?? () {
            // Default action if no callback is provided
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Message sent!')),
            );
          },
          
        );
      },
    );
  }

  class ShowMessageBottomsheet extends StatefulWidget {
  const ShowMessageBottomsheet({super.key, required this.onSendMessage});
  final VoidCallback onSendMessage;

  @override
  State<ShowMessageBottomsheet> createState() => _ShowMessageBottomsheetState();
}

class _ShowMessageBottomsheetState extends State<ShowMessageBottomsheet> {
  @override
  Widget build(BuildContext context) {
    //Build a message box and when click it show keyboard
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Type your message here...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              widget.onSendMessage();
              Navigator.pop(context); // Close the bottom sheet
            },
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              widget.onSendMessage();
              Navigator.pop(context); // Close the bottom sheet
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }
}