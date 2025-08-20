class MuteUserModel {
  final String lastMutedUserId;
  final bool lastUserIsMuted;
  final List<String> allMutedUsersList;
  final String messageToLastUser;

  MuteUserModel({
    required this.lastMutedUserId,
    required this.lastUserIsMuted,
    required this.allMutedUsersList,
    required this.messageToLastUser,
  });

  factory MuteUserModel.fromJson(Map<String, dynamic> json) {
    return MuteUserModel(
      lastMutedUserId: json['userId'] as String,
      lastUserIsMuted: json['isMuted'] as bool,
      allMutedUsersList: List<String>.from(json['mutedUsers'] ?? []),
      messageToLastUser: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': lastMutedUserId,
      'isMuted': lastUserIsMuted,
      'mutedUsers': allMutedUsersList,
      'message': messageToLastUser,
    };
  }
}
