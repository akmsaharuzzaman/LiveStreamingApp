import 'package:flutter/material.dart';

void showSendMessageBottomSheet(
  BuildContext context, {
  VoidCallback? onSendMessage,
}) {
  //show a button sheet with a text field and keyboard for chat input
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return ShowMessageBottomsheet(
        onSendMessage:
            onSendMessage ??
            () {
              // Default action if no callback is provided
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Message sent!')));
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
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Build a message box and when click it show keyboard
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle for dragging (optional)
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TextField(
                controller: _textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    widget.onSendMessage();
                    Navigator.pop(context);
                  }
                },
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_textController.text.trim().isNotEmpty) {
                          widget.onSendMessage();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
