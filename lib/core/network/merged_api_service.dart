import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// API Result wrapper for handling success and failure states
abstract class ApiResult<T> {
  const factory ApiResult.success(T data) = Success<T>;
  const factory ApiResult.failure(String error) = Failure<T>;

  /// Check if the result is successful
  bool get isSuccess;

  /// Check if the result is a failure
  bool get isFailure;

  /// Get data if success, null if failure
  T? get dataOrNull;

  /// Get error message if failure, null if success
  String? get errorOrNull;

  /// Transform success data to another type
  ApiResult<R> map<R>(R Function(T) transform);

  /// Transform success data to another ApiResult
  ApiResult<R> flatMap<R>(ApiResult<R> Function(T) transform);

  /// Execute action if success
  ApiResult<T> onSuccess(void Function(T) action);

  /// Execute action if failure
  ApiResult<T> onFailure(void Function(String) action);

  /// Get data or provide default value
  T getOrElse(T defaultValue);

  /// Get data or execute fallback function
  T getOrElseGet(T Function() fallback);

  /// Fold the result into a single value
  R fold<R>(R Function(T) onSuccess, R Function(String) onFailure);

  /// Pattern matching method
  R when<R>({
    required R Function(T) success,
    required R Function(String) failure,
  });
}

/// Success implementation
class Success<T> implements ApiResult<T> {
  final T data;

  const Success(this.data);

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  T? get dataOrNull => data;

  @override
  String? get errorOrNull => null;

