enum LiveType { multiLive, live, pk, audio }
class LiveStream {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelId;
  final String userId;
  final String userName;
  final String userProfilePic;
  final DateTime startTime;
  final bool isLive;
  final int viewerCount;
  final List<String> tags;
  final LiveType liveType;
  final String? countryCode;

  LiveStream({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelId,
    required this.userId,
    required this.userName,
    required this.userProfilePic,
    required this.startTime,
    required this.isLive,
    required this.viewerCount,
    required this.tags,
    required this.liveType,
    this.countryCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'channelId': channelId,
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'startTime': DateTime.now().isBefore(startTime)
         ,
      'isLive': isLive,
      'viewerCount': viewerCount,
      'tags': tags,
      'liveType': liveType.index,
      'countryCode': countryCode,
    };
  }

  factory LiveStream.fromMap(Map<String, dynamic> map) {
    return LiveStream(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      channelId: map['channelId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userProfilePic: map['userProfilePic'] ?? '',
      startTime: (map['startTime'] ).toDate(),
      isLive: map['isLive'] ?? false,
      viewerCount: map['viewerCount'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      liveType: LiveType.values[map['liveType'] ?? 0],
      countryCode: map['countryCode'] as String?,
    );
  }

  LiveStream copyWith({
    String? id,
    String? title,
    String? thumbnailUrl,
    String? channelId,
    String? userId,
    String? userName,
    String? userProfilePic,
    DateTime? startTime,
    bool? isLive,
    int? viewerCount,
    List<String>? tags,
    LiveType? liveType,
    String? countryCode,
  }) {
    return LiveStream(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      channelId: channelId ?? this.channelId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      startTime: startTime ?? this.startTime,
      isLive: isLive ?? this.isLive,
      viewerCount: viewerCount ?? this.viewerCount,
      tags: tags ?? this.tags,
      liveType: liveType ?? this.liveType,
      countryCode: countryCode ?? this.countryCode,
    );
  }
}
