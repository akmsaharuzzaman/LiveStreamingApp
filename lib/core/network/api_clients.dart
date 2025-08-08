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
    );

    return response.fold((data) {
      // Handle success case
      final token = data['token'] as String?;
      if (token != null) {
        _saveToken(token);
        _apiService.setAuthToken(token);
      }
      return ApiResponse.success(data: data);
    }, (error) => ApiResponse.failure(message: error));
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
    );

    return response.fold((data) {
      // Handle success case
      final token = data['token'] as String?;
      if (token != null) {
        _saveToken(token);
        _apiService.setAuthToken(token);
      }
      return ApiResponse.success(data: data);
    }, (error) => ApiResponse.failure(message: error));
  }

  /// Register/Login with Google
  Future<ApiResponse<Map<String, dynamic>>> registerWithGoogle({
    required String email,
    required String firstName,
    required String lastName,
    required String googleId,
    String? profilePictureUrl,
  }) async {
    // Use longer timeout for Google registration as it may involve additional processing
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
      options: Options(
        sendTimeout: const Duration(
          minutes: 2,
        ), // Increase timeout to 2 minutes
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    print('Google Auth Response: $response');

    return response.fold((data) {
      print('Google Auth Response: $data');
      // Handle success case - try both token formats for compatibility
      final token = data['access_token'] as String? ?? data['token'] as String?;
      if (token != null) {
        _saveToken(token);
        _apiService.setAuthToken(token);
      }
      return ApiResponse.success(data: data);
    }, (error) => ApiResponse.failure(message: error));
  }

  /// Refresh authentication token
  Future<ApiResponse<Map<String, dynamic>>> refreshToken() async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.refreshTokenEndpoint,
    );

    return response.fold((data) {
      // Handle success case
      final token = data['token'] as String?;
      if (token != null) {
        _saveToken(token);
        _apiService.setAuthToken(token);
      }
      return ApiResponse.success(data: data);
    }, (error) => ApiResponse.failure(message: error));
  }

  /// Logout
  Future<ApiResponse<bool>> logout() async {
    final response = await _apiService.post<bool>(ApiConstants.logoutEndpoint);

    return response.fold(
      (data) {
        _clearToken();
        _apiService.clearAuthToken();
        return ApiResponse.success(data: data);
      },
      (error) {
        // Even if logout fails, clear local token
        _clearToken();
        _apiService.clearAuthToken();
        return ApiResponse.failure(message: error);
      },
    );
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
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
    );
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

    // If we have an avatar file, we need to use file upload
    if (avatarFile != null) {
      try {
        final response = await _apiService
            .customFileUpload<Map<String, dynamic>>(
              endpoint: ApiConstants.userProfileUpdateEndpoint,
              filePath: avatarFile.path,
              method: 'PUT', // Use PUT method for profile updates
              fieldName: 'avatar',
              data: formData,
            );

        return response.fold(
          (data) => ApiResponse.success(data: data),
          (error) => ApiResponse.failure(message: error),
        );
      } catch (e) {
        return ApiResponse.failure(
          message: 'Error uploading file: ${e.toString()}',
          statusCode: 500,
        );
      }
    } else if (formData.isNotEmpty) {
      // If we only have text fields, use regular PUT
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiConstants.userProfileUpdateEndpoint,
        data: formData,
      );

      return response.fold(
        (data) => ApiResponse.success(data: data),
        (error) => ApiResponse.failure(message: error),
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
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.userProfileEndpoint,
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
    );
  }

  /// Get user profile by ID
  Future<ApiResponse<Map<String, dynamic>>> getUserById(String userId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/api/auth/user/$userId',
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
    );
  }

  /// Update user profile
  Future<ApiResponse<Map<String, dynamic>>> updateUserProfile(
    Map<String, dynamic> userData,
  ) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      ApiConstants.userProfileEndpoint,
      data: userData,
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
    );
  }

  /// Upload profile picture
  Future<ApiResponse<Map<String, dynamic>>> uploadProfilePicture(
    File imageFile,
  ) async {
    final response = await _apiService.customFileUpload<Map<String, dynamic>>(
      endpoint: '${ApiConstants.userProfileEndpoint}/picture',
      filePath: imageFile.path,
      method: 'PUT', // Use PUT method for profile picture uploads
      fieldName: 'profile_picture',
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
    );
  }

  /// Delete user account
  Future<ApiResponse<bool>> deleteAccount() async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiConstants.userProfileEndpoint,
    );

    return response.fold((data) {
      // Check if the response indicates success
      final success = data['success'] as bool? ?? false;
      return ApiResponse.success(data: success);
    }, (error) => ApiResponse.failure(message: error));
  }

  /// Follow a user
  Future<ApiResponse<Map<String, dynamic>>> followUser(String userId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/api/followers/follow/$userId',
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
    );
  }

  /// Unfollow a user
  Future<ApiResponse<Map<String, dynamic>>> unfollowUser(String userId) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      '/api/followers/follow/$userId',
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
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

    final response = await _apiService.uploadFile<Map<String, dynamic>>(
      customEndpoint ?? ApiConstants.uploadFileEndpoint,
      file.path,
      fieldName: fieldName,
      data: additionalFields,
      onSendProgress: onProgress,
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
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

    final filePaths = files.map((file) => file.path).toList();
    final response = await _apiService
        .uploadMultipleFiles<Map<String, dynamic>>(
          customEndpoint ?? ApiConstants.uploadFileEndpoint,
          filePaths,
          fieldName: fieldName,
          data: additionalFields,
          onSendProgress: onProgress,
        );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
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
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _apiService.get<T>(
      endpoint,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
    );
  }

  /// Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _apiService.post<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
    );
  }

  /// Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _apiService.put<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
    );
  }

  /// Generic PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _apiService.patch<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
    );
  }

  /// Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _apiService.delete<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
    );
  }

  /// Download file
  Future<ApiResponse<String>> downloadFile(
    String endpoint,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onProgress,
  }) async {
    final response = await _apiService.downloadFile(
      endpoint,
      savePath,
      queryParameters: queryParameters,
      onReceiveProgress: onProgress,
    );

    return response.fold(
      (data) => ApiResponse.success(data: data),
      (error) => ApiResponse.failure(message: error),
    );
  }
}
