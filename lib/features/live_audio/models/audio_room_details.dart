import 'audio_host_details.dart';
import 'seat_model.dart';

class AudioRoomDetails {
  String? roomId;
  int? hostGifts;
  int? hostBonus;
  AudioHostDetails? hostDetails;
  PremiumSeat? premiumSeat;
  SeatModel? seats;
  List<dynamic>? messages;
  String? createdAt;
  List<dynamic>? bannedUsers;
  List<String>? members;
  List<dynamic>? membersDetails;
  List<dynamic>? mutedUsers;
  List<Ranking>? ranking;
  int? duration;

  AudioRoomDetails({
    this.roomId,
    this.hostGifts,
    this.hostBonus,
    this.hostDetails,
    this.premiumSeat,
    this.seats,
    this.messages,
    this.createdAt,
    this.bannedUsers,
    this.members,
    this.membersDetails,
    this.mutedUsers,
    this.ranking,
    this.duration,
  });

  AudioRoomDetails.fromJson(Map<String, dynamic> json) {
    roomId = json['roomId'] as String?;
    hostGifts = json['hostGifts'] as int?;
    hostBonus = json['hostBonus'] as int?;
    hostDetails = (json['hostDetails'] as Map<String,dynamic>?) != null ? AudioHostDetails.fromJson(json['hostDetails'] as Map<String,dynamic>) : null;
    premiumSeat = (json['premiumSeat'] as Map<String,dynamic>?) != null ? PremiumSeat.fromJson(json['premiumSeat'] as Map<String,dynamic>) : null;
    seats = (json['seats'] as Map<String,dynamic>?) != null ? SeatModel.fromJson(json['seats'] as Map<String,dynamic>) : null;
    messages = json['messages'] as List?;
    createdAt = json['createdAt'] as String?;
    bannedUsers = json['bannedUsers'] as List?;
    members = (json['members'] as List?)?.map((dynamic e) => e as String).toList();
    membersDetails = json['membersDetails'] as List?;
    mutedUsers = json['mutedUsers'] as List?;
    ranking = (json['ranking'] as List?)?.map((dynamic e) => Ranking.fromJson(e as Map<String,dynamic>)).toList();
    duration = json['duration'] as int?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['roomId'] = roomId;
    json['hostGifts'] = hostGifts;
    json['hostBonus'] = hostBonus;
    json['hostDetails'] = hostDetails?.toJson();
    json['premiumSeat'] = premiumSeat?.toJson();
    json['seats'] = seats?.toJson();
    json['messages'] = messages;
    json['createdAt'] = createdAt;
    json['bannedUsers'] = bannedUsers;
    json['members'] = members;
    json['membersDetails'] = membersDetails;
    json['mutedUsers'] = mutedUsers;
    json['ranking'] = ranking?.map((e) => e.toJson()).toList();
    json['duration'] = duration;
    return json;
  }
}


class PremiumSeat {
  AudioHostDetails? member;
  bool? available;

  PremiumSeat({
    this.member,
    this.available,
  });

  PremiumSeat.fromJson(Map<String, dynamic> json) {
    member = (json['member'] as Map<String,dynamic>?) != null ? AudioHostDetails.fromJson(json['member'] as Map<String,dynamic>) : null;
    available = json['available'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['member'] = member?.toJson();
    json['available'] = available;
    return json;
  }
}

class Ranking {
  String? name;
  String? avatar;
  String? uid;
  String? id;
  String? currentBackground;
  String? currentTag;
  int? currentLevel;
  Map<String, dynamic>? equipedStoreItems;
  int? totalGiftSent;
  bool? isMuted;

  Ranking({
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

  Ranking.fromJson(Map<String, dynamic> json) {
    name = json['name'] as String?;
    avatar = json['avatar'] as String?;
    uid = json['uid'] as String?;
    id = json['_id'] as String?;
    currentBackground = json['currentBackground'] as String?;
    currentTag = json['currentTag'] as String?;
    currentLevel = json['currentLevel'] as int?;
    equipedStoreItems = json['equipedStoreItems'] as Map<String,dynamic>?;
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
    json['equipedStoreItems'] = equipedStoreItems;
    json['totalGiftSent'] = totalGiftSent;
    json['isMuted'] = isMuted;
    return json;
  }
}