import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:streaming_djlive/core/network/api_service.dart';
import 'package:streaming_djlive/core/network/api_result.dart';
import 'package:streaming_djlive/core/network/api_constants.dart';

/// 🚀 COMPREHENSIVE API SERVICE USAGE EXAMPLES
///
/// This file demonstrates how to use the ApiService with clean architecture
/// patterns including repositories, BLoC integration, and error handling.
///
/// Example repository showing how to use ApiService for streaming operations
class StreamRepository {
  final ApiService _apiService = ApiService.instance;

  /// Get all streams with pagination and filtering
  Future<ApiResult<List<StreamModel>>> getStreams({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    return await _apiService.get<List<StreamModel>>(
      ApiConstants.getStreams,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
      },
      fromJson: (data) {
        final streams = (data['streams'] as List)
            .map((json) => StreamModel.fromJson(json))
            .toList();
        return streams;
      },
    );
  }

  /// Create a new stream with optional thumbnail
  Future<ApiResult<StreamModel>> createStream({
    required String title,
    required String description,
    String? category,
    String? thumbnailPath,
  }) async {
    final data = {
      'title': title,
      'description': description,
      if (category != null) 'category': category,
    };

    if (thumbnailPath != null) {
      // Upload with file
      return await _apiService.uploadWithData<StreamModel>(
        ApiConstants.createStream,
        fields: data,
        files: [
          await MultipartFile.fromFile(
            thumbnailPath,
            filename: 'thumbnail.jpg',
          ),
        ],
        fromJson: (responseData) =>
            StreamModel.fromJson(responseData['stream']),
      );
    } else {
      // Regular POST request
      return await _apiService.post<StreamModel>(
        ApiConstants.createStream,
        data: data,
        fromJson: (responseData) =>
            StreamModel.fromJson(responseData['stream']),
      );
    }
  }

  /// Join a stream
  Future<ApiResult<Map<String, dynamic>>> joinStream(String streamId) async {
    return await _apiService.post<Map<String, dynamic>>(
      '${ApiConstants.joinStream}/$streamId',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Send comment to stream
  Future<ApiResult<CommentModel>> sendComment({
    required String streamId,
    required String message,
  }) async {
    return await _apiService.post<CommentModel>(
      ApiConstants.sendComment,
      data: {'stream_id': streamId, 'message': message},
      fromJson: (data) => CommentModel.fromJson(data['comment']),
    );
  }

  /// Like a stream
  Future<ApiResult<bool>> likeStream(String streamId) async {
    return await _apiService.post<bool>(
      '${ApiConstants.likeStream}/$streamId',
      fromJson: (data) => data['liked'] as bool,
    );
  }

  /// Delete a stream
  Future<ApiResult<bool>> deleteStream(String streamId) async {
    return await _apiService.delete<bool>(
      '${ApiConstants.createStream}/$streamId',
      fromJson: (data) => data['deleted'] as bool,
    );
  }
}

/// Example user repository for authentication and profile management
class UserRepository {
  final ApiService _apiService = ApiService.instance;

  /// Login with email and password
  Future<ApiResult<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    return await _apiService.post<AuthResponse>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      fromJson: (data) => AuthResponse.fromJson(data),
    );
  }

  /// Social login (Google, Facebook, etc.)
  Future<ApiResult<AuthResponse>> socialLogin({
    required String provider,
    required String token,
  }) async {
    return await _apiService.post<AuthResponse>(
      ApiConstants.socialLogin,
      data: {'provider': provider, 'token': token},
      fromJson: (data) => AuthResponse.fromJson(data),
    );
  }

  /// Register new user
  Future<ApiResult<AuthResponse>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return await _apiService.post<AuthResponse>(
      ApiConstants.register,
      data: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      },
      fromJson: (data) => AuthResponse.fromJson(data),
    );
  }

  /// Update user profile with avatar upload
  Future<ApiResult<UserProfile>> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
    String? phone,
    String? avatarPath,
  }) async {
    final data = <String, dynamic>{};

    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (bio != null) data['bio'] = bio;
    if (phone != null) data['phone'] = phone;

    if (avatarPath != null) {
      // Upload with avatar file
      return await _apiService.uploadWithData<UserProfile>(
        ApiConstants.updateProfile,
        fields: data,
        files: [
          await MultipartFile.fromFile(avatarPath, filename: 'avatar.jpg'),
        ],
        fromJson: (responseData) => UserProfile.fromJson(responseData['user']),
      );
    } else {
      // Regular update
      return await _apiService.put<UserProfile>(
        ApiConstants.updateProfile,
        data: data,
        fromJson: (responseData) => UserProfile.fromJson(responseData['user']),
      );
    }
  }

  /// Get user followers with pagination
  Future<ApiResult<List<UserProfile>>> getFollowers({
    int page = 1,
    int limit = 20,
  }) async {
    return await _apiService.get<List<UserProfile>>(
      ApiConstants.getFollowers,
      queryParameters: {'page': page, 'limit': limit},
      fromJson: (data) {
        final followers = (data['followers'] as List)
            .map((json) => UserProfile.fromJson(json))
            .toList();
        return followers;
      },
    );
  }
}

/// Example media repository for file uploads and processing
class MediaRepository {
  final ApiService _apiService = ApiService.instance;

