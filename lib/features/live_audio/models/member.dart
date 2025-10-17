class AudioMember {
  String? name;
  String? avatar;
  String? uid;
  String? id;
  String? currentBackground;
  String? currentTag;
  int? currentLevel;
  EquipedStoreItems? equipedStoreItems;
  int? totalGiftSent;
  bool? isMuted;

  AudioMember({
    this.name,
    this.avatar,
    this.uid,
    this.id,
    this.currentBackground,
    this.currentTag,
    this.currentLevel,
    this.equipedStoreItems,
    this.totalGiftSent,
    this.isMuted,
  });

  AudioMember.fromJson(Map<String, dynamic> json) {
    name = json['name'] as String?;
    avatar = json['avatar'] as String?;
    uid = json['uid'] as String?;
    id = json['_id'] as String?;
    currentBackground = json['currentBackground'] as String?;
    currentTag = json['currentTag'] as String?;
    currentLevel = json['currentLevel'] as int?;
    equipedStoreItems = (json['equipedStoreItems'] as Map<String, dynamic>?) != null
        ? EquipedStoreItems.fromJson(json['equipedStoreItems'] as Map<String, dynamic>)
        : null;
    totalGiftSent = json['totalGiftSent'] as int?;
    isMuted = json['isMuted'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['name'] = name;
    json['avatar'] = avatar;
    json['uid'] = uid;
    json['_id'] = id;
    json['currentBackground'] = currentBackground;
    json['currentTag'] = currentTag;
    json['currentLevel'] = currentLevel;
    json['equipedStoreItems'] = equipedStoreItems?.toJson();
    json['totalGiftSent'] = totalGiftSent;
    json['isMuted'] = isMuted;
    return json;
  }
}

class EquipedStoreItems {
  EquipedStoreItems();

  EquipedStoreItems.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    return json;
  }
}