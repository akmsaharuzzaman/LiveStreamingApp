/// Utility functions for chat feature
class ChatUtils {
  /// Generate a room ID from user IDs
  /// Ensures the same room ID is generated regardless of user order
  static String roomIdFromUserIds(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('-');
  }
}
