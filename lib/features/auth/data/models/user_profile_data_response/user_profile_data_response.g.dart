// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_data_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileDataResponse _$UserProfileDataResponseFromJson(
        Map<String, dynamic> json) =>
    UserProfileDataResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      result: json['result'] == null
          ? null
          : Result.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserProfileDataResponseToJson(
        UserProfileDataResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'result': instance.result,
    };
