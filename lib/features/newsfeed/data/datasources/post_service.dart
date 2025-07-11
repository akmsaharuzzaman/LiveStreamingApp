import 'dart:io';
import 'package:dlstarlive/core/network/api_service.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/auth/i_auth_service.dart';

class PostService {
  final ApiService _apiService;
  final IAuthService _authService;

  PostService(this._apiService, this._authService);

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

  /// Deletes a post by ID
  ///
  /// [postId] - The ID of the post to delete
  ///
  /// Returns ApiResult with deletion status
  Future<ApiResult<Map<String, dynamic>>> deletePost(String postId) async {
    try {
      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Make API request using DELETE method
      final response = await _apiService.dio.delete(
        '/api/posts/delete/$postId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final data = response.data;
        if (data['success'] == true) {
          return ApiResult.success(data);
        } else {
          return ApiResult.failure(data['message'] ?? 'Failed to delete post');
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

  /// Reacts to a post (like/unlike)
  ///
  /// [postId] - The ID of the post to react to
  /// [reactionType] - The type of reaction (like, love, etc.)
  ///
  /// Returns ApiResult with reaction status
  Future<ApiResult<Map<String, dynamic>>> reactToPost({
    required String postId,
    String reactionType = 'like',
  }) async {
    try {
      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Make API request
      final response = await _apiService.dio.post(
        '/api/posts/react/',
        data: {'postId': postId, 'reaction_type': reactionType},
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
            data['message'] ?? 'Failed to react to post',
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

  /// Creates a comment on a post
  ///
  /// [postId] - The ID of the post to comment on
  /// [commentText] - The text content of the comment
  ///
  /// Returns ApiResult with created comment data
  Future<ApiResult<Map<String, dynamic>>> createComment({
    required String postId,
    required String commentText,
  }) async {
    try {
      // Validate input
      if (commentText.trim().isEmpty) {
        return ApiResult.failure('Comment text cannot be empty');
      }

      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Make API request
      final response = await _apiService.dio.post(
        '/api/posts/comment/',
        data: {'postId': postId, 'commentText': commentText.trim()},
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
            data['message'] ?? 'Failed to create comment',
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

  /// Creates a reply to a comment
  ///
  /// [postId] - The ID of the post
  /// [commentId] - The ID of the parent comment
  /// [commentText] - The text content of the reply
  ///
  /// Returns ApiResult with created reply data
  Future<ApiResult<Map<String, dynamic>>> replyToComment({
    required String postId,
    required String commentId,
    required String commentText,
  }) async {
    try {
      // Validate input
      if (commentText.trim().isEmpty) {
        return ApiResult.failure('Reply text cannot be empty');
      }

      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Make API request
      final response = await _apiService.dio.post(
        '/api/posts/comment/reply',
        data: {
          'postId': postId,
          'commentId': commentId,
          'commentText': commentText.trim(),
        },
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
          return ApiResult.failure(data['message'] ?? 'Failed to create reply');
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

  /// Deletes a comment
  ///
  /// [postId] - The ID of the post containing the comment
  /// [commentId] - The ID of the comment to delete
  ///
  /// Returns ApiResult with deletion status
  Future<ApiResult<Map<String, dynamic>>> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Make API request using the correct endpoint format
      final response = await _apiService.dio.delete(
        '/api/posts/$postId/comment/delete/$commentId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final data = response.data;
        if (data['success'] == true) {
          return ApiResult.success(data);
        } else {
          return ApiResult.failure(
            data['message'] ?? 'Failed to delete comment',
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

  /// Edits a comment
  ///
  /// [commentId] - The ID of the comment to edit
  /// [newCommentText] - The new text content of the comment
  ///
  /// Returns ApiResult with updated comment data
  Future<ApiResult<Map<String, dynamic>>> editComment({
    required String commentId,
    required String newCommentText,
  }) async {
    try {
      // Validate input
      if (newCommentText.trim().isEmpty) {
        return ApiResult.failure('Comment text cannot be empty');
      }

      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Make API request using PUT method
      final response = await _apiService.dio.put(
        '/api/posts/comment/edit',
        data: {'commentId': commentId, 'newCommentText': newCommentText.trim()},
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
          return ApiResult.failure(data['message'] ?? 'Failed to edit comment');
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

  /// Reacts to a comment (like/unlike)
  ///
  /// [commentId] - The ID of the comment to react to
  /// [reactionType] - The type of reaction (like, love, etc.)
  ///
  /// Returns ApiResult with reaction status
  Future<ApiResult<Map<String, dynamic>>> reactToComment({
    required String commentId,
    String reactionType = 'like',
  }) async {
    try {
      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Make API request
      final response = await _apiService.dio.post(
        '/api/posts/comment/react',
        data: {'commentId': commentId, 'reaction_type': reactionType},
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
            data['message'] ?? 'Failed to react to comment',
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

  /// Gets all comments for a post
  ///
  /// [postId] - The ID of the post to get comments for
  /// [page] - Page number for pagination (default: 1)
  /// [limit] - Number of comments per page (default: 5)
  ///
  /// Returns ApiResult with comments data
  Future<ApiResult<Map<String, dynamic>>> getPostComments({
    required String postId,
    int page = 1,
    int limit = 5,
  }) async {
    try {
      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Make API request with correct endpoint format
      final response = await _apiService.dio.get(
        '/api/posts/$postId/comments',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final data = response.data;
        if (data['success'] == true) {
          return ApiResult.success(data);
        } else {
          return ApiResult.failure(data['message'] ?? 'Failed to get comments');
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

  /// Gets all stories with pagination
  ///
  /// [page] - Page number for pagination (default: 1)
  /// [limit] - Number of stories per page (default: 10)
  ///
  /// Returns ApiResult with stories data
  Future<ApiResult<Map<String, dynamic>>> getAllStories({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Make API request
      final response = await _apiService.dio.get(
        '/api/stories/',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final data = response.data;
        if (data['success'] == true) {
          return ApiResult.success(data);
        } else {
          return ApiResult.failure(data['message'] ?? 'Failed to get stories');
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

  /// Reacts to a story (like/unlike)
  ///
  /// [storyId] - The ID of the story to react to
  /// [reactionType] - The type of reaction (like, love, haha, etc.)
  ///
  /// Returns ApiResult with reaction status
  Future<ApiResult<Map<String, dynamic>>> reactToStory({
    required String storyId,
    String reactionType = 'like',
  }) async {
    try {
      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Make API request
      final response = await _apiService.dio.post(
        '/api/stories/react/',
        data: {'storyId': storyId, 'reaction_type': reactionType},
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
            data['message'] ?? 'Failed to react to story',
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

  /// Creates a new story with media file
  ///
  /// [mediaFile] - Image or video file to upload as story
  ///
  /// Returns ApiResult with the created story data
  Future<ApiResult<Map<String, dynamic>>> createStory({
    required File mediaFile,
  }) async {
    try {
      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Prepare form data
      final formData = FormData();
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

      // Make API request
      final response = await _apiService.dio.post(
        '/api/stories/create',
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
          return ApiResult.failure(data['message'] ?? 'Failed to create story');
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

  /// Deletes a story by ID
  ///
  /// [storyId] - The ID of the story to delete
  ///
  /// Returns ApiResult with deletion status
  Future<ApiResult<Map<String, dynamic>>> deleteStory(String storyId) async {
    try {
      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResult.failure('Authentication required');
      }

      // Make API request using DELETE method
      final response = await _apiService.dio.delete(
        '/api/stories/delete/$storyId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final data = response.data;
        if (data['success'] == true) {
          return ApiResult.success(data);
        } else {
          return ApiResult.failure(data['message'] ?? 'Failed to delete story');
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
