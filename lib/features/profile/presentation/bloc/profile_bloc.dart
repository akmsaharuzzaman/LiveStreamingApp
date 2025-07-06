import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dlstarlive/features/profile/data/models/profile_data_response/result.dart';

import '../../data/models/profile_data_response/user_profile_data_response.dart';
import '../../data/repositories/profile_repository.dart';

part 'profile_bloc.freezed.dart';
part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileState()) {
    on<ProfileEvent>((events, emit) async {
      await events.map(
        userDataLoaded: (event) async => await _userDataLoaded(event, emit),
        imagePicked: (event) async => await _imagePicked(event, emit),
        saveUserProfile: (event) async => await _saveUserProfile(event, emit),
      );
    });
  }

  Future<void> _userDataLoaded(
    _UserDataLoaded event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(logInStatus: ProfileStatus.inProgress));

    try {
      final user = await ProfileRepository().profileDataLoad(uid: event.uid);

      emit(
        state.copyWith(userProfile: user, logInStatus: ProfileStatus.success),
      );
    } catch (e) {
      emit(state.copyWith(logInStatus: ProfileStatus.failure));
    }
  }

  _imagePicked(_ImagePicked event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(logInStatus: ProfileStatus.initial));
    try {
      final XFile? pickedImage = await ProfileRepository().openImagePicker(
        event.cameraImage,
      );
      if (pickedImage == null) return;

      final imageBytes = await pickedImage.readAsBytes();

      if (imageBytes != null) {
        await ProfileRepository().createProfileImageSubmitted(
          imageBytes: imageBytes,
        );
      }

      emit(
        state.copyWith(
          imageBytes: imageBytes,
          pickedImageFile: pickedImage,
          logInStatus: ProfileStatus.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(logInStatus: ProfileStatus.failure));
    }
  }

  Future<void> _saveUserProfile(
    _SaveUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(logInStatus: ProfileStatus.inProgress));

    try {
      await ProfileRepository().saveUserProfile(
        event.name,
        event.birthday,
        event.bio,
      );
      final userProfile = state.userProfile;
      final resultList = userProfile.result;
      emit(
        state.copyWith(
          //userInfoProfile: userData,
          userProfile: userProfile.copyWith(
            result: Result(
              name: event.name,
              birthday: event.birthday,
              bio: event.bio,
              firstName: resultList?.firstName,
              lastName: resultList?.lastName,
              uid: resultList?.uid,
              country: resultList?.country,
              countryLanguages: resultList?.countryLanguages,
              countryCode: resultList?.countryCode,
              userPoints: resultList?.userPoints,
              avatar: resultList?.avatar,
              resellerCoins: resultList?.resellerCoins,
              resellerHistory: resultList?.resellerHistory,
            ),
          ),
          logInStatus: ProfileStatus.success,
        ),
      );

      await Fluttertoast.showToast(
        webPosition: "center",
        msg: "Profile Update Successfully",
      );
    } catch (e) {
      print("Profile submit error is $e");
      emit(state.copyWith(logInStatus: ProfileStatus.failure));
    }
  }
}
