import 'package:dlstarlive/features/live_audio/data/models/audio_member_model.dart';
import 'package:flutter/material.dart';
import 'chat_model.dart';

class AudioRoomDetails {
  String title;
  int numberOfSeats;
  String roomId;
  int hostGifts;
  int hostBonus;
  AudioMember hostDetails;
  PremiumSeat premiumSeat;
  SeatsData seatsData;
  List<AudioChatModel> messages;
  String createdAt;
  List<String> members;
  List<AudioMember> membersDetails;
  List<dynamic> bannedUsers;
  List<dynamic> mutedUsers;
  List<Ranking> ranking;
  int duration;

  AudioRoomDetails({
    required this.title,
    required this.numberOfSeats,
    required this.roomId,
    required this.hostGifts,
    required this.hostBonus,
    required this.hostDetails,
    required this.premiumSeat,
    required this.seatsData,
    required this.messages,
    required this.createdAt,
    required this.bannedUsers,
    required this.members,
    required this.membersDetails,
    required this.mutedUsers,
    required this.ranking,
    required this.duration,
  });

factory AudioRoomDetails.fromJson(Map<String, dynamic> json) {
    try {
      final title = json['title'] as String?;
      late final int numberOfSeats;
      try {
        numberOfSeats = json['numberOfSeats'] as int? ?? 6;
      } catch (e) {
        throw ArgumentError('Error parsing numberOfSeats: $e');
      }
      late final String roomId;
      try {
        roomId = json['roomId'] as String? ?? '';
      } catch (e) {
        throw ArgumentError('Error parsing roomId: $e');
      }
      late final int hostGifts;
      try {
        hostGifts = json['hostGifts'] as int? ?? 0;
      } catch (e) {
        throw ArgumentError('Error parsing hostGifts: $e');
      }
      late final int hostBonus;
      try {
        hostBonus = json['hostBonus'] as int? ?? 0;
      } catch (e) {
        throw ArgumentError('Error parsing hostBonus: $e');
      }
      late final AudioMember hostDetails;
      try {
        if (json['hostDetails'] != null) {
          hostDetails = AudioMember.fromJson(json['hostDetails'] as Map<String, dynamic>);
        } else {
          hostDetails = AudioMember(name: 'Host', avatar: '', uid: '', id: '', currentLevel: 0, equipedStoreItems: null, totalGiftSent: 0, isMuted: false);
        }
      } catch (e) {
        throw ArgumentError('Error parsing hostDetails: $e');
      }
      late final PremiumSeat premiumSeat;
      try {
        if (json['premiumSeat'] != null) {
          premiumSeat = PremiumSeat.fromJson(json['premiumSeat'] as Map<String, dynamic>);
        } else {
          premiumSeat = PremiumSeat(member: null, available: true);
        }
      } catch (e) {
        throw ArgumentError('Error parsing premiumSeat: $e');
      }
      late final SeatsData seats;
      try {
        if (json['seats'] != null) {
          seats = SeatsData.fromJson(json['seats'] as Map<String, dynamic>);
        } else {
          seats = SeatsData(seats: {});
        }
      } catch (e) {
        throw ArgumentError('Error parsing seats: $e');
      }
      final messages = json['messages'] != null && (json['messages'] as List<dynamic>).isNotEmpty
          ? (json['messages'] as List<dynamic>).map((e) => AudioChatModel.fromJson(e as Map<String, dynamic>)).toList()
          : <AudioChatModel>[];
      late final String createdAt;
      try {
        createdAt = json['createdAt'] as String? ?? DateTime.now().toIso8601String();
      } catch (e) {
        throw ArgumentError('Error parsing createdAt: $e');
      }
      late final List<dynamic> bannedUsers;
      try {
        bannedUsers = json['bannedUsers'] as List<dynamic>? ?? [];
      } catch (e) {
        throw ArgumentError('Error parsing bannedUsers: $e');
      }
      late final List<String> members;
      try {
        if (json['members'] != null) {
          members = List<String>.from(json['members'].map((dynamic e) => e as String));
        } else {
          members = [];
        }
      } catch (e) {
        throw ArgumentError('Error parsing members: $e');
      }
      late final List<AudioMember> membersDetails;
      try {
        if (json['membersDetails'] != null) {
          membersDetails = List<AudioMember>.from(json['membersDetails'].map((dynamic e) => AudioMember.fromJson(e as Map<String, dynamic>)));
        } else {
          membersDetails = [];
        }
      } catch (e) {
        throw ArgumentError('Error parsing membersDetails: $e');
      }
      late final List<dynamic> mutedUsers;
      try {
        mutedUsers = json['mutedUsers'] as List<dynamic>? ?? [];
      } catch (e) {
        throw ArgumentError('Error parsing mutedUsers: $e');
      }
      late final List<Ranking> ranking;
      try {
        if (json['ranking'] != null) {
          ranking = List<Ranking>.from(json['ranking'].map((dynamic e) => Ranking.fromJson(e as Map<String, dynamic>)));
        } else {
          ranking = [];
        }
      } catch (e) {
        throw ArgumentError('Error parsing ranking: $e');
      }
      late final int duration;
      try {
        duration = json['duration'] as int? ?? 0;
      } catch (e) {
        throw ArgumentError('Error parsing duration: $e');
      }

      return AudioRoomDetails(
        title: title ?? 'Audio Room',
        numberOfSeats: numberOfSeats,
        roomId: roomId,
        hostGifts: hostGifts,
        hostBonus: hostBonus,
        hostDetails: hostDetails,
        premiumSeat: premiumSeat,
        seatsData: seats,
        messages: messages,
        createdAt: createdAt,
        bannedUsers: bannedUsers,
        members: members,
        membersDetails: membersDetails,
        mutedUsers: mutedUsers,
        ranking: ranking,
        duration: duration,
      );
    } catch (e) {
      debugPrint('\n \x1B[36m [AUDIO_ROOM] : MODEL - JSON data: $json \x1B[0m');
      debugPrint('\n \x1B[36m [AUDIO_ROOM] : MODEL - ❌ Error parsing AudioRoomDetails: $e \x1B[0m');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['title'] = title;
    json['numberOfSeats'] = numberOfSeats;
    json['roomId'] = roomId;
    json['hostGifts'] = hostGifts;
    json['hostBonus'] = hostBonus;
    json['hostDetails'] = hostDetails.toJson();
    json['premiumSeat'] = premiumSeat.toJson();
    json['seats'] = seatsData.toJson();
    json['messages'] = messages;
    json['createdAt'] = createdAt;
    json['bannedUsers'] = bannedUsers;
    json['members'] = members;
    json['membersDetails'] = membersDetails;
    json['mutedUsers'] = mutedUsers;
    json['ranking'] = ranking.map((e) => e.toJson()).toList();
    json['duration'] = duration;
    return json;
  }
}

class SeatsData {
  Map<String, SeatInfo>? seats;

