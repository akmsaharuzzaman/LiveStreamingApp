/// Constants for Audio Socket Service events and configuration
class AudioSocketConstants {
  // Base URL
  static const String baseUrl = 'http://31.97.222.97:8000';

  // Audio room specific events
  static const String getAllRoomsEvent = 'get-all-audio-rooms'; // 1
  static const String audioRoomDetailsEvent = 'audio-room-details'; // 2
  static const String createRoomEvent = 'create-audio-room'; // 3
  static const String joinAudioRoomEvent = 'join-audio-room'; // 5
  static const String leaveAudioRoomEvent = 'leave-audio-room'; // 6
  static const String userLeftEvent = 'audio-user-left'; // 7
  static const String joinSeatEvent = 'join-audio-seat'; // 8
  static const String leaveSeatEvent = 'leave-audio-seat'; // 9
  static const String removeFromSeatEvent = 'remove-from-seat'; // 10
  static const String sendMessageEvent = 'send-audio-message'; // 11
  static const String errorMessageEvent = 'error-message'; // 12
  static const String muteUnmuteUserEvent = 'audio-mute-unmute'; // 13
  static const String banUserEvent = 'ban-audio-user'; // 14
  static const String unbanUserEvent = 'unban-audio-user'; // 15

  // Connection timeouts
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration roomDetailsTimeout = Duration(seconds: 10);

  // Reconnection settings
  static const int reconnectionAttempts = 5;
  static const int reconnectionDelayMs = 1000;

  // Default values
  static const int defaultNumberOfSeats = 6;
  static const String defaultSeatKey = 'seat-1';
}
