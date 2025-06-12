import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_djlive/features/auth/data/models/user_profile.dart';
import 'package:streaming_djlive/features/auth/data/models/user_profile_data_response/user_profile_data_response.dart';
import 'package:streaming_djlive/features/auth/data/repositories/log_in_repository.dart';

import '../../../../core/services/login_provider.dart';

part 'log_in_bloc.freezed.dart';
part 'log_in_event.dart';
part 'log_in_state.dart';

class LogInBloc extends Bloc<LogInEvent, LogInState> {
  final LogInRepository logInRepository;

  LogInBloc({required this.logInRepository}) : super(const LogInState()) {
    on<LogInEvent>((events, emit) async {
      await events.map(
        googleLogIn: (event) async => await _googleLogIn(event, emit),
        isProfileComplete: (event) async =>
            await _isProfileComplete(event, emit),
        firstNameChanged: (event) async => await _firstNameChanged(event, emit),
        lastNameChanged: (event) async => await _lastNameChanged(event, emit),
        bioChanged: (event) async => await _bioChanged(event, emit),
        genderChanged: (event) async => await _genderChanged(event, emit),
        countryChanged: (event) async => await _countryChanged(event, emit),
        birthDayChanged: (event) async => await _birthDayChanged(event, emit),
        saveUserProfile: (event) async => await _saveUserProfile(event, emit),
        imagePicked: (event) async => await _imagePicked(event, emit),
        profileDataLoad: (event) async => await _profileDataLoad(event, emit),
      );
    });
  }

