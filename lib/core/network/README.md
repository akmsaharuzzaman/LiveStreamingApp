# 🚀 API Service for Flutter Live Streaming App

A comprehensive, production-ready API service built with **Dio** for Flutter applications following **Clean Architecture** principles.

## 📁 Files Structure

```
lib/core/network/
├── api_service.dart           # Main API service class
├── api_constants.dart         # API endpoints and constants
├── api_result.dart           # Result wrapper for API responses
├── api_interceptors.dart     # Request/response interceptors
├── network_exceptions.dart   # Error handling utilities
└── api_usage_examples_clean.dart # Usage examples and patterns
```

## ✨ Features

- **Complete HTTP Operations**: GET, POST, PUT, PATCH, DELETE
- **File Uploads**: Single file, multiple files, with progress tracking
- **File Downloads**: With progress callbacks
- **Automatic Token Management**: JWT token refresh and retry
- **Error Handling**: Comprehensive error handling and user-friendly messages
- **Request Caching**: Cache GET requests to improve performance
- **Retry Logic**: Automatic retry for failed requests
- **Logging**: Debug logging for development
- **Type Safety**: Generic types for type-safe API calls

## 🎯 Quick Start

### 1. Basic Setup

```dart
// The API service is a singleton
final apiService = ApiService.instance;

// Set authentication token
apiService.setAuthToken('your_jwt_token_here');
```

### 2. Simple GET Request

```dart
// Get streams with query parameters
final result = await apiService.get<List<StreamModel>>(
  '/streams',
  queryParameters: {'page': 1, 'limit': 20},
  fromJson: (data) => (data['streams'] as List)
      .map((json) => StreamModel.fromJson(json))
      .toList(),
);

// Handle the result
result.fold(
  (streams) => print('Got ${streams.length} streams'),
  (error) => print('Error: $error'),
);
```

### 3. POST Request with Data

```dart
// Create a new stream
final result = await apiService.post<StreamModel>(
  '/streams',
  data: {
    'title': 'My Live Stream',
    'description': 'Amazing content!',
    'category': 'gaming',
  },
  fromJson: (data) => StreamModel.fromJson(data['stream']),
);
```

### 4. File Upload

```dart
// Upload avatar image
final result = await apiService.uploadFile<String>(
  '/user/avatar',
  '/path/to/image.jpg',
  fieldName: 'avatar',
  fromJson: (data) => data['avatar_url'],
);
```

### 5. Multiple File Upload

```dart
// Upload multiple images
final result = await apiService.uploadMultipleFiles<List<String>>(
  '/media/images',
  ['/path/to/image1.jpg', '/path/to/image2.jpg'],
  fromJson: (data) => (data['urls'] as List).cast<String>(),
);
```

### 6. File Upload with Additional Data

```dart
// Upload video with metadata
final result = await apiService.uploadWithData<MediaResponse>(
  '/media/video',
  files: [
    await MultipartFile.fromFile('/path/to/video.mp4'),
  ],
  fields: {
    'title': 'My Video',
    'description': 'Great content',
    'category': 'entertainment',
  },
  onSendProgress: (sent, total) {
    print('Upload progress: ${(sent / total * 100).toStringAsFixed(1)}%');
  },
  fromJson: (data) => MediaResponse.fromJson(data),
);
```

## 🏗️ Repository Pattern Usage

### Create Repository

```dart
class StreamRepository {
  final ApiService _apiService = ApiService.instance;
  
  Future<ApiResult<List<StreamModel>>> getStreams({
    int page = 1,
    String? category,
  }) async {
    return await _apiService.get<List<StreamModel>>(
      ApiConstants.getStreams,
      queryParameters: {
        'page': page,
        if (category != null) 'category': category,
      },
      fromJson: (data) => (data['streams'] as List)
          .map((json) => StreamModel.fromJson(json))
          .toList(),
    );
  }
  
  Future<ApiResult<StreamModel>> createStream({
    required String title,
    required String description,
    String? thumbnailPath,
  }) async {
    if (thumbnailPath != null) {
      return await _apiService.uploadWithData<StreamModel>(
        ApiConstants.createStream,
        fields: {'title': title, 'description': description},
        files: [await MultipartFile.fromFile(thumbnailPath)],
        fromJson: (data) => StreamModel.fromJson(data['stream']),
      );
    }
    
    return await _apiService.post<StreamModel>(
      ApiConstants.createStream,
      data: {'title': title, 'description': description},
      fromJson: (data) => StreamModel.fromJson(data['stream']),
    );
  }
}
```