  SeatsData({this.seats});

  SeatsData.fromJson(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      seats = {};
      json.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          seats![key] = SeatInfo.fromJson(value);
        }
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    seats?.forEach((key, value) {
      json[key] = value.toJson();
    });
    return json;
  }
}

class SeatInfo {
  AudioMember? member;
  bool? available;

  SeatInfo({this.member, this.available});

  SeatInfo.fromJson(Map<String, dynamic> json) {
    member = (json['member'] as Map<String, dynamic>?) != null && (json['member'] as Map<String, dynamic>).isNotEmpty
        ? AudioMember.fromJson(json['member'] as Map<String, dynamic>)
        : null;
    available = json['available'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['member'] = member?.toJson() ?? {};
    json['available'] = available;
    return json;
  }
}

class PremiumSeat {
  AudioMember? member;
  bool? available;

  PremiumSeat({this.member, this.available});

  PremiumSeat.fromJson(Map<String, dynamic> json) {
    member = (json['member'] as Map<String, dynamic>?) != null && (json['member'] as Map<String, dynamic>).isNotEmpty
        ? AudioMember.fromJson(json['member'] as Map<String, dynamic>)
        : null;
    available = json['available'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['member'] = member?.toJson() ?? {};
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
    equipedStoreItems = json['equipedStoreItems'] as Map<String, dynamic>?;
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
