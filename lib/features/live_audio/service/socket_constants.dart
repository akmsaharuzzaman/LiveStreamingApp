/// Constants for Audio Socket Service events and configuration
class AudioSocketConstants {
  // Base URL
  static const String baseUrl = 'http://31.97.222.97:8000';

  // Audio room specific events
  static const String getAllRoomsEvent = 'get-all-audio-rooms'; // 1
  static const String audioRoomDetailsEvent = 'audio-room-details'; // 2
  static const String createRoomEvent = 'create-audio-room'; // 3
  static const String joinAudioRoomEvent = 'join-audio-room'; // 4
  static const String leaveAudioRoomEvent = 'leave-audio-room'; // 5
  static const String userLeftEvent = 'audio-user-left'; // 6
  static const String joinSeatEvent = 'join-audio-seat'; // 7
  static const String leaveSeatEvent = 'leave-audio-seat'; // 8
  static const String removeFromSeatEvent = 'remove-from-seat'; // 9
  static const String sendMessageEvent = 'send-audio-message'; // 10
  static const String errorMessageEvent = 'error-message'; // 11
  static const String muteUnmuteUserEvent = 'audio-mute-unmute'; // 12
  static const String banUserEvent = 'ban-audio-user'; // 13
  // static const String unbanUserEvent = 'unban-audio-user'; // 14
  static const String updateHostBonusEvent = 'update-audio-host-coins'; // 15
  static const String sentAudioGiftsEvent = 'sent-audio-gift'; // 16

  // Connection timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration roomDetailsTimeout = Duration(seconds: 30);

  // Reconnection settings
  static const int reconnectionAttempts = 5;
  static const int reconnectionDelayMs = 1000;

  // Default values
  static const int defaultNumberOfSeats = 6;
  static const String defaultSeatKey = 'seat-1';
}
