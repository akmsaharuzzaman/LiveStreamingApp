import 'package:dlstarlive/core/network_temp/api_result.dart';
import 'package:dlstarlive/core/network_temp/api_service.dart';
import 'package:dio/dio.dart';
import '../../../../core/auth/i_auth_service.dart';

/// Service for live streaming related API operations
class LiveStreamService {
  final ApiService _apiService;
  final IAuthService _authService;

  LiveStreamService(this._apiService, this._authService);

  /// Generates an Agora token for live streaming
  ///
  /// [channelName] - The channel name for the live stream (room ID)
  /// [uid] - The user ID for the stream
  ///
  /// Returns ApiResult with the generated token
  Future<ApiResult<Map<String, dynamic>>> generateAgoraToken({
    required String channelName,
    required String uid,
  }) async {
    try {
      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Make API request to generate Agora token
      final response = await _apiService.dio.post(
        '/api/auth/generate-token/',
        data: {'channelName': channelName, 'uid': uid},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final data = response.data;
        if (data['success'] == true) {
          return ApiResult.success(data);
        } else {
          return ApiResult.failure(
            data['message'] ?? 'Failed to generate Agora token',
          );
        }
      } else {
        return ApiResult.failure('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.failure('Unexpected error: $e');
    }
  }

  /// Handles Dio errors and converts them to user-friendly messages
  ApiResult<Map<String, dynamic>> _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiResult.failure('Connection timeout. Please try again.');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        if (statusCode == 400) {
          final message = data?['message'] ?? 'Invalid request';
          return ApiResult.failure(message);
        } else if (statusCode == 401) {
          return ApiResult.failure(
            'Authentication failed. Please log in again.',
          );
        } else {
          final message = data?['message'] ?? 'Server error occurred';
          return ApiResult.failure(message);
        }

      case DioExceptionType.cancel:
        return ApiResult.failure('Request was cancelled');

      case DioExceptionType.connectionError:
        return ApiResult.failure('No internet connection');

      default:
        return ApiResult.failure('Network error occurred');
    }
  }
}
