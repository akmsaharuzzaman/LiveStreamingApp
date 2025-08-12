class ChatModel {
  final String name;
  final String avatar;
  final String uid;
  final String id;
  final String text;

  ChatModel({
    required this.name,
    required this.avatar,
    required this.uid,
    required this.id,
    required this.text,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      uid: json['uid'] as String,
      id: json['_id'] as String,
      text: json['text'] as String,
    );
  }
}