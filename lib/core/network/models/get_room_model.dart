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
  final HostDetails? hostDetails;
  final List<String> members;
  final List<String> bannedUsers;
  final List<String> brodcasters;
  final List<String> callRequests;
  final String title;

  GetRoomModel({
    required this.hostId,
    required this.roomId,
    this.hostDetails,
    required this.members,
    required this.bannedUsers,
    required this.brodcasters,
    required this.callRequests,
    required this.title,
  });

  factory GetRoomModel.fromJson(Map<String, dynamic> json) {
    return GetRoomModel(
      hostId: json['hostId'] as String,
      roomId: json['roomId'] as String,
      hostDetails: json['hostDetails'] != null
          ? HostDetails.fromJson(json['hostDetails'])
          : null,
      members: List<String>.from(json['members'] ?? []),
      bannedUsers: List<String>.from(json['bannedUsers'] ?? []),
      brodcasters: List<String>.from(json['brodcasters'] ?? []),
      callRequests: List<String>.from(json['callRequests'] ?? []),
      title: json['title'] as String,
    );
  }
  static List<GetRoomModel> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => GetRoomModel.fromJson(json)).toList();
  }
}