part of 'log_in_bloc.dart';

@freezed
class LogInEvent with _$LogInEvent {
  const factory LogInEvent.googleLogIn({
    required BuildContext context,
    required Map<dynamic, dynamic> body,
  }) = _GoogleLogIn;
  const factory LogInEvent.isProfileComplete() = _IsProfileComplete;
  const factory LogInEvent.profileDataLoad({required String uId}) =
      _ProfileDataLoad;
  const factory LogInEvent.firstNameChanged({required String firstName}) =
      _FirstNameChanged;
  const factory LogInEvent.lastNameChanged({required String lastName}) =
      _LastNameChanged;
  const factory LogInEvent.bioChanged({required String bio}) = _BioChanged;
  const factory LogInEvent.genderChanged({required String gender}) =
      _GenderChanged;
  const factory LogInEvent.countryChanged({
    required String countryName,
    required String countryDialCode,
    required String countryFlag,
    required String countryIsoCode,
    required List<String> countryLanguages,
  }) = _CountryChanged;
  const factory LogInEvent.birthDayChanged({required String birthDay}) =
      _BirthDayChanged;
  const factory LogInEvent.saveUserProfile({
    required BuildContext context,
    required String firstName,
    required String lastName,
    required String birthday,
    required String gender,
    required String bio,
    required String countryName,
    required String countryDialCode,
    required String countryIsoCode,
    required List<String> countryLanguages,
  }) = _SaveUserProfile;
  const factory LogInEvent.imagePicked({
    required BuildContext context,
    required bool cameraImage,
  }) = _ImagePicked;
}