  @override
  ApiResult<R> map<R>(R Function(T) transform) {
    try {
      return Success(transform(data));
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  ApiResult<R> flatMap<R>(ApiResult<R> Function(T) transform) {
    try {
      return transform(data);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  ApiResult<T> onSuccess(void Function(T) action) {
    action(data);
    return this;
  }

  @override
  ApiResult<T> onFailure(void Function(String) action) {
    return this;
  }

  @override
  T getOrElse(T defaultValue) => data;

  @override
  T getOrElseGet(T Function() fallback) => data;

  @override
  R fold<R>(R Function(T) onSuccess, R Function(String) onFailure) {
    return onSuccess(data);
  }

  @override
  R when<R>({
    required R Function(T) success,
    required R Function(String) failure,
  }) {
    return success(data);
  }
}

/// Failure implementation
class Failure<T> implements ApiResult<T> {
  final String error;

  const Failure(this.error);

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  T? get dataOrNull => null;

  @override
  String? get errorOrNull => error;

  @override
  ApiResult<R> map<R>(R Function(T) transform) {
    return Failure<R>(error);
  }

  @override
  ApiResult<R> flatMap<R>(ApiResult<R> Function(T) transform) {
    return Failure<R>(error);
  }

  @override
  ApiResult<T> onSuccess(void Function(T) action) {
    return this;
  }

  @override
  ApiResult<T> onFailure(void Function(String) action) {
    action(error);
    return this;
  }

  @override
  T getOrElse(T defaultValue) => defaultValue;

  @override
  T getOrElseGet(T Function() fallback) => fallback();

  @override
  R fold<R>(R Function(T) onSuccess, R Function(String) onFailure) {
    return onFailure(error);
  }

  @override
  R when<R>({
    required R Function(T) success,
    required R Function(String) failure,
  }) {
    return failure(error);
  }
}

/// Network exception handler
class NetworkExceptions {
  /// Handle different types of errors
  static String handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else {
      return 'Unknown error occurred: ${error.toString()}';
    }
  }

  /// Handle Dio specific errors
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';

      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';

      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';

      case DioExceptionType.badResponse:
        return _handleStatusCodeError(
          error.response?.statusCode,
          error.response?.data,
        );

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';

      case DioExceptionType.badCertificate:
        return 'Certificate verification failed.';
      case DioExceptionType.unknown:
        return 'Network error occurred. Please try again.';
    }
  }

  /// Handle HTTP status code errors
  static String _handleStatusCodeError(int? statusCode, dynamic responseData) {
    switch (statusCode) {
      case 400:
        return _extractErrorMessage(responseData) ??
            'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Forbidden. You don\'t have permission to access this resource.';
      case 404:
        return 'Resource not found.';
      case 408:
        return 'Request timeout. Please try again.';
      case 409:
        return 'Conflict. Resource already exists.';
      case 422:
        return _extractErrorMessage(responseData) ?? 'Validation error.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. Please try again later.';
      default:
        return _extractErrorMessage(responseData) ??
            'Request failed with status code: $statusCode';
    }
  }

  /// Extract error message from response data
  static String? _extractErrorMessage(dynamic responseData) {
    if (responseData == null) return null;

    try {
      if (responseData is Map<String, dynamic>) {
        // Try different possible error message keys
        final errorKeys = [
          'message',
          'error',
          'detail',
          'error_description',
          'errors',
        ];

        for (final key in errorKeys) {
          if (responseData.containsKey(key)) {
            final value = responseData[key];
            if (value is String) {
              return value;
            } else if (value is List && value.isNotEmpty) {
              return value.first.toString();
            } else if (value is Map && value.containsKey('message')) {
              return value['message'].toString();
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting error message: $e');
      }
    }

    return null;
  }

  /// Create a default error message
  static String defaultError([String? message]) {
    return message ?? 'An unexpected error occurred. Please try again.';
  }
}

/// HTTP Method enum for better type safety
enum HttpMethod { get, post, put, patch, delete }

/// Request configuration class
class ApiRequest {
  final String endpoint;
  final HttpMethod method;
  final Map<String, dynamic>? queryParameters;
  final Map<String, dynamic>? data;
  final Map<String, String>? headers;
  final bool requiresAuth;
  final Duration? timeout;

  const ApiRequest({
    required this.endpoint,
    required this.method,
    this.queryParameters,
    this.data,
    this.headers,
    this.requiresAuth = false,
    this.timeout,
  });
}

/// File upload configuration
class FileUploadRequest {
  final String endpoint;
  final File file;
  final String fieldName;
  final Map<String, dynamic>? additionalFields;
  final Map<String, String>? headers;
  final bool requiresAuth;
  final ProgressCallback? onProgress;

  const FileUploadRequest({
    required this.endpoint,
    required this.file,
    this.fieldName = 'file',
    this.additionalFields,
    this.headers,
    this.requiresAuth = false,
    this.onProgress,
  });
}

/// Multiple files upload configuration
class MultiFileUploadRequest {
  final String endpoint;
  final List<File> files;
  final String fieldName;
  final Map<String, dynamic>? additionalFields;
  final Map<String, String>? headers;
  final bool requiresAuth;
  final ProgressCallback? onProgress;

  const MultiFileUploadRequest({
    required this.endpoint,
    required this.files,
    this.fieldName = 'files',
    this.additionalFields,
    this.headers,
    this.requiresAuth = false,
    this.onProgress,
  });
}

/// API Response wrapper (Compatible with both approaches)
class ApiResponse<T> {
  final T? data;
  final String? message;
  final int? statusCode;
  final bool isSuccess;
  final Map<String, dynamic>? headers;

  const ApiResponse({
    this.data,
    this.message,
    this.statusCode,
    required this.isSuccess,
    this.headers,
  });

  factory ApiResponse.success({
    T? data,
    String? message,
    int? statusCode,
    Map<String, dynamic>? headers,
  }) {
    return ApiResponse<T>(
      data: data,
      message: message,
      statusCode: statusCode,
      isSuccess: true,
      headers: headers,
    );
  }

  factory ApiResponse.failure({
    String? message,
    int? statusCode,
    Map<String, dynamic>? headers,
  }) {
    return ApiResponse<T>(
      message: message,
      statusCode: statusCode,
      isSuccess: false,
      headers: headers,
    );
  }
}

/// Authentication interceptor for handling JWT tokens
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for certain endpoints
    if (_shouldSkipAuth(options.path)) {
      return handler.next(options);
    }

    try {
      // Check if auth token is already in headers
      final existingAuth =
          options.headers[ApiConstants.authHeader] ??
          options.headers[ApiConstants.headerAuthorization];

      if (existingAuth != null && existingAuth.toString().isNotEmpty) {
        return handler.next(options);
      }

      // Try to get token from SharedPreferences (fallback for compatibility)
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(DataConstants.tokenKey);

      if (token != null && token.isNotEmpty) {
        options.headers[ApiConstants.authHeader] = 'Bearer $token';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding auth token: $e');
      }
    }

    handler.next(options);
  }

  bool _shouldSkipAuth(String path) {
    final skipAuthPaths = [
      ApiConstants.loginEndpoint,
      ApiConstants.registerEndpoint,
      '/auth/refresh',
      '/auth/forgot-password',
      '/auth/reset-password',
    ];

    return skipAuthPaths.any((skipPath) => path.contains(skipPath));
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 unauthorized errors
    if (err.response?.statusCode == 401) {
      // You can handle token refresh here if needed
      // For now, just pass the error along
    }
    handler.next(err);
  }
}

/// Logging interceptor for development
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('🌐 [${options.method}] ${options.baseUrl}${options.path}');
      if (options.queryParameters.isNotEmpty) {
        print('📋 Query Parameters: ${options.queryParameters}');
      }
      if (options.data != null) {
        print('📤 Request Data: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('✅ [${response.statusCode}] ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('❌ [${err.response?.statusCode}] ${err.requestOptions.path}');
      print('Error: ${err.message}');
    }
    handler.next(err);
  }
}

/// Comprehensive API service combining both approaches
@lazySingleton
class ApiService {
  late final Dio _dio;
  String? _authToken;

