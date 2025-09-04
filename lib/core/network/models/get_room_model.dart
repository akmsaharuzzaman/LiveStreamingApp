class HostDetails {
  final String id;
  final String avatar;
  final String name;
  final String uid;

  HostDetails({
    required this.id,
    required this.avatar,
    required this.name,
    required this.uid,
  });

  factory HostDetails.fromJson(Map<String, dynamic> json) {
    return HostDetails(
      id: json['_id'] as String,
      avatar: json['avatar'] as String,
      name: json['name'] as String,
      uid: json['uid'] as String,
    );
  }
}

class GetRoomModel {
  final String hostId;
  final String roomId;
  final String roomType;
  final List<dynamic> messages;
  final HostDetails? hostDetails;
  final List<HostDetails> membersDetails;
  final List<String> members;
  final List<String> bannedUsers;
  final List<String> brodcasters;
  final List<HostDetails> broadcastersDetails;
  final List<HostDetails> callRequests;
  final HostDetails? adminDetails;
  final String title;
  final int hostCoins;

  GetRoomModel({
    required this.hostId,
    required this.roomId,
    required this.roomType,
    this.hostDetails,
    this.messages = const [],
    this.membersDetails = const [],
    this.adminDetails,
    required this.members,
    required this.bannedUsers,
    required this.brodcasters,
    required this.broadcastersDetails,
    required this.callRequests,
    required this.title,
    this.hostCoins = 0,
  });

  factory GetRoomModel.fromJson(Map<String, dynamic> json) {
    return GetRoomModel(
      hostId: json['hostId'] as String,
      roomId: json['roomId'] as String,
      roomType: json['roomType'] as String,
      hostDetails: json['hostDetails'] != null
          ? HostDetails.fromJson(json['hostDetails'])
          : null,
      messages: List<dynamic>.from(json['messages'] ?? []),
      membersDetails: (json['membersDetails'] as List<dynamic>? ?? [])
          .map((e) => HostDetails.fromJson(e))
          .toList(),
      members: List<String>.from(json['members'] ?? []),
      bannedUsers: List<String>.from(json['bannedUsers'] ?? []),
      brodcasters: List<String>.from(json['brodcasters'] ?? []),
      broadcastersDetails: (json['broadcastersDetails'] as List<dynamic>? ?? [])
          .map((e) => HostDetails.fromJson(e))
          .toList(),
      callRequests: (json['callRequests'] as List<dynamic>? ?? [])
          .map((e) => HostDetails.fromJson(e))
          .toList(),
      adminDetails: json['adminDetails'] != null
          ? HostDetails.fromJson(json['adminDetails'])
          : null,
      title: json['title'] as String,
      hostCoins: json['hostCoins'] as int? ?? 0,
    );
  }

  static List<GetRoomModel> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => GetRoomModel.fromJson(json)).toList();
  }
}
