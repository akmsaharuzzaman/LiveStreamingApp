class JoinedUserModel {
  final String id;
  final String avatar;
  final String name;
  final String uid;

  JoinedUserModel({
    required this.id,
    required this.avatar,
    required this.name,
    required this.uid,
  });

  factory JoinedUserModel.fromJson(Map<String, dynamic> json) {
    return JoinedUserModel(
      id: json['_id'] as String,
      avatar: json['avatar'] as String,
      name: json['name'] as String,
      uid: json['uid'] as String,
    );
  }
}