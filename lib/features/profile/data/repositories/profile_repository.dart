import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/dio_client.dart';
import '../models/profile_data_response/user_profile_data_response.dart';

class ProfileRepository {
  late DioClient dioClient;
  //final String _baseUrl = dotenv.env["BASE_URL"]!;
  final String _baseUrl = "http://dlstarlive.com:8000";
  final ImagePicker _imagePicker = ImagePicker();
  ProfileRepository() {
    var dio = Dio();
    dioClient = DioClient(_baseUrl, dio);
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

  ///pick image
  Future<XFile?> openImagePicker(bool isCamera) async {
    final imageSource = isCamera ? ImageSource.camera : ImageSource.gallery;
    final pickedFile = await _imagePicker.pickImage(
        source: imageSource, maxHeight: 600, maxWidth: 600);
    return pickedFile;
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

  Future<dynamic> saveUserProfile(
    // required XFile pickedImage,
    String name,
    String birthday,
    String bio,
  ) async {
    try {
      FormData formData = FormData();
      formData.fields.addAll([
        MapEntry("name", name),
      ]);

      formData.fields.addAll([
        MapEntry("bio", bio.toString()),
      ]);
      formData.fields.addAll([
        MapEntry("birthday", birthday.toString()),
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
}
