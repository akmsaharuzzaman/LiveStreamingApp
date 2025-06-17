/// API constants for the live streaming application
class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://api.yourlivestream.com/api/v1';
  static const String authBaseUrl = 'https://api.yourlivestream.com/auth';
  static const String streamingBaseUrl =
      'https://api.yourlivestream.com/streaming';
  static const String mediaBaseUrl = 'https://media.yourlivestream.com';

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
  static const String networkError = 'Network connection failed';
  static const String timeoutError = 'Request timeout';
  static const String serverError = 'Server error occurred';
  static const String unauthorizedError = 'Unauthorized access';
  static const String forbiddenError = 'Access forbidden';
  static const String notFoundError = 'Resource not found';
  static const String validationError = 'Validation failed';
  static const String unknownError = 'Unknown error occurred';
}
