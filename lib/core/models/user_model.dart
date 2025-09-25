import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'activity_zone_model.dart';

part 'user_model.g.dart';

/// User stats model
@JsonSerializable()
class UserStatsModel extends Equatable {
  @JsonKey(name: '_id')
  final String id;
  final String userId;
  final int stars;
  final int diamonds;
  final int coins;
  final int levels;
  final List<dynamic> gifts;
  final DateTime createdAt;
  final DateTime updatedAt;
  @JsonKey(name: '__v')
  final int version;

  const UserStatsModel({
    required this.id,
    required this.userId,
    required this.stars,
    required this.diamonds,
    required this.coins,
    required this.levels,
    required this.gifts,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) => UserStatsModel(
    id: json['_id'] as String,
    userId: json['userId'] as String,
    stars: (json['stars'] as num? ?? 0).toInt(),
    diamonds: (json['diamonds'] as num? ?? 0).toInt(),
    coins: (json['coins'] as num? ?? 0).toInt(),
    levels: (json['levels'] as num? ?? 0).toInt(),
    gifts: json['gifts'] as List<dynamic>? ?? [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    version: (json['__v'] as num? ?? 0).toInt(),
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'userId': userId,
    'stars': stars,
    'diamonds': diamonds,
    'coins': coins,
    'levels': levels,
    'gifts': gifts,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    '__v': version,
  };

  @override
  List<Object?> get props => [
    id,
    userId,
    stars,
    diamonds,
    coins,
    levels,
    gifts,
    createdAt,
    updatedAt,
    version,
  ];
}

/// User relationship model
@JsonSerializable()
class UserRelationshipModel extends Equatable {
  final bool friendship;
  final bool myFollower;
  final bool myFollowing;

  const UserRelationshipModel({
    required this.friendship,
    required this.myFollower,
    required this.myFollowing,
  });

  factory UserRelationshipModel.fromJson(Map<String, dynamic> json) =>
      UserRelationshipModel(
        friendship: json['friendship'] as bool,
        myFollower: json['myFollower'] as bool,
        myFollowing: json['myFollowing'] as bool,
      );

  Map<String, dynamic> toJson() => {
    'friendship': friendship,
    'myFollower': myFollower,
    'myFollowing': myFollowing,
  };

  UserRelationshipModel copyWith({
    bool? friendship,
    bool? myFollower,
    bool? myFollowing,
  }) {
    return UserRelationshipModel(
      friendship: friendship ?? this.friendship,
      myFollower: myFollower ?? this.myFollower,
      myFollowing: myFollowing ?? this.myFollowing,
    );
  }

  @override
  List<Object?> get props => [friendship, myFollower, myFollowing];
}

/// Complete user model for the backend response
@JsonSerializable()
class UserModel extends Equatable {
  @JsonKey(name: '_id')
  final String id;
  final String email;
  final String name;
  final int? level;
  final String? firstName;
  final String? lastName;
  final String? uid;
  final String? avatar;
  final String? coverPicture;
  final String userStateInApp;
  final List<dynamic> userPermissions;
  final bool isViewer;
  final String userRole;
  final ActivityZoneModel activityZone;
  final DateTime createdAt;
  final DateTime updatedAt;
  @JsonKey(name: '__v')
  final int version;

  // Profile completion fields
  final List<String> countryLanguages;
  final String? gender;
  final DateTime? birthday;

  // Optional Google-specific fields
  final String? googleId;
  final String? profilePictureUrl;

  // Optional nested objects
  final UserStatsModel? stats;
  final UserRelationshipModel? relationship;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.level,
    this.firstName,
    this.lastName,
    this.uid,
    this.avatar,
    this.coverPicture,
    required this.userStateInApp,
    required this.userPermissions,
    required this.isViewer,
    required this.countryLanguages,
    required this.userRole,
    required this.activityZone,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.gender,
    this.birthday,
    this.googleId,
    this.profilePictureUrl,
    this.stats,
    this.relationship,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Create a UserModel from Google sign-in data (fallback)
  factory UserModel.fromGoogle({
    required String email,
    required String name,
    String? firstName,
    String? lastName,
    String? googleId,
    String? profilePictureUrl,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: googleId ?? email.hashCode.toString(),
      email: email,
      name: name,
      firstName: firstName,
      lastName: lastName,
      uid: googleId,
      avatar: profilePictureUrl,
      coverPicture: null, // Will be set later if user uploads a cover picture
      userStateInApp: 'Online',
      userPermissions: const [],
      isViewer: false,
      userRole: 'user',
      activityZone: const ActivityZoneModel(zone: 'safe'),
      createdAt: now,
      updatedAt: now,
      version: 0,
      countryLanguages: const [], // Will be filled during profile completion
      gender: null, // Will be filled during profile completion
      birthday: null, // Will be filled during profile completion
      googleId: googleId,
      profilePictureUrl: profilePictureUrl,
      stats: null,
      relationship: null,
    );
  }

  /// Copy with method for updating fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? firstName,
    String? lastName,
    String? uid,
    String? avatar,
    String? coverPicture,
    String? userStateInApp,
    List<dynamic>? userPermissions,
    bool? isViewer,
    List<String>? countryLanguages,
    String? userRole,
    ActivityZoneModel? activityZone,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    String? gender,
    DateTime? birthday,
    String? googleId,
    String? profilePictureUrl,
    UserStatsModel? stats,
    UserRelationshipModel? relationship,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      uid: uid ?? this.uid,
      avatar: avatar ?? this.avatar,
      coverPicture: coverPicture ?? this.coverPicture,
      userStateInApp: userStateInApp ?? this.userStateInApp,
      userPermissions: userPermissions ?? this.userPermissions,
      isViewer: isViewer ?? this.isViewer,
      countryLanguages: countryLanguages ?? this.countryLanguages,
      userRole: userRole ?? this.userRole,
      activityZone: activityZone ?? this.activityZone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      googleId: googleId ?? this.googleId,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      stats: stats ?? this.stats,
      relationship: relationship ?? this.relationship,
    );
  }

  /// Check if profile is complete (has country, gender, and birthday)
  bool get isProfileComplete {
    return countryLanguages.isNotEmpty && gender != null && birthday != null;
  }

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    firstName,
    lastName,
    uid,
    avatar,
    coverPicture,
    userStateInApp,
    userPermissions,
    isViewer,
    countryLanguages,
    userRole,
    activityZone,
    createdAt,
    updatedAt,
    version,
    gender,
    birthday,
    googleId,
    profilePictureUrl,
    stats,
    relationship,
  ];
}
