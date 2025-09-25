// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserStatsModel _$UserStatsModelFromJson(Map<String, dynamic> json) =>
    UserStatsModel(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      stars: (json['stars'] as num).toInt(),
      diamonds: (json['diamonds'] as num).toInt(),
      coins: (json['coins'] as num).toInt(),
      levels: (json['levels'] as num).toInt(),
      gifts: json['gifts'] as List<dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: (json['__v'] as num).toInt(),
    );

Map<String, dynamic> _$UserStatsModelToJson(UserStatsModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'userId': instance.userId,
      'stars': instance.stars,
      'diamonds': instance.diamonds,
      'coins': instance.coins,
      'levels': instance.levels,
      'gifts': instance.gifts,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      '__v': instance.version,
    };

UserRelationshipModel _$UserRelationshipModelFromJson(
  Map<String, dynamic> json,
) => UserRelationshipModel(
  friendship: json['friendship'] as bool,
  myFollower: json['myFollower'] as bool,
  myFollowing: json['myFollowing'] as bool,
);

Map<String, dynamic> _$UserRelationshipModelToJson(
  UserRelationshipModel instance,
) => <String, dynamic>{
  'friendship': instance.friendship,
  'myFollower': instance.myFollower,
  'myFollowing': instance.myFollowing,
};

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['_id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  level: (json['level'] as num?)?.toInt(),
  currentLevelBackground: json['currentLevelBackground'] as String?,
  currentLevelTag: json['currentLevelTag'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  uid: json['uid'] as String?,
  avatar: json['avatar'] as String?,
  coverPicture: json['coverPicture'] as String?,
  userStateInApp: json['userStateInApp'] as String,
  userPermissions: json['userPermissions'] as List<dynamic>,
  isViewer: json['isViewer'] as bool,
  countryLanguages: (json['countryLanguages'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  userRole: json['userRole'] as String,
  activityZone: ActivityZoneModel.fromJson(
    json['activityZone'] as Map<String, dynamic>,
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  version: (json['__v'] as num).toInt(),
  gender: json['gender'] as String?,
  birthday: json['birthday'] == null
      ? null
      : DateTime.parse(json['birthday'] as String),
  googleId: json['googleId'] as String?,
  profilePictureUrl: json['profilePictureUrl'] as String?,
  stats: json['stats'] == null
      ? null
      : UserStatsModel.fromJson(json['stats'] as Map<String, dynamic>),
  relationship: json['relationship'] == null
      ? null
      : UserRelationshipModel.fromJson(
          json['relationship'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  '_id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'level': instance.level,
  'currentLevelBackground': instance.currentLevelBackground,
  'currentLevelTag': instance.currentLevelTag,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'uid': instance.uid,
  'avatar': instance.avatar,
  'coverPicture': instance.coverPicture,
  'userStateInApp': instance.userStateInApp,
  'userPermissions': instance.userPermissions,
  'isViewer': instance.isViewer,
  'userRole': instance.userRole,
  'activityZone': instance.activityZone,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  '__v': instance.version,
  'countryLanguages': instance.countryLanguages,
  'gender': instance.gender,
  'birthday': instance.birthday?.toIso8601String(),
  'googleId': instance.googleId,
  'profilePictureUrl': instance.profilePictureUrl,
  'stats': instance.stats,
  'relationship': instance.relationship,
};
