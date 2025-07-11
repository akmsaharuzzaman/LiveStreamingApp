/// Abstract interface for authentication services
abstract class IAuthService {
  /// Get the stored authentication token
  Future<String?> getToken();

  /// Store the authentication token
  Future<void> setToken(String token);

  /// Remove the authentication token
  Future<void> removeToken();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
