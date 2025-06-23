import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../network/api_service.dart';
import '../network/api_result.dart';
import 'simple_auth_service.dart';

class PostCreationService {
  final ApiService _apiService;
  final AuthService _authService;

  PostCreationService(this._apiService, this._authService);

  /// Creates a new post with optional image
  ///
  /// [postCaption] - The text content of the post
  /// [mediaFile] - Optional image/video file to upload
  ///
  /// Returns ApiResult with the created post data
  Future<ApiResult<Map<String, dynamic>>> createPost({
    String? postCaption,
    File? mediaFile,
  }) async {
    try {
      // Validate that at least one field is provided
      if ((postCaption == null || postCaption.trim().isEmpty) &&
          mediaFile == null) {
        return ApiResult.failure('At least caption or media file is required');
      }

      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Prepare form data
      final formData = FormData();

      // Add caption if provided
      if (postCaption != null && postCaption.trim().isNotEmpty) {
        formData.fields.add(MapEntry('postCaption', postCaption.trim()));
      }

      // Add media file if provided
      if (mediaFile != null) {
        final fileName = mediaFile.path.split('/').last;
        final mimeType = _getMimeType(fileName);

        formData.files.add(
          MapEntry(
            'media',
            await MultipartFile.fromFile(
              mediaFile.path,
              filename: fileName,
              contentType: MediaType.parse(mimeType),
            ),
          ),
        );
      }

      // Make API request
      final response = await _apiService.dio.post(
        '/api/posts/create',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
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
          return ApiResult.failure(data['message'] ?? 'Failed to create post');
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

  /// Determines MIME type based on file extension
  String _getMimeType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
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
        } else if (statusCode == 413) {
          return ApiResult.failure(
            'File too large. Please choose a smaller file.',
          );
        } else if (statusCode == 415) {
          return ApiResult.failure('Unsupported file type.');
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
