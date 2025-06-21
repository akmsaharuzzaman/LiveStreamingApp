import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dlstarlive/core/network/api_service.dart';
import 'package:dlstarlive/core/network/api_result.dart';
import 'package:dlstarlive/core/network/api_constants.dart';

/// Example repository showing how to use ApiService
class StreamRepository {
  final ApiService _apiService = ApiService.instance;

  /// Get all streams
  Future<ApiResult<List<Stream>>> getStreams({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    return await _apiService.get<List<Stream>>(
      ApiConstants.getStreams,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
      },
      fromJson: (data) {
        final streams = (data['streams'] as List)
            .map((json) => Stream.fromJson(json))
            .toList();
        return streams;
      },
    );
  }

  /// Create a new stream
  Future<ApiResult<Stream>> createStream({
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
      return await _apiService.uploadWithData<Stream>(
        ApiConstants.createStream,
        fields: data,
        files: [
          await MultipartFile.fromFile(
            thumbnailPath,
            filename: 'thumbnail.jpg',
          ),
        ],
        fromJson: (responseData) => Stream.fromJson(responseData['stream']),
      );
    } else {
      // Regular POST request
      return await _apiService.post<Stream>(
        ApiConstants.createStream,
        data: data,
        fromJson: (responseData) => Stream.fromJson(responseData['stream']),
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
  Future<ApiResult<Comment>> sendComment({
    required String streamId,
    required String message,
  }) async {
    return await _apiService.post<Comment>(
      ApiConstants.sendComment,
      data: {'stream_id': streamId, 'message': message},
      fromJson: (data) => Comment.fromJson(data['comment']),
    );
  }

  /// Like a stream
  Future<ApiResult<bool>> likeStream(String streamId) async {
    return await _apiService.post<bool>(
      '${ApiConstants.likeStream}/$streamId',
      fromJson: (data) => data['liked'] as bool,
    );
  }

  /// Get stream statistics
  Future<ApiResult<StreamStats>> getStreamStats(String streamId) async {
    return await _apiService.get<StreamStats>(
      '${ApiConstants.streamStats}/$streamId',
      fromJson: (data) => StreamStats.fromJson(data['stats']),
    );
  }
}

/// Example user repository
class UserRepository {
  final ApiService _apiService = ApiService.instance;

  /// Login user
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

  /// Register user
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

  /// Get user profile
  Future<ApiResult<UserProfile>> getProfile() async {
    return await _apiService.get<UserProfile>(
      ApiConstants.profile,
      fromJson: (data) => UserProfile.fromJson(data['user']),
    );
  }

  /// Update user profile
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

  /// Upload avatar only
  Future<ApiResult<String>> uploadAvatar(String imagePath) async {
    return await _apiService.uploadFile<String>(
      ApiConstants.uploadAvatar,
      imagePath,
      fieldName: 'avatar',
      fromJson: (data) => data['avatar_url'] as String,
    );
  }

  /// Follow user
  Future<ApiResult<bool>> followUser(String userId) async {
    return await _apiService.post<bool>(
      ApiConstants.followUser,
      data: {'user_id': userId},
      fromJson: (data) => data['following'] as bool,
    );
  }

  /// Get followers
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

/// Example media repository
class MediaRepository {
  final ApiService _apiService = ApiService.instance;

  /// Upload video
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

  /// Upload multiple images
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

  /// Download media file
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

  /// Compress video
  Future<ApiResult<String>> compressVideo({
    required String videoPath,
    String quality = 'medium',
  }) async {
    return await _apiService.uploadWithData<String>(
      ApiConstants.compressVideo,
      files: [await MultipartFile.fromFile(videoPath, filename: 'video.mp4')],
      fields: {'quality': quality},
      fromJson: (data) => data['compressed_url'] as String,
    );
  }
}

/// Example usage in BLoC
class StreamBloc extends Bloc<StreamEvent, StreamState> {
  final StreamRepository _streamRepository;

  StreamBloc(this._streamRepository) : super(StreamInitial()) {
    on<LoadStreamsEvent>(_onLoadStreams);
    on<CreateStreamEvent>(_onCreateStream);
  }

  Future<void> _onLoadStreams(
    LoadStreamsEvent event,
    Emitter<StreamState> emit,
  ) async {
    emit(StreamLoading());

    final result = await _streamRepository.getStreams(
      page: event.page,
      category: event.category,
    );

    result.fold(
      (streams) => emit(StreamLoaded(streams)),
      (error) => emit(StreamError(error)),
    );
  }

  Future<void> _onCreateStream(
    CreateStreamEvent event,
    Emitter<StreamState> emit,
  ) async {
    emit(StreamCreating());

    final result = await _streamRepository.createStream(
      title: event.title,
      description: event.description,
      category: event.category,
      thumbnailPath: event.thumbnailPath,
    );

    result.fold(
      (stream) => emit(StreamCreated(stream)),
      (error) => emit(StreamError(error)),
    );
  }
}

// Example model classes (you'll need to create these)
class Stream {
  final String id;
  final String title;
  final String description;

  Stream({required this.id, required this.title, required this.description});

  factory Stream.fromJson(Map<String, dynamic> json) {
    return Stream(
      id: json['id'],
      title: json['title'],
      description: json['description'],
    );
  }
}

class Comment {
  final String id;
  final String message;
  final String userId;

  Comment({required this.id, required this.message, required this.userId});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      message: json['message'],
      userId: json['user_id'],
    );
  }
}

class StreamStats {
  final int viewers;
  final int likes;
  final int comments;

  StreamStats({
    required this.viewers,
    required this.likes,
    required this.comments,
  });

  factory StreamStats.fromJson(Map<String, dynamic> json) {
    return StreamStats(
      viewers: json['viewers'],
      likes: json['likes'],
      comments: json['comments'],
    );
  }
}

class AuthResponse {
  final String token;
  final UserProfile user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      user: UserProfile.fromJson(json['user']),
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }
}

class MediaUploadResponse {
  final String url;
  final String mediaId;

  MediaUploadResponse({required this.url, required this.mediaId});

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaUploadResponse(url: json['url'], mediaId: json['media_id']);
  }
}

// Example events and states for BLoC
abstract class StreamEvent {}

class LoadStreamsEvent extends StreamEvent {
  final int page;
  final String? category;

  LoadStreamsEvent({required this.page, this.category});
}

class CreateStreamEvent extends StreamEvent {
  final String title;
  final String description;
  final String? category;
  final String? thumbnailPath;

  CreateStreamEvent({
    required this.title,
    required this.description,
    this.category,
    this.thumbnailPath,
  });
}

abstract class StreamState {}

class StreamInitial extends StreamState {}

class StreamLoading extends StreamState {}

class StreamCreating extends StreamState {}

class StreamLoaded extends StreamState {
  final List<Stream> streams;
  StreamLoaded(this.streams);
}

class StreamCreated extends StreamState {
  final Stream stream;
  StreamCreated(this.stream);
}

class StreamError extends StreamState {
  final String message;
  StreamError(this.message);
}
