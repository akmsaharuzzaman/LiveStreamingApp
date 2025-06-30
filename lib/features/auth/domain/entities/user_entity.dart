class UserEntity {
  final String id;
  final String email;
  final String name;
  final String firstName;
  final String lastName;
  final String uid;
  final String bio;
  final DateTime? birthday;
  final String country;
  final String countryCode;
  final String countryDialCode;
  final String gender;
  final int credit;
  final int userPoints;
  final bool isViewer;
  final bool isReseller;
  final int resellerCoins;
  final String userStateInApp;
  final UserAvatar? avatar;
  final UserStats? stats;
  final ActivityZone activityZone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.uid,
    required this.bio,
    this.birthday,
    required this.country,
    required this.countryCode,
    required this.countryDialCode,
    required this.gender,
    required this.credit,
    required this.userPoints,
    required this.isViewer,
    required this.isReseller,
    required this.resellerCoins,
    required this.userStateInApp,
    this.avatar,
    this.stats,
    required this.activityZone,
    required this.createdAt,
    required this.updatedAt,
  });
}

class UserAvatar {
  final String name;
  final String url;

  const UserAvatar({required this.name, required this.url});
}

class UserStats {
  final String id;
  final String userId;
  final int stars;
  final int diamonds;
  final int levels;
  final List<String> gifts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserStats({
    required this.id,
    required this.userId,
    required this.stars,
    required this.diamonds,
    required this.levels,
    required this.gifts,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ActivityZone {
  final String zone;

  const ActivityZone({required this.zone});
}
