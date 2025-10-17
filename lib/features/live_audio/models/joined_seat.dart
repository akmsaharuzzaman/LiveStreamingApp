import 'member.dart';

class JoinedSeatModel {
  String? seatKey;
  AudioMember? member;

  JoinedSeatModel({this.seatKey, this.member});

  JoinedSeatModel.fromJson(Map<String, dynamic> json) {
    seatKey = json['seatKey'] as String?;
    member = (json['member'] as Map<String, dynamic>?) != null
        ? AudioMember.fromJson(json['member'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['seatKey'] = seatKey;
    json['member'] = member?.toJson();
    return json;
  }
}
