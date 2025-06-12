part of 'profile_bloc.dart';

@freezed
class ProfileEvent with _$ProfileEvent {
  const factory ProfileEvent.userDataLoaded({required String uid}) =
      _UserDataLoaded;

  const factory ProfileEvent.imagePicked({
    required BuildContext context,
    required bool cameraImage,
  }) = _ImagePicked;

  const factory ProfileEvent.saveUserProfile({
    required BuildContext context,
    required String name,
    required String birthday,
    required String bio,
  }) = _SaveUserProfile;
}
