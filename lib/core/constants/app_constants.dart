class AppConstants {
  // Domain Layer - Business logic constants
  static const String appName = 'DLStar';
  static const String appVersion = '1.0.0';

  // Animation Durations (can be used across layers)
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}

// Data Layer Constants
class DataConstants {
  // API Constants
  // static const String baseUrl = 'https://b8eff8466e05.ngrok-free.app';
  static const String baseUrl = 'http://dlstarlive.com:8000';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
}

// API Layer Constants
class ApiConstants {
  // HTTP Methods
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String patch = 'PATCH';
  static const String delete = 'DELETE';

  // Content Types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormData = 'multipart/form-data';
  static const String contentTypeUrlEncoded =
      'application/x-www-form-urlencoded';

  // Headers
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String headerAuthorization = 'Authorization';
  static const String headerBearerPrefix = 'Bearer ';

  // Error Messages
  static const String networkError =
      'Network error. Please check your internet connection.';
  static const String timeoutError = 'Request timeout. Please try again.';
  static const String unauthorizedError = 'Unauthorized. Please login again.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'Something went wrong. Please try again.';

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
  static const List<String> allowedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'txt',
  ];
  static const List<String> allowedVideoTypes = ['mp4', 'mov', 'avi', 'mkv'];

  // API Endpoints (Example - replace with your actual endpoints)
  static const String registerGoogleAuthEndpoint = '/api/auth/register-google';
  static const String userProfileEndpoint = '/api/auth/my-profile';
  static const String userProfileUpdateEndpoint = '/api/auth/update-profile';
  //--------
  static const String authEndpoint = '/auth';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String googleAuthEndpoint = '/auth/google';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String uploadFileEndpoint = '/upload';
}

// Presentation Layer Constants
class UIConstants {
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Border Radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXL = 16.0;

  // Icon Paths
  static const String iconsPath = 'assets/icons/';
  static const String imagesPath = 'assets/images/';
  static const String logoImage = '${imagesPath}logo.png';

  // Image Icons and Logos
  //Placeholder images
  static const String placeholderImage = '${imagesPath}placeholder.png';

  // Logos
  static const String appLogo = '${logoImage}google_logo.svg';

  //Icons
  static const String homeIcon = '${iconsPath}home_icon.svg';
  static const String profileIcon = '${iconsPath}profile_icon.svg';
  static const String chatIcon = '${iconsPath}chat_icon.svg';
  static const String liveStreamIcon = '${iconsPath}live_stream_icon.svg';
  static const String newsfeedIcon = '${iconsPath}newsfeed_icon.svg';
}
