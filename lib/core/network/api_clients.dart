import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// Authentication API client
@lazySingleton
class AuthApiClient {
  final ApiService _apiService;
  final SharedPreferences _prefs;

  AuthApiClient(this._apiService, this._prefs);

  /// Login with email and password
  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.loginEndpoint,
      data: {'email': email, 'password': password},
      parser: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final token = response.data!['token'] as String?;
      if (token != null) {
        await _saveToken(token);
        _apiService.setAuthToken(token);
      }
    }

    return response;
  }

  /// Register new user
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.registerEndpoint,
      data: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null) 'phone': phone,
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final token = response.data!['token'] as String?;
      if (token != null) {
        await _saveToken(token);
        _apiService.setAuthToken(token);
      }
    }

    return response;
  }

  /// Register/Login with Google
  Future<ApiResponse<Map<String, dynamic>>> registerWithGoogle({
    required String email,
    required String firstName,
    required String lastName,
    required String googleId,
    String? profilePictureUrl,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.registerGoogleAuthEndpoint,
      data: {
        'email': email,
        'name': '$firstName $lastName',
        'first_name': firstName,
        'last_name': lastName,
        'uid': googleId,
        if (profilePictureUrl != null) 'avatar': profilePictureUrl,
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final token = response.data!['access_token'] as String?;
      if (token != null) {
        await _saveToken(token);
        _apiService.setAuthToken(token);
      }
    }

    return response;
  }

  /// Refresh authentication token
  Future<ApiResponse<Map<String, dynamic>>> refreshToken() async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.refreshTokenEndpoint,
      requiresAuth: true,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final token = response.data!['token'] as String?;
      if (token != null) {
        await _saveToken(token);
        _apiService.setAuthToken(token);
      }
    }

    return response;
  }

  /// Logout
  Future<ApiResponse<bool>> logout() async {
    final response = await _apiService.post<bool>(
      ApiConstants.logoutEndpoint,
      requiresAuth: true,
      parser: (data) => true,
    );

    await _clearToken();
    _apiService.clearAuthToken();

    return response;
  }

  /// Initialize authentication state
  Future<void> initializeAuth() async {
    final token = await _getStoredToken();
    if (token != null) {
      _apiService.setAuthToken(token);
    }
  }

  /// Save token to local storage
  Future<void> _saveToken(String token) async {
    await _prefs.setString(DataConstants.tokenKey, token);
  }

  /// Get stored token
  Future<String?> _getStoredToken() async {
    return _prefs.getString(DataConstants.tokenKey);
  }

  /// Clear stored token
  Future<void> _clearToken() async {
    await _prefs.remove(DataConstants.tokenKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _getStoredToken();
    return token != null;
  }

  /// Get the current stored token (for internal use)
  Future<String?> getStoredToken() async {
    return await _getStoredToken();
  }

  /// Update user profile with country, gender, and birthday
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required String country,
    required String gender,
    required DateTime birthday,
  }) async {
    final formData = {
      'countryLanguages': country,
      'birthday': birthday.toIso8601String(),
      'gender': gender,
    };

    final response = await _apiService.put<Map<String, dynamic>>(
      ApiConstants.userProfileUpdateEndpoint,
      data: formData,
      requiresAuth: true,
      parser: (data) => data as Map<String, dynamic>,
    );

    return response;
  }

  /// Update user profile with optional fields (name, first_name, avatar)
  Future<ApiResponse<Map<String, dynamic>>> updateUserProfile({
    String? name,
    String? firstName,
    File? avatarFile,
    String? gender,
  }) async {
    // Create form data map
    Map<String, dynamic> formData = {};

    if (name != null) {
      formData['name'] = name;
    }
    if (firstName != null) {
      formData['firstName'] = firstName;
    }
    if (gender != null) {
      formData['gender'] = gender;
    }

    // If we have an avatar file, we need to use our custom file upload method with PUT
    if (avatarFile != null) {
      try {
        // Create FormData with the file and additional fields
        final fileName = avatarFile.path.split('/').last;
        final uploadFormData = FormData();

        // Add the file
        uploadFormData.files.add(
          MapEntry(
            'avatar',
            await MultipartFile.fromFile(avatarFile.path, filename: fileName),
          ),
        );

        // Add other fields
        formData.forEach((key, value) {
          uploadFormData.fields.add(MapEntry(key, value.toString()));
        });

        // Use custom file upload method with PUT
        final response = await _apiService
            .customFileUpload<Map<String, dynamic>>(
              endpoint: ApiConstants.userProfileUpdateEndpoint,
              formData: uploadFormData,
              method: HttpMethod.put,
              requiresAuth: true,
              parser: (data) => data as Map<String, dynamic>,
            );

        return response;
      } catch (e) {
        return ApiResponse.failure(
          message: 'Error uploading file: ${e.toString()}',
          statusCode: 500,
        );
      }
    } else if (formData.isNotEmpty) {
      // If we only have text fields, use regular PUT
      return await _apiService.put<Map<String, dynamic>>(
        ApiConstants.userProfileUpdateEndpoint,
        data: formData,
        requiresAuth: true,
        parser: (data) => data as Map<String, dynamic>,
      );
    } else {
      // Nothing to update
      return ApiResponse.failure(
        message: 'No data provided for update',
        statusCode: 400,
      );
    }
  }
}