  // Singleton support for legacy code
  static ApiService? _instance;

  static ApiService get instance {
    _instance ??= ApiService._create();
    return _instance!;
  }

  // Constructor for dependency injection
  ApiService() {
    _dio = Dio();
    _setupDio();
  }

  // Private constructor for singleton
  ApiService._create() {
    _dio = Dio();
    _setupDio();
  }

  /// Configure Dio with base settings and interceptors
  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: DataConstants.baseUrl,
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

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers[ApiConstants.authHeader] = 'Bearer $token';
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove(ApiConstants.authHeader);
  }

  /// Generic request method (new approach)
  Future<ApiResponse<T>> request<T>(
    ApiRequest request, {
    T Function(dynamic)? parser,
  }) async {
    try {
      final options = _buildRequestOptions(request);

      Response response;

      switch (request.method) {
        case HttpMethod.get:
          response = await _dio.get(
            request.endpoint,
            queryParameters: request.queryParameters,
            options: options,
          );
          break;
        case HttpMethod.post:
          response = await _dio.post(
            request.endpoint,
            data: request.data,
            queryParameters: request.queryParameters,
            options: options,
          );
          break;
        case HttpMethod.put:
          response = await _dio.put(
            request.endpoint,
            data: request.data,
            queryParameters: request.queryParameters,
            options: options,
          );
          break;
        case HttpMethod.patch:
          response = await _dio.patch(
            request.endpoint,
            data: request.data,
            queryParameters: request.queryParameters,
            options: options,
          );
          break;
        case HttpMethod.delete:
          response = await _dio.delete(
            request.endpoint,
            data: request.data,
            queryParameters: request.queryParameters,
            options: options,
          );
          break;
      }

      return _handleResponse<T>(response, parser);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// GET request (legacy compatible)
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

      return _handleLegacyResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// POST request (legacy compatible)
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

      return _handleLegacyResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// PUT request (legacy compatible)
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

      return _handleLegacyResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// PATCH request (legacy compatible)
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

      return _handleLegacyResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// DELETE request (legacy compatible)
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

      return _handleLegacyResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// Upload single file (legacy compatible)
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

      return _handleLegacyResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// Upload multiple files (legacy compatible)
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

      return _handleLegacyResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// Upload with multipart data (legacy compatible)
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

      return _handleLegacyResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.failure(NetworkExceptions.handleError(e));
    }
  }

  /// Download file (legacy compatible)
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

  /// Build request options
  Options _buildRequestOptions(ApiRequest request) {
    final headers = <String, dynamic>{
      ApiConstants.headerContentType: ApiConstants.contentTypeJson,
      ApiConstants.headerAccept: ApiConstants.contentTypeJson,
      ...?request.headers,
    };

    if (request.requiresAuth && _authToken != null) {
      headers[ApiConstants.headerAuthorization] =
          '${ApiConstants.headerBearerPrefix}$_authToken';
    }

    return Options(
      headers: headers,
      sendTimeout: request.timeout ?? DataConstants.connectionTimeout,
      receiveTimeout: request.timeout ?? DataConstants.receiveTimeout,
    );
  }

  /// Handle successful response (new approach)
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? parser,
  ) {
    final data = parser != null ? parser(response.data) : response.data as T?;

    return ApiResponse.success(
      data: data,
      message: response.statusMessage,
      statusCode: response.statusCode,
      headers: response.headers.map,
    );
  }

  /// Handle legacy response format
  ApiResult<T> _handleLegacyResponse<T>(
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

  /// Handle errors (new approach)
  ApiResponse<T> _handleError<T>(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiResponse.failure(
            message: ApiConstants.timeoutError,
            statusCode: 408,
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          String message;

          switch (statusCode) {
            case 400:
              message = 'Bad request';
              break;
            case 401:
              message = ApiConstants.unauthorizedError;
              break;
            case 403:
              message = 'Forbidden';
              break;
            case 404:
              message = 'Not found';
              break;
            case 500:
              message = ApiConstants.serverError;
              break;
            default:
              message =
                  error.response?.data?['message'] ?? ApiConstants.unknownError;
          }

          return ApiResponse.failure(message: message, statusCode: statusCode);
        case DioExceptionType.cancel:
          return ApiResponse.failure(
            message: 'Request was cancelled',
            statusCode: 499,
          );
        case DioExceptionType.connectionError:
          return ApiResponse.failure(
            message: ApiConstants.networkError,
            statusCode: 0,
          );
        default:
          return ApiResponse.failure(
            message: ApiConstants.unknownError,
            statusCode: 0,
          );
      }
    }

    if (error is ServerException) {
      return ApiResponse.failure(message: error.message, statusCode: 500);
    }

    return ApiResponse.failure(message: error.toString(), statusCode: 0);
  }

  /// Get current Dio instance (for advanced usage)
  Dio get dio => _dio;
}
