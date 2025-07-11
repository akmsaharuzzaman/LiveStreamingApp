import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../constants/app_constants.dart';
import 'network_info.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  Dio get dio {
    final dio = Dio();

    dio.options = BaseOptions(
      baseUrl: DataConstants.baseUrl,
      connectTimeout: DataConstants.connectionTimeout,
      receiveTimeout: DataConstants.receiveTimeout,
      headers: {
        ApiConstants.headerContentType: ApiConstants.contentTypeJson,
        ApiConstants.headerAccept: ApiConstants.contentTypeJson,
      },
    );

    // Add interceptors for logging, authentication, etc.
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ),
    );

    // Add auth interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add any common headers or authentication logic here
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Handle successful responses
          handler.next(response);
        },
        onError: (DioException error, handler) {
          // Handle errors globally
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  @lazySingleton
  NetworkInfo get networkInfo => NetworkInfoImpl();
}
