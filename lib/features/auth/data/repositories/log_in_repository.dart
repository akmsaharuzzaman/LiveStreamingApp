import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:streaming_djlive/features/auth/data/models/user_profile_data_response/user_profile_data_response.dart';
import 'package:streaming_djlive/features/auth/presentation/bloc/log_in_bloc/log_in_bloc.dart';

import '../../../core/services/dio_client.dart';
import '../models/user_profile.dart';

class LogInRepository {
  late DioClient dioClient;
  //final String _baseUrl = dotenv.env["BASE_URL"]!;
  final String _baseUrl = "http://dlstarlive.com:8000";

  LogInRepository() {
    var dio = Dio();
    dioClient = DioClient(_baseUrl, dio);
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> googleLogin(BuildContext context) async {
    try {
      GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
      );

      googleSignIn.onCurrentUserChanged
          .listen((GoogleSignInAccount? account) async {
        if (account != null) {
          final fullName = account.displayName ?? '';
          final nameParts = fullName.split(' ');

          final firstName = nameParts.isNotEmpty ? nameParts.first : '';
          final lastName =
              nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

          //BigInt uid = BigInt.parse(account.id);

          Map<String, dynamic> _body = {
            "email": account.email,
            "password": '!Password123',
            "name": fullName,
            "first_name": firstName,
            "last_name": lastName,
            "uid": account.id.toString(),
            "avater": account.photoUrl
          };

          context
              .read<LogInBloc>()
              .add(LogInEvent.googleLogIn(body: _body, context: context));

          await googleSignIn.disconnect();
        }
      });

      await googleSignIn.signIn();
    } on Exception catch (exception) {
      Logger().e(exception);
    }
  }

  Future<UserResponseData> signInWithGoogle(
      {required Map<dynamic, dynamic> body}) async {
    try {
      final resp =
          await dioClient.post("/api/auth/register-google", data: body);
      UserResponseData googleUserDataSubmitted =
          UserResponseData.fromJson(jsonDecode(jsonEncode(resp)));

      print("Google Response is ${googleUserDataSubmitted}");
      return googleUserDataSubmitted;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfileDataResponse> profileDataLoad({required String uid}) async {
    try {
      final resp = await dioClient.get(
        "/api/auth/user/$uid",
      );
      UserProfileDataResponse userDataResponse =
          UserProfileDataResponse.fromJson(jsonDecode(jsonEncode(resp)));

      print("User Response is $userDataResponse");
      return userDataResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isProfileComplete(UserProfileDataResponse user) async {
    final profile = user.result;

    print('Checking profile completeness...');
    print('Profile: $profile');

    if (profile == null) {
      print('Profile is null');
      return false;
    }

    print('First Name: "${profile.firstName}"');
    print('Last Name: "${profile.lastName}"');
    print('Birthday: ${profile.birthday}');
    print('Bio: "${profile.bio}"');

    final isComplete = profile.firstName?.trim().isNotEmpty == true &&
        profile.lastName?.trim().isNotEmpty == true &&
        profile.birthday != null;
    // profile.bio?.trim().isNotEmpty == true;

    print('Is profile complete? $isComplete');
    return isComplete;
  }

  ///pick image
  Future<XFile?> openImagePicker(bool isCamera) async {
    final imageSource = isCamera ? ImageSource.camera : ImageSource.gallery;
    final pickedFile = await _imagePicker.pickImage(
        source: imageSource, maxHeight: 600, maxWidth: 600);
    return pickedFile;
  }

  Future<dynamic> saveUserProfile({
    // required XFile pickedImage,
    required String firstName,
    required String lastName,
    required String birthday,
    required String gender,
    required String bio,
    required String countryName,
    required String countryDialCode,
    required String countryIsoCode,
    required List<String> countryLanguages,
  }) async {
    try {
      FormData formData = FormData();
      formData.fields.addAll([
        MapEntry("first_name", firstName),
      ]);
      formData.fields.addAll([
        MapEntry("last_name", lastName),
      ]);
      formData.fields.addAll([
        MapEntry("bio", bio.toString()),
      ]);
      formData.fields.addAll([
        MapEntry("birthday", birthday.toString()),
      ]);
      formData.fields.addAll([
        MapEntry("gender", gender.toString()),
      ]);
      formData.fields.addAll([
        MapEntry("country", countryName.toString()),
      ]);
      formData.fields.addAll([
        MapEntry("country_dial_code", countryDialCode.toString()),
      ]);
      formData.fields.addAll([
        MapEntry("country_code", countryIsoCode.toString()),
      ]);
      formData.fields.addAll([
        MapEntry("country_languages", jsonEncode(countryLanguages)),
      ]);

      print('FormData being sent:');
      formData.fields.forEach((field) {
        print('${field.key}: ${field.value}');
      });

      final resp =
          await dioClient.put(' /api/auth/update-profile', data: formData);

      return resp;
    } catch (e) {
      print("Error saving user profile: $e");
      return false;
    }
  }

  Future<dynamic> createProfileImageSubmitted({
    required Uint8List imageBytes,
  }) async {
    try {
      final formData = FormData.fromMap({
        "avatar": MultipartFile.fromBytes(
          imageBytes,
          filename: 'image.jpg',
        ),
      });
      final resp = await dioClient.put(
        ' /api/auth/update-profile',
        data: formData,
      );

      return resp;
    } catch (e) {
      print("Error saving user profile: $e");
      return false;
    }
  }
}
