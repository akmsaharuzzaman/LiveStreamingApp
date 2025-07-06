import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.firstName,
    required super.lastName,
    required super.uid,
    required super.bio,
    super.birthday,
    required super.country,
    required super.countryCode,
    required super.countryDialCode,
    required super.gender,
    required super.credit,
    required super.userPoints,
    required super.isViewer,
    required super.isReseller,
    required super.resellerCoins,
    required super.userStateInApp,
    super.avatar,
    super.stats,
    required super.activityZone,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      uid: json['uid'] ?? '',
      bio: json['bio'] ?? '',
      birthday: json['birthday'] != null
          ? DateTime.parse(json['birthday'])
          : null,
      country: json['country'] ?? '',
      countryCode: json['country_code'] ?? '',
      countryDialCode: json['country_dial_code'] ?? '',
      gender: json['gender'] ?? '',
      credit: json['credit'] ?? 0,
      userPoints: json['userPoints'] ?? 0,
      isViewer: json['isViewer'] ?? false,
      isReseller: json['isreseller'] ?? false,
      resellerCoins: json['reseller_coins'] ?? 0,
      userStateInApp: json['user_state_in_app'] ?? 'Offline',
      avatar: json['avatar'] != null
          ? UserAvatarModel.fromJson(json['avatar'])
          : null,
      stats: json['stats'] != null
          ? UserStatsModel.fromJson(json['stats'])
          : null,
      activityZone: ActivityZoneModel.fromJson(json['activity_zone'] ?? {}),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'uid': uid,
      'bio': bio,
      'birthday': birthday?.toIso8601String(),
      'country': country,
      'country_code': countryCode,
      'country_dial_code': countryDialCode,
      'gender': gender,
      'credit': credit,
      'userPoints': userPoints,
      'isViewer': isViewer,
      'isreseller': isReseller,
      'reseller_coins': resellerCoins,
      'user_state_in_app': userStateInApp,
      'avatar': (avatar as UserAvatarModel?)?.toJson(),
      'stats': (stats as UserStatsModel?)?.toJson(),
      'activity_zone': (activityZone as ActivityZoneModel).toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class UserAvatarModel extends UserAvatar {
  const UserAvatarModel({required super.name, required super.url});

  factory UserAvatarModel.fromJson(Map<String, dynamic> json) {
    return UserAvatarModel(name: json['name'] ?? '', url: json['url'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'url': url};
  }
}

class UserStatsModel extends UserStats {
  const UserStatsModel({
    required super.id,
    required super.userId,
    required super.stars,
    required super.diamonds,
    required super.levels,
    required super.gifts,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      stars: json['stars'] ?? 0,
      diamonds: json['diamonds'] ?? 0,
      levels: json['levels'] ?? 0,
      gifts: List<String>.from(json['gifts'] ?? []),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'stars': stars,
      'diamonds': diamonds,
      'levels': levels,
      'gifts': gifts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ActivityZoneModel extends ActivityZone {
  const ActivityZoneModel({required super.zone});

  factory ActivityZoneModel.fromJson(Map<String, dynamic> json) {
    return ActivityZoneModel(zone: json['zone'] ?? 'safe');
  }

  Map<String, dynamic> toJson() {
    return {'zone': zone};
  }
}