  Future<void> _googleLogIn(
      _GoogleLogIn event, Emitter<LogInState> emit) async {
    emit(state.copyWith(logInStatus: LogInStatus.inProgress));
    final route = GoRouter.of(event.context);
    try {
      final googleSignUpResponse =
          await LogInRepository().signInWithGoogle(body: event.body);
      print("userrrr $googleSignUpResponse");

      emit(state.copyWith(
        userProfile: googleSignUpResponse,
        logInStatus: LogInStatus.success,
      ));

      String? token = googleSignUpResponse.accessToken;
      if (kDebugMode) {
        print("infoToken 2: $token");
      }

      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString("token", token);
        await prefs.setString(
            "uid", googleSignUpResponse.result?.first.id ?? "");
      }

      final info = event.context.read<LoginInfo>();
      info.login(token ?? "");
      //route.go(DispatchScreen.route);
      if ((googleSignUpResponse.result?.first.bio?.isNotEmpty ?? true) &&
          (googleSignUpResponse.result?.first.country?.isNotEmpty ?? true) &&
          (googleSignUpResponse.result?.first.gender?.isNotEmpty ?? true)) {
        route.go('/profileComplete');
      } else {
        route.go('/home');
      }
    } catch (e) {
      emit(state.copyWith(logInStatus: LogInStatus.failure));
    }
  }

  Future<void> _isProfileComplete(
      _IsProfileComplete event, Emitter<LogInState> emit) async {
    emit(state.copyWith(logInStatus: LogInStatus.inProgress));
    try {
      final value =
          await logInRepository.isProfileComplete(state.userInfoProfile!);
      emit(state.copyWith(
        isProfileComplete: value,
        logInStatus: LogInStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(logInStatus: LogInStatus.failure));
    }
  }

  Future<void> _profileDataLoad(
      _ProfileDataLoad event, Emitter<LogInState> emit) async {
    emit(state.copyWith(logInStatus: LogInStatus.inProgress));
    try {
      final userData = await logInRepository.profileDataLoad(uid: event.uId);
      emit(state.copyWith(
        userInfoProfile: userData,
        logInStatus: LogInStatus.success,
      ));
    } catch (e) {
      print("Profile data load error: $e");
      emit(state.copyWith(logInStatus: LogInStatus.failure));
    }
  }

  Future<void> _firstNameChanged(
      _FirstNameChanged event, Emitter<LogInState> emit) async {
    final userProfile = state.userInfoProfile;
    final resultList = userProfile.result;

    if (resultList != null) {
      final updatedResult =
          userProfile.result?.copyWith(firstName: event.firstName);

      emit(state.copyWith(
        userInfoProfile: userProfile.copyWith(result: updatedResult),
      ));
    }
  }

  Future<void> _lastNameChanged(
      _LastNameChanged event, Emitter<LogInState> emit) async {
    final userProfile = state.userInfoProfile;
    final resultList = userProfile.result;

    if (resultList != null) {
      final updatedResult =
          userProfile.result?.copyWith(lastName: event.lastName);

      emit(state.copyWith(
        userInfoProfile: userProfile.copyWith(result: updatedResult),
      ));
    }
  }

  Future<void> _bioChanged(_BioChanged event, Emitter<LogInState> emit) async {
    final userProfile = state.userInfoProfile;
    final resultList = userProfile.result;

    if (resultList != null) {
      final updatedResult = userProfile.result?.copyWith(bio: event.bio);

      emit(state.copyWith(
        userInfoProfile: userProfile.copyWith(result: updatedResult),
      ));
    }
  }

  Future<void> _genderChanged(
      _GenderChanged event, Emitter<LogInState> emit) async {
    final userProfile = state.userProfile;
    final resultList = userProfile.result;

    if (resultList != null && resultList.isNotEmpty) {
      final updatedResult = resultList.first.copyWith(gender: event.gender);
      final updatedResultList = [...resultList];
      updatedResultList[0] = updatedResult;

      emit(state.copyWith(
        userProfile: userProfile.copyWith(result: updatedResultList),
      ));
    }
  }

  Future<void> _countryChanged(
      _CountryChanged event, Emitter<LogInState> emit) async {
    final userProfile = state.userInfoProfile;
    final resultList = userProfile.result;

    if (resultList != null) {
      final updatedResult =
          userProfile.result?.copyWith(country: event.countryName);

      emit(state.copyWith(
        userInfoProfile: userProfile.copyWith(result: updatedResult),
      ));
    }
  }

  Future<void> _birthDayChanged(
      _BirthDayChanged event, Emitter<LogInState> emit) async {
    final userProfile = state.userInfoProfile;
    final resultList = userProfile.result;

    if (resultList != null) {
      final updatedResult =
          userProfile.result?.copyWith(birthday: event.birthDay);

      emit(state.copyWith(
        userInfoProfile: userProfile.copyWith(result: updatedResult),
      ));
    }
  }

  Future<void> _saveUserProfile(
      _SaveUserProfile event, Emitter<LogInState> emit) async {
    emit(state.copyWith(profileSaveStatus: ProfileSaveStatus.inProgress));
    final route = GoRouter.of(event.context);

    try {
      await logInRepository.saveUserProfile(
          firstName: event.firstName,
          lastName: event.lastName,
          birthday: event.birthday,
          gender: event.gender,
          bio: event.bio,
          countryName: event.countryName,
          countryDialCode: event.countryDialCode,
          countryIsoCode: event.countryIsoCode,
          countryLanguages: [event.countryLanguages.toString()]);
      emit(state.copyWith(
        //userInfoProfile: userData,
        logInStatus: LogInStatus.success,
      ));
      route.go('/home');
    } catch (e) {
      print("Profile submit error is $e");
      emit(state.copyWith(profileSaveStatus: ProfileSaveStatus.failure));
    }
  }

  _imagePicked(_ImagePicked event, Emitter<LogInState> emit) async {
    emit(state.copyWith(
      logInStatus: LogInStatus.initial,
    ));
    try {
      final XFile? pickedImage =
          await logInRepository.openImagePicker(event.cameraImage);
      if (pickedImage == null) return;

      final imageBytes = await pickedImage.readAsBytes();

      if (imageBytes != null) {
        await logInRepository.createProfileImageSubmitted(
          imageBytes: imageBytes,
        );
      }

      emit(state.copyWith(
        imageBytes: imageBytes,
        pickedImageFile: pickedImage,
        logInStatus: LogInStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        logInStatus: LogInStatus.failure,
      ));
    }
  }
}
