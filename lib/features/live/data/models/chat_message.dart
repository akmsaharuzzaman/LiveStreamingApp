
class ChatMessage {
  final String id;
  final String message;
  final String userId;
  final String userName;
  final String userProfilePic;
  final DateTime timestamp;
  final String streamId;

  ChatMessage({
    required this.id,
    required this.message,
    required this.userId,
    required this.userName,
    required this.userProfilePic,
    required this.timestamp,
    required this.streamId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'timestamp': DateTime.now().isBefore(timestamp)
          ? timestamp.toIso8601String()
          : timestamp,
      'streamId': streamId,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      message: map['message'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userProfilePic: map['userProfilePic'] ?? '',
      timestamp: (map['timestamp'] ).toDate(),
      streamId: map['streamId'] ?? '',
    );
  }
}
