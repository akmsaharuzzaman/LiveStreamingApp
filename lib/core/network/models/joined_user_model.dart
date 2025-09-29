class JoinedUserModel {
  final String id;
  final String avatar;
  final String name;
  final String uid;
  final int diamonds;
  final int currentLevel;
  final String currentBackground;
  final String currentTag;

  JoinedUserModel({
    required this.id,
    required this.avatar,
    required this.name,
    required this.uid,
    this.diamonds = 0,
    this.currentLevel = 0,
    this.currentBackground = '',
    this.currentTag = '',
  });

  factory JoinedUserModel.fromJson(Map<String, dynamic> json) {
    return JoinedUserModel(
      id: json['_id'] as String,
      avatar: json['avatar'] as String,
      name: json['name'] as String,
      uid: json['uid'] as String,
      diamonds: json['diamonds'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 0,
      currentBackground: json['currentBackground'] as String,
      currentTag: json['currentTag'] as String,
    );
  }

  // Helper method to create a copy with updated diamonds
  JoinedUserModel copyWith({
    String? id,
    String? avatar,
    String? name,
    String? uid,
    int? diamonds,
    int? currentLevel,
    String? currentBackground,
    String? currentTag,
  }) {
    return JoinedUserModel(
      id: id ?? this.id,
      avatar: avatar ?? this.avatar,
      name: name ?? this.name,
      uid: uid ?? this.uid,
      diamonds: diamonds ?? this.diamonds,
      currentLevel: currentLevel ?? this.currentLevel,
      currentBackground: currentBackground ?? this.currentBackground,
      currentTag: currentTag ?? this.currentTag,
    );
  }
}
