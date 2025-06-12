import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/dio_client.dart';

class AuthRepository {
  late DioClient dioClient;
  final ImagePicker _imagePicker = ImagePicker();
  final String _baseUrl = dotenv.env["BASE_URL"]!;

  AuthRepository() {
    var dio = Dio();
    dioClient = DioClient(_baseUrl, dio);
  }
  // Future<RegistrationResponse> userRegistration({
  //   required String phone,
  //   required String password,
  //   required String confirmPassword,
  // }) async {
  //   try {
  //     final resp = await dioClient.post("/api/auth/register", data: {
  //       "phone": phone,
  //       "password": password,
  //       "password_confirmation": confirmPassword
  //     });
  //
  //     RegistrationResponse userRegistrationResponse =
  //         RegistrationResponse.fromJson(jsonDecode(jsonEncode(resp)));
  //
  //     await Fluttertoast.showToast(
  //       backgroundColor: Colors.green,
  //       textColor: Colors.white,
  //       webPosition: "center",
  //       msg: userRegistrationResponse.message.toString(),
  //     );
  //
  //     return userRegistrationResponse;
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
}
