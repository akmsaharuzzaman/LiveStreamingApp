// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GoogleResponseModel _$GoogleResponseModelFromJson(Map<String, dynamic> json) =>
    GoogleResponseModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      googleId: json['googleId'] as String?,
      emailVerifiedAt: json['emailVerifiedAt'] == null
          ? null
          : DateTime.parse(json['emailVerifiedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$GoogleResponseModelToJson(
  GoogleResponseModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'phone': instance.phone,
  'profilePictureUrl': instance.profilePictureUrl,
  'googleId': instance.googleId,
  'emailVerifiedAt': instance.emailVerifiedAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
