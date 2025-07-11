import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingM),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(UIConstants.spacingM),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(
                    UIConstants.borderRadiusM,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.chat, color: Colors.green, size: 32),
                    SizedBox(width: UIConstants.spacingM),
                    Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: UIConstants.spacingL),

              // Content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(UIConstants.spacingL),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.message,
                          size: 80,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: UIConstants.spacingL),
                      Text(
                        'No Conversations Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: UIConstants.spacingM),
                      Text(
                        'Start chatting with your friends and connections',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: UIConstants.spacingXL),

                      // Recent Activity Placeholder
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(UIConstants.spacingL),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(
                            UIConstants.borderRadiusM,
                          ),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: UIConstants.spacingM),
                            Text(
                              'Recent chats will appear here',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle new chat
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }
}
