import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class for interacting with Agora Token Server
class AgoraTokenService {
  // Change this URL to your deployed server URL in production
  static const String baseUrl = 'http://31.97.222.97:8004/api';

  /// Generate RTC token for video/audio calls
  ///
  /// [channelName] - The channel name to join
  /// [uid] - User ID (use 0 for dynamic assignment)
  /// [role] - User role: 'publisher' or 'subscriber'
  /// [expireTime] - Token expiration time in seconds (default: 1 hour)
  static Future<AgoraTokenResponse> getRtcToken({
    required String channelName,
    int uid = 0,
    String role = 'publisher',
    int expireTime = 3600,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/rtc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'channelName': channelName,
          'uid': uid,
          'role': role,
          'expireTime': expireTime,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return AgoraTokenResponse.fromJson(data);
      } else {
        throw AgoraTokenException(
          data['error'] ?? 'Failed to get RTC token',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AgoraTokenException) rethrow;
      throw AgoraTokenException('Network error: $e', 0);
    }
  }

  /// Generate RTM token for real-time messaging
  ///
  /// [uid] - User ID as string
  /// [expireTime] - Token expiration time in seconds (default: 1 hour)
  static Future<AgoraTokenResponse> getRtmToken({
    required String uid,
    int expireTime = 3600,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/rtm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'expireTime': expireTime}),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return AgoraTokenResponse.fromJson(data);
      } else {
        throw AgoraTokenException(
          data['error'] ?? 'Failed to get RTM token',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AgoraTokenException) rethrow;
      throw AgoraTokenException('Network error: $e', 0);
    }
  }

  /// Check server health
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get token service information
  static Future<Map<String, dynamic>> getTokenInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/token/info'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw AgoraTokenException(
          'Failed to get token info',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AgoraTokenException) rethrow;
      throw AgoraTokenException('Network error: $e', 0);
    }
  }
}

/// Response model for Agora token requests
class AgoraTokenResponse {
  final bool success;
  final String token;
  final String appId;
  final String? channelName;
  final dynamic uid;
  final String? role;
  final int expireTime;
  final String expireAt;

  AgoraTokenResponse({
    required this.success,
    required this.token,
    required this.appId,
    this.channelName,
    this.uid,
    this.role,
    required this.expireTime,
    required this.expireAt,
  });

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> json) {
    return AgoraTokenResponse(
      success: json['success'] ?? false,
      token: json['token'] ?? '',
      appId: json['appId'] ?? '',
      channelName: json['channelName'],
      uid: json['uid'],
      role: json['role'],
      expireTime: json['expireTime'] ?? 0,
      expireAt: json['expireAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'token': token,
      'appId': appId,
      'channelName': channelName,
      'uid': uid,
      'role': role,
      'expireTime': expireTime,
      'expireAt': expireAt,
    };
  }

  @override
  String toString() {
    return 'AgoraTokenResponse(success: $success, token: ${token.substring(0, 20)}..., appId: $appId)';
  }
}

/// Exception class for Agora token service errors
class AgoraTokenException implements Exception {
  final String message;
  final int statusCode;

  AgoraTokenException(this.message, this.statusCode);

  @override
  String toString() {
    return 'AgoraTokenException: $message (Status: $statusCode)';
  }
}

/// Example usage class
class AgoraTokenUsageExample {
  static void main() async {
    try {
      // Check if server is healthy
      bool isHealthy = await AgoraTokenService.checkHealth();
      print('Server health: $isHealthy');

      if (!isHealthy) {
        print(
          'Server is not responding. Please check if the token server is running.',
        );
        return;
      }

      // Get RTC token for video call
      final rtcToken = await AgoraTokenService.getRtcToken(
        channelName: 'test_channel',
        uid: 12345,
        role: 'publisher',
        expireTime: 3600,
      );

      print('RTC Token: ${rtcToken.token}');
      print('App ID: ${rtcToken.appId}');
      print('Expires at: ${rtcToken.expireAt}');

      // Get RTM token for messaging
      final rtmToken = await AgoraTokenService.getRtmToken(
        uid: 'user_12345',
        expireTime: 3600,
      );

      print('RTM Token: ${rtmToken.token}');
      print('App ID: ${rtmToken.appId}');
      print('Expires at: ${rtmToken.expireAt}');
    } catch (e) {
      print('Error: $e');
    }
  }
}