/// User API client
@lazySingleton
class UserApiClient {
  final ApiService _apiService;

  UserApiClient(this._apiService);

  /// Get user profile
  Future<ApiResponse<Map<String, dynamic>>> getUserProfile() async {
    return await _apiService.get<Map<String, dynamic>>(
      ApiConstants.userProfileEndpoint,
      requiresAuth: true,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get user profile by ID
  Future<ApiResponse<Map<String, dynamic>>> getUserById(String userId) async {
    return await _apiService.get<Map<String, dynamic>>(
      '/api/auth/user/$userId',
      requiresAuth: true,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update user profile
  Future<ApiResponse<Map<String, dynamic>>> updateUserProfile(
    Map<String, dynamic> userData,
  ) async {
    return await _apiService.put<Map<String, dynamic>>(
      ApiConstants.userProfileEndpoint,
      data: userData,
      requiresAuth: true,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Upload profile picture
  Future<ApiResponse<Map<String, dynamic>>> uploadProfilePicture(
    File imageFile,
  ) async {
    final request = FileUploadRequest(
      endpoint: '${ApiConstants.userProfileEndpoint}/picture',
      file: imageFile,
      fieldName: 'profile_picture',
      requiresAuth: true,
    );

    return await _apiService.uploadFile<Map<String, dynamic>>(
      request,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Delete user account
  Future<ApiResponse<bool>> deleteAccount() async {
    return await _apiService.delete<bool>(
      ApiConstants.userProfileEndpoint,
      requiresAuth: true,
      parser: (data) => true,
    );
  }
}

/// File upload API client
@lazySingleton
class FileUploadApiClient {
  final ApiService _apiService;

  FileUploadApiClient(this._apiService);

  /// Upload single file
  Future<ApiResponse<Map<String, dynamic>>> uploadFile({
    required File file,
    String? customEndpoint,
    String fieldName = 'file',
    Map<String, dynamic>? additionalFields,
    bool requiresAuth = true,
    ProgressCallback? onProgress,
  }) async {
    if (!_isValidFile(file)) {
      return ApiResponse.failure(
        message: 'Invalid file type or size',
        statusCode: 400,
      );
    }

    final request = FileUploadRequest(
      endpoint: customEndpoint ?? ApiConstants.uploadFileEndpoint,
      file: file,
      fieldName: fieldName,
      additionalFields: additionalFields,
      requiresAuth: requiresAuth,
      onProgress: onProgress,
    );

    return await _apiService.uploadFile<Map<String, dynamic>>(
      request,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Upload multiple files
  Future<ApiResponse<Map<String, dynamic>>> uploadFiles({
    required List<File> files,
    String? customEndpoint,
    String fieldName = 'files',
    Map<String, dynamic>? additionalFields,
    bool requiresAuth = true,
    ProgressCallback? onProgress,
  }) async {
    for (final file in files) {
      if (!_isValidFile(file)) {
        return ApiResponse.failure(
          message: 'One or more files are invalid',
          statusCode: 400,
        );
      }
    }

    final request = MultiFileUploadRequest(
      endpoint: customEndpoint ?? ApiConstants.uploadFileEndpoint,
      files: files,
      fieldName: fieldName,
      additionalFields: additionalFields,
      requiresAuth: requiresAuth,
      onProgress: onProgress,
    );

    return await _apiService.uploadFiles<Map<String, dynamic>>(
      request,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Validate file
  bool _isValidFile(File file) {
    if (!file.existsSync()) return false;

    final fileName = file.path.split('/').last.toLowerCase();
    final extension = fileName.split('.').last;

    // Check file size
    final fileSize = file.lengthSync();
    if (fileSize > ApiConstants.maxFileSize) return false;

    // Check file type
    final allowedTypes = [
      ...ApiConstants.allowedImageTypes,
      ...ApiConstants.allowedDocumentTypes,
      ...ApiConstants.allowedVideoTypes,
    ];

    return allowedTypes.contains(extension);
  }
}

/// Generic API client for custom endpoints
@lazySingleton
class GenericApiClient {
  final ApiService _apiService;

  GenericApiClient(this._apiService);

  /// Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    return await _apiService.get<T>(
      endpoint,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
      parser: parser,
    );
  }

  /// Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    return await _apiService.post<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
      parser: parser,
    );
  }

  /// Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    return await _apiService.put<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
      parser: parser,
    );
  }

  /// Generic PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    return await _apiService.patch<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
      parser: parser,
    );
  }

  /// Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    return await _apiService.delete<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
      parser: parser,
    );
  }

  /// Send form data
  Future<ApiResponse<T>> sendFormData<T>(
    String endpoint, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = false,
    T Function(dynamic)? parser,
  }) async {
    return await _apiService.sendFormData<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
      parser: parser,
    );
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
    return await _apiService.sendMultipartFormData<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
      parser: parser,
    );
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
    return await _apiService.downloadFile(
      endpoint,
      savePath,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
      onProgress: onProgress,
    );
  }
}
