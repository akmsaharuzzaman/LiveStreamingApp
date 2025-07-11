import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_response_model.g.dart';

/// Response model for authentication API calls
@JsonSerializable()
class AuthResponseModel extends Equatable {
  final bool success;
  final List<UserModel> result;
  @JsonKey(name: 'access_token')
  final String accessToken;

  const AuthResponseModel({
    required this.success,
    required this.result,
    required this.accessToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);

  /// Get the first user from result array
  UserModel? get user => result.isNotEmpty ? result.first : null;

  @override
  List<Object?> get props => [success, result, accessToken];
}
