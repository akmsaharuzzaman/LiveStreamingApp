import 'package:flutter/material.dart';

class InboxSettings extends StatefulWidget {
  const InboxSettings({super.key});

  @override
  State<InboxSettings> createState() => _InboxSettingsState();
}

class _InboxSettingsState extends State<InboxSettings> {
  String selectedMessageFrom = 'Higher level users';
  bool liveStreamLink = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Inbox',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            
            // Accept private messages from section
            const Text(
              'Accept private messages from',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
            
            // Message options
            _buildMessageOption('All users', false),
            _buildMessageOption('Users on followed list', false),
            _buildMessageOption('Higher level users', true),
            
            const SizedBox(height: 32),
            
            // User level section
            _buildLevelRow('User level', 'Lv 5', Colors.green),
            const SizedBox(height: 20),
            
            // Talent level section
            _buildLevelRow('Talent level', '💎1', Colors.blue),
            
            const SizedBox(height: 32),
            
            // Friends message note
            const Text(
              'User can still receive private message from friends',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Message types section
            const Text(
              'Message types to receive',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Live stream link section
            _buildLiveStreamSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMessageFrom = text;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Colors.orange,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelRow(String title, String level, Color badgeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                level,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.black54,
              size: 16,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveStreamSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Live stream link',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        Row(
          children: [
            Switch(
              value: liveStreamLink,
              onChanged: (value) {
                setState(() {
                  liveStreamLink = value;
                });
              },
              activeColor: Colors.pink,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit,
                size: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }
}