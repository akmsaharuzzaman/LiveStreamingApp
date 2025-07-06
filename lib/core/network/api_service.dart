import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dlstarlive/core/network/api_constants.dart';
import 'package:dlstarlive/core/network/api_interceptors.dart';
import 'package:dlstarlive/core/network/api_result.dart';
import 'package:dlstarlive/core/network/network_exceptions.dart';

/// Comprehensive API service using Dio for all HTTP operations
/// Supports GET, POST, PUT, PATCH, DELETE, and file uploads
class ApiService {
  late final Dio _dio;

  static ApiService? _instance;

  /// Singleton instance
  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  ApiService._internal() {
    _dio = Dio();
    _setupDio();
  }

  /// Configure Dio with base settings and interceptors
  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add interceptors
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LoggingInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: true,
        ),
      );
    }
  }

  /// GET request
  Future<ApiResult<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// POST request
  Future<ApiResult<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// PUT request
  Future<ApiResult<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// PATCH request
  Future<ApiResult<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// DELETE request
  Future<ApiResult<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// Upload single file
  Future<ApiResult<T>> uploadFile<T>(
    String endpoint,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final formData = FormData();

      // Add file
      formData.files.add(
        MapEntry(fieldName, await MultipartFile.fromFile(filePath)),
      );

      // Add additional data
      if (data != null) {
        data.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// Upload multiple files
  Future<ApiResult<T>> uploadMultipleFiles<T>(
    String endpoint,
    List<String> filePaths, {
    String fieldName = 'files',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final formData = FormData();

      // Add files
      for (int i = 0; i < filePaths.length; i++) {
        formData.files.add(
          MapEntry(
            '$fieldName[$i]',
            await MultipartFile.fromFile(filePaths[i]),
          ),
        );
      }

      // Add additional data
      if (data != null) {
        data.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// Upload with multipart data (files + JSON data)
  Future<ApiResult<T>> uploadWithData<T>(
    String endpoint, {
    List<MultipartFile>? files,
    Map<String, dynamic>? fields,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final formData = FormData();

      // Add files
      if (files != null) {
        for (int i = 0; i < files.length; i++) {
          formData.files.add(MapEntry('file_$i', files[i]));
        }
      }

      // Add fields
      if (fields != null) {
        fields.forEach((key, value) {
          if (value is List) {
            formData.fields.add(MapEntry(key, value.join(',')));
          } else {
            formData.fields.add(MapEntry(key, value.toString()));
          }
        });
      }

      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// Download file
  Future<ApiResult<String>> downloadFile(
    String endpoint,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        endpoint,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );

      return ApiResult.success(savePath);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// Handle response and convert to ApiResult
  ApiResult<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      if (fromJson != null) {
        try {
          final data = fromJson(response.data);
          return ApiResult.success(data);
        } catch (e) {
          return ApiResult.failure(
            NetworkExceptions.defaultError('Failed to parse response: $e'),
          );
        }
      } else {
        return ApiResult.success(response.data as T);
      }
    } else {
      return ApiResult.failure(
        NetworkExceptions.defaultError(
          'Request failed with status: ${response.statusCode}',
        ),
      );
    }
  }

  /// Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Update base URL
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Get current Dio instance (for advanced usage)
  Dio get dio => _dio;

  /// Cancel all pending requests
  void cancelAllRequests() {
    _dio.close(force: true);
  }

  // Authentication & User Profile API methods

  /// Get current user profile
  Future<ApiResult<Map<String, dynamic>>> getCurrentUserProfile(
    String userId,
  ) async {
    return await get<Map<String, dynamic>>(
      '/api/auth/user/$userId',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Logout user (if backend requires logout call)
  Future<ApiResult<Map<String, dynamic>>> logoutUser() async {
    return await post<Map<String, dynamic>>(
      '/api/auth/logout',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }
}
