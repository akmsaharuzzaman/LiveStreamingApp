class BroadcasterModel {
  final String name;
  final String avatar;
  final String uid;
  final String id;

  BroadcasterModel({
    required this.name,
    required this.avatar,
    required this.uid,
    required this.id,
  });

  factory BroadcasterModel.fromJson(Map<String, dynamic> json) {
    return BroadcasterModel(
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      uid: json['uid'] as String,
      id: json['_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatar': avatar,
      'uid': uid,
      '_id': id,
    };
  }

  static List<BroadcasterModel> fromListJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) => BroadcasterModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}