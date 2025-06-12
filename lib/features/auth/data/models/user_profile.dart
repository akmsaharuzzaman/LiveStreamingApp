class UserResponseData {
  final bool? success;
  final List<Result>? result;
  final String? accessToken;

  const UserResponseData({
    this.success,
    this.result,
    this.accessToken,
  });

  factory UserResponseData.fromJson(Map<String, dynamic> json) {
    return UserResponseData(
      success: json['success'] as bool?,
      result: (json['result'] as List<dynamic>?)
          ?.map((e) => Result.fromJson(e as Map<String, dynamic>))
          .toList(),
      accessToken: json['access_token'] as String?, // <-- FIXED key here
    );
  }

  UserResponseData copyWith({
    bool? success,
    List<Result>? result,
    String? accessToken,
  }) =>
      UserResponseData(
        success: success ?? this.success,
        result: result ?? this.result,
        accessToken: accessToken ?? this.accessToken,
      );

  @override
  String toString() =>
      'UserResponseData(success: $success, result: $result, accessToken: $accessToken)';
}

class Result {
  final String? email;
  final String? password;
  final String? userStateInApp;
  final bool? isreseller;
  final int? resellerCoins;
  final String? resellerWhatsAppnumber;
  final List<dynamic>? resellerHistory;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? birthday;
  final String? country;
  final String? bio;
  final Avatar? avatar;
  final String? countryCode;
  final String? country_dial_code;
  final String? uid;
  final List<String>? countryLanguages;
  final int? credit;
  final int? userPoints;
  final bool? isViewer;
  final ActivityZone? activityZone;
  final String? id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  Result({
    this.email,
    this.password,
    this.userStateInApp,
    this.isreseller,
    this.resellerCoins,
    this.resellerWhatsAppnumber,
    this.resellerHistory,
    this.name,
    this.firstName,
    this.lastName,
    this.gender,
    this.birthday,
    this.country,
    this.bio,
    this.avatar,
    this.countryCode,
    this.country_dial_code,
    this.uid,
    this.countryLanguages,
    this.credit,
    this.userPoints,
    this.isViewer,
    this.activityZone,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        email: json['email'] as String?,
        password: json['password'] as String?,
        userStateInApp: json['user_state_in_app'] as String?,
        isreseller: json['isreseller'] as bool?,
        resellerCoins: json['reseller_coins'] as int?,
        resellerWhatsAppnumber: json['reseller_whatsAppnumber'] as String?,
        resellerHistory: json['reseller_history'] as List<dynamic>?,
        name: json['name'] as String?,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        gender: json['gender'] as String?,
        birthday: json['birthday'] as String?,
        country: json['country'] as String?,
        bio: json['bio'] as String?,
        avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
        countryCode: json['country_code'] as String?,
        country_dial_code: json['country_dial_code'] as String?,
        uid: json['uid'] as String?,
        countryLanguages: (json['country_languages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        credit: json['credit'] as int?,
        userPoints: json['userPoints'] as int?,
        isViewer: json['isViewer'] as bool?,
        activityZone: json['activity_zone'] != null
            ? ActivityZone.fromJson(json['activity_zone'])
            : null,
        id: json['_id'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        v: json['__v'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'user_state_in_app': userStateInApp,
        'isreseller': isreseller,
        'reseller_coins': resellerCoins,
        'reseller_whatsAppnumber': resellerWhatsAppnumber,
        'reseller_history': resellerHistory,
        'name': name,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        'birthday': birthday,
        'country': country,
        'bio': bio,
        'avatar': avatar?.toJson(),
        'country_code': countryCode,
        'country_dial_code': country_dial_code,
        'uid': uid,
        'country_languages': countryLanguages,
        'credit': credit,
        'userPoints': userPoints,
        'isViewer': isViewer,
        'activity_zone': activityZone?.toJson(),
        '_id': id,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        '__v': v,
      };

  Result copyWith({
    String? email,
    String? password,
    String? userStateInApp,
    bool? isreseller,
    int? resellerCoins,
    String? resellerWhatsAppnumber,
    List<dynamic>? resellerHistory,
    String? name,
    String? firstName,
    String? lastName,
    String? gender,
    String? birthday,
    String? country,
    String? bio,
    Avatar? avatar,
    String? countryCode,
    String? country_dial_code,
    String? uid,
    List<String>? countryLanguages,
    int? credit,
    int? userPoints,
    bool? isViewer,
    ActivityZone? activityZone,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) =>
      Result(
        email: email ?? this.email,
        password: password ?? this.password,
        userStateInApp: userStateInApp ?? this.userStateInApp,
        isreseller: isreseller ?? this.isreseller,
        resellerCoins: resellerCoins ?? this.resellerCoins,
        resellerWhatsAppnumber:
            resellerWhatsAppnumber ?? this.resellerWhatsAppnumber,
        resellerHistory: resellerHistory ?? this.resellerHistory,
        name: name ?? this.name,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        gender: gender ?? this.gender,
        birthday: birthday ?? this.birthday,
        country: country ?? this.country,
        bio: bio ?? this.bio,
        avatar: avatar ?? this.avatar,
        countryCode: countryCode ?? this.countryCode,
        country_dial_code: country_dial_code ?? this.country_dial_code,
        uid: uid ?? this.uid,
        countryLanguages: countryLanguages ?? this.countryLanguages,
        credit: credit ?? this.credit,
        userPoints: userPoints ?? this.userPoints,
        isViewer: isViewer ?? this.isViewer,
        activityZone: activityZone ?? this.activityZone,
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        v: v ?? this.v,
      );

  @override
  String toString() {
    return 'Result(email: $email, name: $name, firstName: $firstName, lastName: $lastName, uid: $uid)';
  }
}

class ActivityZone {
  final String? zone;

  ActivityZone({this.zone});

  factory ActivityZone.fromJson(Map<String, dynamic> json) =>
      ActivityZone(zone: json['zone'] as String?);

  Map<String, dynamic> toJson() => {
        'zone': zone,
      };

  ActivityZone copyWith({
    String? zone,
  }) =>
      ActivityZone(
        zone: zone ?? this.zone,
      );

  @override
  String toString() => 'ActivityZone(zone: $zone)';
}

class Avatar {
  final String? name;
  final String? url;

  Avatar({this.name, this.url});

  factory Avatar.fromJson(Map<String, dynamic> json) => Avatar(
        name: json['name'] as String?,
        url: json['url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
      };

  Avatar copyWith({
    String? name,
    String? url,
  }) =>
      Avatar(
        name: name ?? this.name,
        url: url ?? this.url,
      );

  @override
  String toString() => 'Avatar(name: $name, url: $url)';
}
