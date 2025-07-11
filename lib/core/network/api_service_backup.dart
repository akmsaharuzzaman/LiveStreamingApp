import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

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

/// API Response wrapper
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

/// Main API Service
@lazySingleton
class ApiService {
  final Dio _dio;
  String? _authToken;

  ApiService(this._dio);

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Generic request method
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

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    final request = ApiRequest(
      endpoint: endpoint,
      method: HttpMethod.get,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
    );

    return await this.request<T>(request, parser: parser);
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    final request = ApiRequest(
      endpoint: endpoint,
      method: HttpMethod.post,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
    );

    return await this.request<T>(request, parser: parser);
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    final request = ApiRequest(
      endpoint: endpoint,
      method: HttpMethod.put,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
    );

    return await this.request<T>(request, parser: parser);
  }

  /// PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    final request = ApiRequest(
      endpoint: endpoint,
      method: HttpMethod.patch,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
    );

    return await this.request<T>(request, parser: parser);
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    final request = ApiRequest(
      endpoint: endpoint,
      method: HttpMethod.delete,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
    );

    return await this.request<T>(request, parser: parser);
  }

  /// Upload single file
  Future<ApiResponse<T>> uploadFile<T>(
    FileUploadRequest request, {
    T Function(dynamic)? parser,
  }) async {
    try {
      if (!request.file.existsSync()) {
        throw const ServerException('File does not exist');
      }

      final fileSize = await request.file.length();
      if (fileSize > ApiConstants.maxFileSize) {
        throw const ServerException('File size exceeds maximum limit');
      }

      final fileName = request.file.path.split('/').last;
      final formData = FormData.fromMap({
        request.fieldName: await MultipartFile.fromFile(
          request.file.path,
          filename: fileName,
        ),
        ...?request.additionalFields,
      });

      final options = Options(
        headers: {
          ...?request.headers,
          if (request.requiresAuth && _authToken != null)
            ApiConstants.headerAuthorization:
                '${ApiConstants.headerBearerPrefix}$_authToken',
        },
      );

      final response = await _dio.post(
        request.endpoint,
        data: formData,
        options: options,
        onSendProgress: request.onProgress,
      );

      return _handleResponse<T>(response, parser);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Upload multiple files
  Future<ApiResponse<T>> uploadFiles<T>(
    MultiFileUploadRequest request, {
    T Function(dynamic)? parser,
  }) async {
    try {
      for (final file in request.files) {
        if (!file.existsSync()) {
          throw const ServerException('One or more files do not exist');
        }

        final fileSize = await file.length();
        if (fileSize > ApiConstants.maxFileSize) {
          throw const ServerException(
            'One or more files exceed maximum size limit',
          );
        }
      }

      final formData = FormData.fromMap({
        request.fieldName: await Future.wait(
          request.files.map((file) async {
            final fileName = file.path.split('/').last;
            return await MultipartFile.fromFile(file.path, filename: fileName);
          }),
        ),
        ...?request.additionalFields,
      });

      final options = Options(
        headers: {
          ...?request.headers,
          if (request.requiresAuth && _authToken != null)
            ApiConstants.headerAuthorization:
                '${ApiConstants.headerBearerPrefix}$_authToken',
        },
      );

      final response = await _dio.post(
        request.endpoint,
        data: formData,
        options: options,
        onSendProgress: request.onProgress,
      );

      return _handleResponse<T>(response, parser);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Send form data (url-encoded)
  Future<ApiResponse<T>> sendFormData<T>(
    String endpoint, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    try {
      final options = Options(
        headers: {
          ApiConstants.headerContentType: ApiConstants.contentTypeUrlEncoded,
          ...?headers,
          if (requiresAuth && _authToken != null)
            ApiConstants.headerAuthorization:
                '${ApiConstants.headerBearerPrefix}$_authToken',
        },
      );

      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, parser);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Send multipart form data
  Future<ApiResponse<T>> sendMultipartFormData<T>(
    String endpoint, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    try {
      final formData = FormData.fromMap(data);

      final options = Options(
        headers: {
          ...?headers,
          if (requiresAuth && _authToken != null)
            ApiConstants.headerAuthorization:
                '${ApiConstants.headerBearerPrefix}$_authToken',
        },
      );

      final response = await _dio.post(
        endpoint,
        data: formData,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, parser);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Download file
  Future<ApiResponse<String>> downloadFile(
    String endpoint,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    ProgressCallback? onProgress,
  }) async {
    try {
      final options = Options(
        headers: {
          ...?headers,
          if (requiresAuth && _authToken != null)
            ApiConstants.headerAuthorization:
                '${ApiConstants.headerBearerPrefix}$_authToken',
        },
      );

      await _dio.download(
        endpoint,
        savePath,
        queryParameters: queryParameters,
        options: options,
        onReceiveProgress: onProgress,
      );

      return ApiResponse.success(
        data: savePath,
        message: 'File downloaded successfully',
        statusCode: 200,
      );
    } catch (e) {
      return _handleError<String>(e);
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

  /// Handle successful response
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

  /// Handle errors
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

  /// Custom file upload that supports different HTTP methods (PUT, POST, etc.)
  Future<ApiResponse<T>> customFileUpload<T>({
    required String endpoint,
    required FormData formData,
    required HttpMethod method,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    ProgressCallback? onSendProgress,
    T Function(dynamic)? parser,
  }) async {
    try {
      final options = Options(
        headers: {
          ...?headers,
          if (requiresAuth && _authToken != null)
            ApiConstants.headerAuthorization:
                '${ApiConstants.headerBearerPrefix}$_authToken',
        },
      );

      Response response;
      switch (method) {
        case HttpMethod.post:
          response = await _dio.post(
            endpoint,
            data: formData,
            queryParameters: queryParameters,
            options: options,
            onSendProgress: onSendProgress,
          );
          break;
        case HttpMethod.put:
          response = await _dio.put(
            endpoint,
            data: formData,
            queryParameters: queryParameters,
            options: options,
            onSendProgress: onSendProgress,
          );
          break;
        default:
          throw const ServerException(
            'Unsupported method for file upload. Use POST or PUT.',
          );
      }

      return _handleResponse<T>(response, parser);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
}
