class AudioChatModel {
  final String name;
  final String avatar;
  final String uid;
  final String id;
  final int? currentLevel;
  final String text;
  final Map<String, dynamic>? equipedStoreItems;

  AudioChatModel({
    required this.name,
    required this.avatar,
    required this.uid,
    required this.id,
    required this.text,
    this.equipedStoreItems,
    this.currentLevel,
  });

  factory AudioChatModel.fromJson(Map<String, dynamic> json) {
    return AudioChatModel(
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      uid: json['uid'] as String,
      id: json['_id'] as String,
      text: json['text'] as String,
      equipedStoreItems:
          (json['equipedStoreItems'] ?? json['equippedStoreItems'])
              as Map<String, dynamic>?,
      currentLevel: json['currentLevel'] as int?,
    );
  }
}


// fvm flutter run | grep '\[AUDIO_ROOM\]'