  /// Upload video with progress tracking
  Future<ApiResult<MediaUploadResponse>> uploadVideo(
    String videoPath, {
    String? title,
    String? description,
    void Function(int, int)? onProgress,
  }) async {
    return await _apiService.uploadWithData<MediaUploadResponse>(
      ApiConstants.uploadVideo,
      files: [await MultipartFile.fromFile(videoPath, filename: 'video.mp4')],
      fields: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      },
      onSendProgress: onProgress,
      fromJson: (data) => MediaUploadResponse.fromJson(data),
    );
  }

  /// Upload multiple images at once
  Future<ApiResult<List<String>>> uploadImages(List<String> imagePaths) async {
    return await _apiService.uploadMultipleFiles<List<String>>(
      ApiConstants.uploadImage,
      imagePaths,
      fieldName: 'images',
      fromJson: (data) {
        final urls = (data['image_urls'] as List)
            .map((url) => url.toString())
            .toList();
        return urls;
      },
    );
  }

  /// Download media file with progress
  Future<ApiResult<String>> downloadMedia(
    String mediaUrl,
    String savePath, {
    void Function(int, int)? onProgress,
  }) async {
    return await _apiService.downloadFile(
      mediaUrl,
      savePath,
      onReceiveProgress: onProgress,
    );
  }
}

/// 🎯 USAGE EXAMPLES WITH WIDGET INTEGRATION

/// Example service class that can be used in widgets
class LiveStreamingService {
  final StreamRepository _streamRepository = StreamRepository();
  final MediaRepository _mediaRepository = MediaRepository();

  /// Start a live stream
  Future<ApiResult<StreamModel>> startLiveStream({
    required String title,
    required String description,
    String? thumbnailPath,
  }) async {
    return await _streamRepository.createStream(
      title: title,
      description: description,
      thumbnailPath: thumbnailPath,
    );
  }

  /// Get trending streams
  Future<ApiResult<List<StreamModel>>> getTrendingStreams() async {
    return await _streamRepository.getStreams(
      page: 1,
      limit: 10,
      category: 'trending',
    );
  }

  /// Upload and create stream with video
  Future<ApiResult<StreamModel>> createStreamWithVideo({
    required String title,
    required String description,
    required String videoPath,
    void Function(int, int)? onUploadProgress,
  }) async {
    // First upload the video
    final uploadResult = await _mediaRepository.uploadVideo(
      videoPath,
      title: title,
      description: description,
      onProgress: onUploadProgress,
    );
    // Check if upload was successful
    if (uploadResult.isSuccess) {
      // Upload successful, now create stream with uploaded video
      return await _streamRepository.createStream(
        title: title,
        description: description,
        thumbnailPath: null, // Use video thumbnail from upload
      );
    } else {
      // Return the upload error
      return ApiResult.failure(uploadResult.errorOrNull!);
    }
  }
}

/// 📱 WIDGET USAGE EXAMPLES

/// Example of using ApiService in a StatefulWidget
class StreamListWidget extends StatefulWidget {
  const StreamListWidget({super.key});

  @override
  StreamListWidgetState createState() => StreamListWidgetState();
}

class StreamListWidgetState extends State<StreamListWidget> {
  final LiveStreamingService _service = LiveStreamingService();
  List<StreamModel> _streams = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _service.getTrendingStreams();

    result.fold(
      (streams) {
        setState(() {
          _streams = streams;
          _isLoading = false;
        });
      },
      (error) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(onPressed: _loadStreams, child: Text('Retry')),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _streams.length,
      itemBuilder: (context, index) {
        final stream = _streams[index];
        return ListTile(
          title: Text(stream.title),
          subtitle: Text(stream.description),
          onTap: () => _joinStream(stream.id),
        );
      },
    );
  }

  Future<void> _joinStream(String streamId) async {
    final repository = StreamRepository();
    final result = await repository.joinStream(streamId);

    result.fold(
      (data) {
        // Handle successful join
        debugPrint('Joined stream successfully');
      },
      (error) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join stream: $error')),
        );
      },
    );
  }
}

/// 🎯 MODEL CLASSES (You'll need to implement these based on your API)

class StreamModel {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final int viewerCount;
  final bool isLive;

  StreamModel({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.viewerCount,
    required this.isLive,
  });

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    return StreamModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      viewerCount: json['viewer_count'] ?? 0,
      isLive: json['is_live'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'viewer_count': viewerCount,
      'is_live': isLive,
    };
  }
}

class CommentModel {
  final String id;
  final String message;
  final String userId;
  final String userName;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.message,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      message: json['message'],
      userId: json['user_id'],
      userName: json['user_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AuthResponse {
  final String token;
  final String refreshToken;
  final UserProfile user;

  AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['access_token'],
      refreshToken: json['refresh_token'],
      user: UserProfile.fromJson(json['user']),
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? bio;
  final int followerCount;
  final int followingCount;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.bio,
    required this.followerCount,
    required this.followingCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      followerCount: json['follower_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }
}

class MediaUploadResponse {
  final String url;
  final String mediaId;
  final String type;
  final int size;

  MediaUploadResponse({
    required this.url,
    required this.mediaId,
    required this.type,
    required this.size,
  });

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaUploadResponse(
      url: json['url'],
      mediaId: json['media_id'],
      type: json['type'],
      size: json['size'],
    );
  }
}