### Use in BLoC

```dart
class StreamBloc extends Bloc<StreamEvent, StreamState> {
  final StreamRepository _repository;
  
  StreamBloc(this._repository) : super(StreamInitial()) {
    on<LoadStreamsEvent>(_onLoadStreams);
  }
  
  Future<void> _onLoadStreams(
    LoadStreamsEvent event,
    Emitter<StreamState> emit,
  ) async {
    emit(StreamLoading());
    
    final result = await _repository.getStreams(page: event.page);
    
    result.fold(
      (streams) => emit(StreamLoaded(streams)),
      (error) => emit(StreamError(error)),
    );
  }
}
```

## 🔧 Configuration

### Update Base URL

```dart
// In api_constants.dart, change:
static const String baseUrl = 'https://your-api.com/api/v1';
```

### Add Custom Headers

```dart
// In api_service.dart _setupDio() method:
_dio.options.headers.addAll({
  'X-API-Key': 'your-api-key',
  'Custom-Header': 'value',
});
```

### Configure Timeouts

```dart
// In api_service.dart _setupDio() method:
_dio.options = BaseOptions(
  baseUrl: ApiConstants.baseUrl,
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
  sendTimeout: Duration(seconds: 30),
);
```

## 🛡️ Error Handling

The API service provides comprehensive error handling:

```dart
final result = await apiService.get('/some-endpoint');

result.fold(
  (data) {
    // Success case
    print('Success: $data');
  },
  (error) {
    // Error case with user-friendly message
    print('Error: $error');
    
    // Show to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  },
);
```

## 📊 Built-in Features

### Automatic Token Refresh
- Automatically refreshes JWT tokens on 401 errors
- Retries failed requests with new token
- Redirects to login if refresh fails

### Request Caching
- Caches GET requests for better performance
- Configurable cache duration
- Automatic cache expiration

### Progress Tracking
```dart
await apiService.uploadFile(
  '/upload',
  filePath,
  onSendProgress: (sent, total) {
    final progress = (sent / total * 100).toStringAsFixed(1);
    print('Upload progress: $progress%');
  },
);
```

### Request Cancellation
```dart
final cancelToken = CancelToken();

// Start request
final future = apiService.get('/data', cancelToken: cancelToken);

// Cancel if needed
cancelToken.cancel('Request cancelled by user');
```

## 🔍 Debugging

Enable debug logging:

```dart
// Logs are automatically enabled in debug mode
// Check console for detailed request/response logs
```

## 🎯 Best Practices

1. **Use Repository Pattern**: Wrap API calls in repository classes
2. **Handle Errors Gracefully**: Always handle both success and error cases
3. **Use Type Safety**: Define proper models and use generic types
4. **Progress Feedback**: Show progress for file uploads/downloads
5. **Token Management**: Let the service handle token refresh automatically
6. **Caching**: Leverage built-in caching for better performance

## 📝 Examples

Check `api_usage_examples_clean.dart` for complete examples including:
- Repository implementations
- BLoC integration
- Widget usage
- Error handling patterns
- File upload/download examples

## 🚀 Ready to Use!

Your API service is now ready for production use with:
- ✅ Complete CRUD operations
- ✅ File upload/download
- ✅ Error handling
- ✅ Token management
- ✅ Caching
- ✅ Progress tracking
- ✅ Clean architecture support

Happy coding! 🎉
