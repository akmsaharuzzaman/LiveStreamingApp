class LeftUserModel {
  final String id;
  final String avatar;
  final String name;
  final String uid;

  LeftUserModel({
    required this.id,
    required this.avatar,
    required this.name,
    required this.uid,
  });

  factory LeftUserModel.fromJson(Map<String, dynamic> json) {
    return LeftUserModel(
      id: json['_id'] as String,
      avatar: json['avatar'] as String,
      name: json['name'] as String,
      uid: json['uid'] as String,
    );
  }
}