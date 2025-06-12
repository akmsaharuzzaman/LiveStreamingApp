import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'activity_zone.dart';
import 'avatar.dart';

part 'result.g.dart';

@JsonSerializable()
class Result extends Equatable {
  @JsonKey(name: 'activity_zone')
  final ActivityZone? activityZone;

  @JsonKey(name: '_id')
  final String? id;

  final String? email;
  final String? password;

  @JsonKey(name: 'user_state_in_app')
  final String? userStateInApp;

  final bool? isreseller;

  @JsonKey(name: 'reseller_coins')
  final int? resellerCoins;

  @JsonKey(name: 'reseller_whatsAppnumber')
  final String? resellerWhatsAppnumber;

  @JsonKey(name: 'reseller_history')
  final List<dynamic>? resellerHistory;

  final String? name;

  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  @JsonKey(name: 'bio')
  final String? bio;

  @JsonKey(name: 'birthday')
  final String? birthday;

  @JsonKey(name: 'country')
  final String? country;

  @JsonKey(name: 'avatar')
  final Avatar? avatar;

  @JsonKey(name: 'countryCode')
  final String? countryCode;

  @JsonKey(name: 'country_dial_code')
  final String? countryDialCode;
  @JsonKey(name: 'gender')
  final String? gender;

  @JsonKey(name: 'uid')
  final String? uid;

  @JsonKey(name: 'country_languages')
  final List<dynamic>? countryLanguages;

  final int? credit;
  final int? userPoints;
  final bool? isViewer;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  @JsonKey(name: '__v')
  final int? v;

  const Result({
    this.activityZone,
    this.id,
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
    this.bio,
    this.birthday,
    this.country,
    this.avatar,
    this.countryCode,
    this.countryDialCode,
    this.uid,
    this.gender,
    this.countryLanguages,
    this.credit,
    this.userPoints,
    this.isViewer,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Result.fromJson(Map<String, dynamic> json) => _$ResultFromJson(json);

  Map<String, dynamic> toJson() => _$ResultToJson(this);

  Result copyWith({
    ActivityZone? activityZone,
    String? id,
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
    String? bio,
    String? birthday,
    String? country,
    Avatar? avatar,
    String? countryCode,
    String? countryDialCode,
    String? gender,
    String? uid,
    List<dynamic>? countryLanguages,
    int? credit,
    int? userPoints,
    bool? isViewer,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) {
    return Result(
      activityZone: activityZone ?? this.activityZone,
      id: id ?? this.id,
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
      bio: bio ?? this.bio,
      birthday: birthday ?? this.birthday,
      country: country ?? this.country,
      avatar: avatar ?? this.avatar,
      countryCode: countryCode ?? this.countryCode,
      countryDialCode: countryDialCode ?? this.countryDialCode,
      uid: uid ?? this.uid,
      gender: gender ?? this.gender,
      countryLanguages: countryLanguages ?? this.countryLanguages,
      credit: credit ?? this.credit,
      userPoints: userPoints ?? this.userPoints,
      isViewer: isViewer ?? this.isViewer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }

  @override
  List<Object?> get props => [
        activityZone,
        id,
        email,
        password,
        userStateInApp,
        isreseller,
        resellerCoins,
        resellerWhatsAppnumber,
        resellerHistory,
        name,
        firstName,
        lastName,
        bio,
        gender,
        birthday,
        country,
        avatar,
        countryCode,
        countryDialCode,
        uid,
        countryLanguages,
        credit,
        userPoints,
        isViewer,
        createdAt,
        updatedAt,
        v,
      ];
}
