import 'dart:io';
import 'package:flutter/foundation.dart';

/// Development utilities for testing the live streaming app
class DevUtils {
  /// Generate a test channel name for development
  static String generateTestChannel() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'test_channel_$timestamp';
  }

  /// Check if running on emulator/simulator
  static bool get isEmulator {
    if (kIsWeb) return false;

    // Check for common emulator indicators
    return Platform.isAndroid &&
        (Platform.environment['ANDROID_EMU'] != null ||
            Platform.environment['ANDROID_PRODUCT_NAME']?.contains('sdk') ==
                true);
  }

  /// Get development-friendly user ID
  static String getDevelopmentUserId() {
    if (kDebugMode) {
      return 'dev_user_${DateTime.now().day}${DateTime.now().hour}';
    }
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Log development information
  static void logDevInfo(String message) {
    if (kDebugMode) {
      print('🔧 DEV: $message');
    }
  }

  /// Create test stream data
  static Map<String, dynamic> createTestStreamData({
    required String userId,
    required String userName,
    String? customTitle,
  }) {
    final streamId = 'stream_${DateTime.now().millisecondsSinceEpoch}';
    final channel = generateTestChannel();

    return {
      'id': streamId,
      'userId': userId,
      'userName': userName,
      'title':
          customTitle ??
          'Test Stream - ${DateTime.now().hour}:${DateTime.now().minute}',
      'description': 'This is a test stream created for development purposes',
      'channelName': channel,
      'category': 'Development',
      'thumbnailUrl': '',
      'isLive': true,
      'startTime': DateTime.now(),
      'endTime': null,
      'viewerCount': 0,
      'tags': ['test', 'development'],
    };
  }

  /// Validate Agora configuration
  static bool validateAgoraConfig() {
    const appId = String.fromEnvironment('AGORA_APP_ID');
    const token = String.fromEnvironment('AGORA_TOKEN');

    if (appId.isEmpty) {
      logDevInfo('❌ AGORA_APP_ID is missing or empty');
      return false;
    }

    if (token.isEmpty) {
      logDevInfo('❌ AGORA_TOKEN is missing or empty');
      return false;
    }

    logDevInfo('✅ Agora configuration looks good');
    return true;
  }

  /// Get test viewer names for chat simulation
  static List<String> getTestViewerNames() {
    return [
      'TestViewer1',
      'DevUser',
      'StreamFan',
      'QATester',
      'BetaUser',
      'TestAccount',
    ];
  }

  /// Create test chat messages
  static List<Map<String, dynamic>> createTestChatMessages(String streamId) {
    final viewers = getTestViewerNames();
    final messages = <Map<String, dynamic>>[];

    for (int i = 0; i < 5; i++) {
      messages.add({
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}_$i',
        'streamId': streamId,
        'userId': 'test_user_$i',
        'userName': viewers[i % viewers.length],
        'message':
            'Test message $i - Hello from ${viewers[i % viewers.length]}!',
        'timestamp': DateTime.now().subtract(Duration(minutes: 5 - i)),
        'type': 'text',
      });
    }

    return messages;
  }
}

/// Quick test scenarios for development
class TestScenarios {
  /// Scenario 1: Create a live stream
  static void testCreateStream() {
    DevUtils.logDevInfo('Starting Test Scenario: Create Stream');

    final testData = DevUtils.createTestStreamData(
      userId: 'dev_user_1',
      userName: 'Test Streamer',
      customTitle: 'Live Development Stream',
    );

    DevUtils.logDevInfo('Test stream data: $testData');
  }

  /// Scenario 2: Simulate viewer joining
  static void testViewerJoin() {
    DevUtils.logDevInfo('Starting Test Scenario: Viewer Join');

    final channel = DevUtils.generateTestChannel();
    DevUtils.logDevInfo('Viewer joining channel: $channel');
  }

  /// Scenario 3: Test chat functionality
  static void testChatMessages() {
    DevUtils.logDevInfo('Starting Test Scenario: Chat Messages');

    final messages = DevUtils.createTestChatMessages('test_stream_123');
    DevUtils.logDevInfo('Generated ${messages.length} test messages');

    for (final message in messages) {
      DevUtils.logDevInfo('💬 ${message['userName']}: ${message['message']}');
    }
  }
}
