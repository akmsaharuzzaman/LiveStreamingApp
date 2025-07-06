/// Model for room host details
class RoomHostDetails {
  final String id;
  final String name;
  final String uid;
  final String country;

  const RoomHostDetails({
    required this.id,
    required this.name,
    required this.uid,
    required this.country,
  });

  factory RoomHostDetails.fromJson(Map<String, dynamic> json) {
    return RoomHostDetails(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      uid: json['uid'] ?? '',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'uid': uid, 'country': country};
  }

  @override
  String toString() {
    return 'RoomHostDetails(id: $id, name: $name, uid: $uid, country: $country)';
  }
}

/// Model for individual room data
class RoomData {
  final String hostId;
  final RoomHostDetails hostDetails;
  final List<String> members;
  final List<String> bannedUsers;

  const RoomData({
    required this.hostId,
    required this.hostDetails,
    required this.members,
    required this.bannedUsers,
  });

  factory RoomData.fromJson(Map<String, dynamic> json) {
    return RoomData(
      hostId: json['hostId'] ?? '',
      hostDetails: RoomHostDetails.fromJson(json['hostDetails'] ?? {}),
      members: List<String>.from(json['members'] ?? []),
      bannedUsers: List<String>.from(json['bannedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hostId': hostId,
      'hostDetails': hostDetails.toJson(),
      'members': members,
      'bannedUsers': bannedUsers,
    };
  }

  /// Get the number of members in the room
  int get memberCount => members.length;

  /// Check if a user is banned
  bool isUserBanned(String userId) => bannedUsers.contains(userId);

  /// Check if a user is a member
  bool isUserMember(String userId) => members.contains(userId);

  /// Check if a user is the host
  bool isUserHost(String userId) => hostId == userId;

  @override
  String toString() {
    return 'RoomData(hostId: $hostId, hostDetails: $hostDetails, members: $members, bannedUsers: $bannedUsers)';
  }
}

/// Model for the complete room list response
class RoomListResponse {
  final Map<String, RoomData> rooms;

  const RoomListResponse({required this.rooms});

  factory RoomListResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, RoomData> roomsMap = {};

    json.forEach((roomId, roomDataJson) {
      if (roomDataJson is Map<String, dynamic>) {
        roomsMap[roomId] = RoomData.fromJson(roomDataJson);
      }
    });

    return RoomListResponse(rooms: roomsMap);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    rooms.forEach((roomId, roomData) {
      json[roomId] = roomData.toJson();
    });
    return json;
  }

  /// Get all room IDs
  List<String> get roomIds => rooms.keys.toList();

  /// Get all room data
  List<RoomData> get roomDataList => rooms.values.toList();

  /// Get room data by ID
  RoomData? getRoomById(String roomId) => rooms[roomId];

  /// Check if room exists
  bool hasRoom(String roomId) => rooms.containsKey(roomId);

  /// Get total number of rooms
  int get roomCount => rooms.length;

  /// Get rooms where user is a member
  Map<String, RoomData> getRoomsForUser(String userId) {
    final Map<String, RoomData> userRooms = {};

    rooms.forEach((roomId, roomData) {
      if (roomData.isUserMember(userId) || roomData.isUserHost(userId)) {
        userRooms[roomId] = roomData;
      }
    });

    return userRooms;
  }

  @override
  String toString() {
    return 'RoomListResponse(rooms: $rooms)';
  }
}
