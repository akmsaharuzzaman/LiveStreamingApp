// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Result _$ResultFromJson(Map<String, dynamic> json) => Result(
      activityZone: json['activity_zone'] == null
          ? null
          : ActivityZone.fromJson(
              json['activity_zone'] as Map<String, dynamic>),
      id: json['_id'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      userStateInApp: json['user_state_in_app'] as String?,
      isreseller: json['isreseller'] as bool?,
      resellerCoins: (json['reseller_coins'] as num?)?.toInt(),
      resellerWhatsAppnumber: json['reseller_whatsAppnumber'] as String?,
      resellerHistory: json['reseller_history'] as List<dynamic>?,
      name: json['name'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      bio: json['bio'] as String?,
      birthday: json['birthday'] as String?,
      country: json['country'] as String?,
      avatar: json['avatar'] == null
          ? null
          : Avatar.fromJson(json['avatar'] as Map<String, dynamic>),
      countryCode: json['countryCode'] as String?,
      countryDialCode: json['country_dial_code'] as String?,
      uid: json['uid'] as String?,
      countryLanguages: json['country_languages'] as List<dynamic>?,
      credit: (json['credit'] as num?)?.toInt(),
      userPoints: (json['userPoints'] as num?)?.toInt(),
      isViewer: json['isViewer'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      v: (json['__v'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ResultToJson(Result instance) => <String, dynamic>{
      'activity_zone': instance.activityZone,
      '_id': instance.id,
      'email': instance.email,
      'password': instance.password,
      'user_state_in_app': instance.userStateInApp,
      'isreseller': instance.isreseller,
      'reseller_coins': instance.resellerCoins,
      'reseller_whatsAppnumber': instance.resellerWhatsAppnumber,
      'reseller_history': instance.resellerHistory,
      'name': instance.name,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'bio': instance.bio,
      'birthday': instance.birthday,
      'country': instance.country,
      'avatar': instance.avatar,
      'countryCode': instance.countryCode,
      'country_dial_code': instance.countryDialCode,
      'uid': instance.uid,
      'country_languages': instance.countryLanguages,
      'credit': instance.credit,
      'userPoints': instance.userPoints,
      'isViewer': instance.isViewer,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      '__v': instance.v,
    };
