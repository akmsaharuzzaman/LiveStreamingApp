import 'package:dlstarlive/core/network_temp/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthRepository {
  late DioClient dioClient;
  final String _baseUrl = dotenv.env["BASE_URL"]!;

  AuthRepository() {
    var dio = Dio();
    dioClient = DioClient(_baseUrl, dio);
  }
}
