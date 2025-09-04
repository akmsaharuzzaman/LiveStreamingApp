class CallRequestModel {
  final String userId;
  final UserDetails userDetails;
  final String roomId;

  CallRequestModel({
    required this.userId,
    required this.userDetails,
    required this.roomId,
  });

  factory CallRequestModel.fromJson(Map<String, dynamic> json) {
    return CallRequestModel(
      userId: json['userId'] as String,
      userDetails: UserDetails.fromJson(
        json['userDetails'] as Map<String, dynamic>,
      ),
      roomId: json['roomId'] as String,
    );
  }
}

class UserDetails {
  final String id;
  final String avatar;
  final String name;
  final String uid;

  UserDetails({
    required this.id,
    required this.avatar,
    required this.name,
    required this.uid,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['_id'] as String,
      avatar: json['avatar'] as String,
      name: json['name'] as String,
      uid: json['uid'] as String,
    );
  }
}
