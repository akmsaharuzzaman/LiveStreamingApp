part of 'log_in_bloc.dart';

enum LogInStatus {
  initial,
  inProgress,
  success,
  failure,
}

enum ProfileSaveStatus {
  initial,
  inProgress,
  success,
  failure,
}

@Freezed()
class LogInState with _$LogInState {
  const factory LogInState({
    @Default(LogInStatus.initial) LogInStatus logInStatus,
    @Default(ProfileSaveStatus.initial) ProfileSaveStatus profileSaveStatus,
    @Default(UserResponseData()) UserResponseData userProfile,
    @Default(UserProfileDataResponse()) UserProfileDataResponse userInfoProfile,
    @Default(false) bool isProfileComplete,
    @Default(null) XFile? pickedImageFile,
    Uint8List? imageBytes,
  }) = _LogInState;
}
