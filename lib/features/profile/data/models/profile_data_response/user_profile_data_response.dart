import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'result.dart';

part 'user_profile_data_response.g.dart';

@JsonSerializable()
class UserProfileDataResponse extends Equatable {
  final bool? success;
  final String? message;
  final Result? result;

  const UserProfileDataResponse({this.success, this.message, this.result});

  factory UserProfileDataResponse.fromJson(Map<String, dynamic> json) {
    return _$UserProfileDataResponseFromJson(json);
  }

  Map<String, dynamic> toJson() => _$UserProfileDataResponseToJson(this);

  UserProfileDataResponse copyWith({
    bool? success,
    String? message,
    Result? result,
  }) {
    return UserProfileDataResponse(
      success: success ?? this.success,
      message: message ?? this.message,
      result: result ?? this.result,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [success, message, result];
}
