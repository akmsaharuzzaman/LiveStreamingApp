part of 'profile_bloc.dart';

enum ProfileStatus {
  initial,
  inProgress,
  success,
  failure,
}

@Freezed()
class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(ProfileStatus.initial) ProfileStatus logInStatus,
    @Default(null) XFile? pickedImageFile,
    Uint8List? imageBytes,
    @Default(UserProfileDataResponse()) UserProfileDataResponse userProfile,
  }) = _ProfileState;
}
