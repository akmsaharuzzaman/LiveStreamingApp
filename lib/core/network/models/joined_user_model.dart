class JoinedUserModel {
  final String id;
  final String avatar;
  final String name;
  final String uid;
  final int diamonds;

  JoinedUserModel({
    required this.id,
    required this.avatar,
    required this.name,
    required this.uid,
    this.diamonds = 0,
  });

  factory JoinedUserModel.fromJson(Map<String, dynamic> json) {
    return JoinedUserModel(
      id: json['_id'] as String,
      avatar: json['avatar'] as String,
      name: json['name'] as String,
      uid: json['uid'] as String,
      diamonds: json['diamonds'] as int? ?? 0,
    );
  }

  // Helper method to create a copy with updated diamonds
  JoinedUserModel copyWith({
    String? id,
    String? avatar,
    String? name,
    String? uid,
    int? diamonds,
  }) {
    return JoinedUserModel(
      id: id ?? this.id,
      avatar: avatar ?? this.avatar,
      name: name ?? this.name,
      uid: uid ?? this.uid,
      diamonds: diamonds ?? this.diamonds,
    );
  }
}
