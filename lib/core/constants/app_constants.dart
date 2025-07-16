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
  static const String forbiddenError = 'Access forbidden';
  static const String notFoundError = 'Resource not found';
  static const String validationError = 'Validation failed';

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

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String socialLogin = '/auth/social-login';

  // User endpoints
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String uploadAvatar = '/user/avatar';
  static const String userSettings = '/user/settings';
  static const String followUser = '/user/follow';
  static const String unfollowUser = '/user/unfollow';
  static const String getFollowers = '/user/followers';
  static const String getFollowing = '/user/following';
  static const String blockUser = '/user/block';
  static const String reportUser = '/user/report';

  // Streaming endpoints
  static const String createStream = '/stream/create';
  static const String endStream = '/stream/end';
  static const String joinStream = '/stream/join';
  static const String leaveStream = '/stream/leave';
  static const String getStreams = '/stream/list';
  static const String getStreamDetails = '/stream/details';
  static const String streamStats = '/stream/stats';
  static const String streamComments = '/stream/comments';
  static const String sendComment = '/stream/comment';
  static const String deleteComment = '/stream/comment/delete';
  static const String likeStream = '/stream/like';
  static const String shareStream = '/stream/share';
  static const String reportStream = '/stream/report';

  // Media endpoints
  static const String uploadVideo = '/media/video/upload';
  static const String uploadImage = '/media/image/upload';
  static const String uploadThumbnail = '/media/thumbnail/upload';
  static const String getMediaUrl = '/media/url';
  static const String deleteMedia = '/media/delete';
  static const String compressVideo = '/media/video/compress';
  static const String generateThumbnail = '/media/thumbnail/generate';

  // Gift and monetization endpoints
  static const String sendGift = '/gift/send';
  static const String getGifts = '/gift/list';
  static const String purchaseCoins = '/payment/coins/purchase';
  static const String getWallet = '/wallet/balance';
  static const String withdrawEarnings = '/wallet/withdraw';
  static const String getTransactions = '/wallet/transactions';

  // Notification endpoints
  static const String getNotifications = '/notifications';
  static const String markNotificationRead = '/notifications/read';
  static const String updateFCMToken = '/notifications/fcm-token';
  static const String notificationSettings = '/notifications/settings';

  // Search and discovery endpoints
  static const String searchUsers = '/search/users';
  static const String searchStreams = '/search/streams';
  static const String getTrendingStreams = '/discover/trending';
  static const String getRecommendedStreams = '/discover/recommended';
  static const String getCategories = '/categories';
  static const String getStreamsByCategory = '/category/streams';

  // Admin endpoints
  static const String adminStats = '/admin/stats';
  static const String moderateContent = '/admin/moderate';
  static const String banUser = '/admin/ban';
  static const String unbanUser = '/admin/unban';

  // Version and health
  static const String version = '/version';
  static const String health = '/health';

  // Headers
  static const String authHeader = 'Authorization';
  static const String contentType = 'Content-Type';
  static const String accept = 'Accept';
  static const String userAgent = 'User-Agent';

  // Content types
  static const String jsonContentType = 'application/json';
  static const String formDataContentType = 'multipart/form-data';
  static const String urlEncodedContentType =
      'application/x-www-form-urlencoded';

  // Cache keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userProfileKey = 'user_profile';
  static const String appSettingsKey = 'app_settings';

  // Error messages

  //Feed endpoints
  static const String createPost = '/api/posts/create';
  static const String editPost = '/api/posts/edit';
  static String getAllPosts(int page, int limit) =>
      '/api/posts/?page=$page&limit=$limit';
  static String getUserPosts(String userId, int page, int limit) =>
      '/api/posts/user/$userId?page=$page&limit=$limit';
  static String deletePost(String postId) => '/api/posts/delete/$postId';
  static const String reactToPost = '/api/posts/react';
  static const String commentToPost = '/api/posts/comment';

  // Reels endpoints
  static String getReels(int page, int limit) =>
      '/api/reels/?page=$page&limit=$limit';
  static String getUserReels(String userId, int page, int limit) =>
      // '/api/reels/user/$userId?page=$page&limit=$limit';
      //! TODO: Update this endpoint to match your API
      '/api/reels/';
  static const String reactToReel = '/api/reels/react/';
  static const String commentOnReel = '/api/reels/comment/';
  static String shareReel(String reelId) => '/api/reels/$reelId/share';
  static const String createReel = '/api/reels/create';
  static String deleteReel(String reelId) => '/api/reels/delete/$reelId';

  // Reel comments endpoints
  static String getReelComments(String reelId, int page, int limit) =>
      '/api/reels/$reelId/comments?page=$page&limit=$limit';
  static const String editReelComment = '/api/reels/comment/edit';
  static String deleteReelComment(String reelId, String commentId) =>
      '/api/reels/$reelId/comment/delete/$commentId';
  static const String reactToReelComment = '/api/reels/comment/react';
  static const String replyToReelComment = '/api/reels/comment/reply';
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
