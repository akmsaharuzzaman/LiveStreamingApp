import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'google_response_model.g.dart';

/// Core user model that represents the authenticated user
/// This model is used across the entire application
@JsonSerializable()
class GoogleResponseModel extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profilePictureUrl;
  final String? googleId;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoogleResponseModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.profilePictureUrl,
    this.googleId,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to create UserModel from JSON
  factory GoogleResponseModel.fromJson(Map<String, dynamic> json) =>
      _$GoogleResponseModelFromJson(json);

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() => _$GoogleResponseModelToJson(this);

  /// Factory constructor to create UserModel from Google Sign-In data
  factory GoogleResponseModel.fromGoogleSignIn({
    required String id,
    required String email,
    required String displayName,
    String? photoUrl,
    required String googleId,
  }) {
    final nameParts = displayName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final now = DateTime.now();

    return GoogleResponseModel(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      profilePictureUrl: photoUrl,
      googleId: googleId,
      emailVerifiedAt: now, // Google accounts are pre-verified
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get display name
  String get displayName => '$firstName $lastName'.trim();

  /// Get initials for avatar
  String get initials {
    String first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  /// Check if user signed in with Google
  bool get isGoogleUser => googleId != null;

  /// Check if email is verified
  bool get isEmailVerified => emailVerifiedAt != null;

  /// Copy with method for creating modified copies
  GoogleResponseModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? profilePictureUrl,
    String? googleId,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoogleResponseModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      googleId: googleId ?? this.googleId,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    phone,
    profilePictureUrl,
    googleId,
    emailVerifiedAt,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, isGoogleUser: $isGoogleUser)';
  }
}
