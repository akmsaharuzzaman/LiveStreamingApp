class MuteUserModel {
  final String userId;
  final bool isMuted;
  final List<String> mutedUsers;
  final String message;

  MuteUserModel({
    required this.userId,
    required this.isMuted,
    required this.mutedUsers,
    required this.message,
  });

  factory MuteUserModel.fromJson(Map<String, dynamic> json) {
    return MuteUserModel(
      userId: json['userId'] as String,
      isMuted: json['isMuted'] as bool,
      mutedUsers: List<String>.from(json['mutedUsers'] ?? []),
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isMuted': isMuted,
      'mutedUsers': mutedUsers,
      'message': message,
    };
  }
}