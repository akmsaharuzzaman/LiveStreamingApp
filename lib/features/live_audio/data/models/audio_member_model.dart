import 'package:dlstarlive/core/utils/app_utils.dart';

class AudioMember {
  String? name;
  String? avatar;
  String? id;
  int? uid;
  String? currentBackground;
  String? currentTag;
  int? currentLevel;
  EquipedStoreItems? equipedStoreItems;
  int? totalGiftSent;
  int? diamonds;
  bool? isMuted;

  AudioMember({
    this.name,
    this.avatar,
    this.id,
    this.uid,
    this.currentBackground,
    this.currentTag,
    this.currentLevel,
    this.equipedStoreItems,
    this.totalGiftSent,
    this.diamonds,
    this.isMuted,
  });

  AudioMember.fromJson(Map<String, dynamic> json) {
    name = json['name'] as String?;
    avatar = json['avatar'] as String?;
    id = json['_id'] as String?;
    // uid = int.tryParse(json['uid'].substring(0, 10));
    uid = AppUtils.getIntFromUid(json['uid']);
    currentBackground = json['currentBackground'] as String?;
    currentTag = json['currentTag'] as String?;
    currentLevel = json['currentLevel'] as int?;
    equipedStoreItems = (json['equipedStoreItems'] as Map<String, dynamic>?) != null
        ? EquipedStoreItems.fromJson(json['equipedStoreItems'] as Map<String, dynamic>)
        : null;
    totalGiftSent = json['totalGiftSent'] as int?;
    diamonds = json['diamonds'] as int?;
    isMuted = json['isMuted'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['name'] = name;
    json['avatar'] = avatar;
    json['_id'] = id;
    json['uid'] = uid;
    json['currentBackground'] = currentBackground;
    json['currentTag'] = currentTag;
    json['currentLevel'] = currentLevel;
    json['equipedStoreItems'] = equipedStoreItems?.toJson();
    json['totalGiftSent'] = totalGiftSent;
    json['diamonds'] = diamonds;
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
