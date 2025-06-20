import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_djlive/core/network/api_constants.dart';

/// Authentication interceptor for handling JWT tokens
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for certain endpoints
    if (_shouldSkipAuth(options.path)) {
      return handler.next(options);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConstants.authTokenKey);

      if (token != null && token.isNotEmpty) {
        options.headers[ApiConstants.authHeader] = 'Bearer $token';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding auth token: $e');
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 unauthorized errors
    if (err.response?.statusCode == 401) {
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the original request
          final response = await _retryRequest(err.requestOptions);
          return handler.resolve(response);
        } else {
          // Refresh failed, redirect to login
          await _clearTokens();
          // You can emit a logout event here or navigate to login
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error handling 401: $e');
        }
      }
    }

    handler.next(err);
  }

  /// Check if authentication should be skipped for this endpoint
  bool _shouldSkipAuth(String path) {
    final skipAuthPaths = [
      ApiConstants.login,
      ApiConstants.register,
      ApiConstants.forgotPassword,
      ApiConstants.resetPassword,
      ApiConstants.refreshToken,
      ApiConstants.version,
      ApiConstants.health,
    ];

    return skipAuthPaths.any((skipPath) => path.contains(skipPath));
  }

  /// Attempt to refresh the authentication token
  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(ApiConstants.refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final newToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newToken != null) {
          await prefs.setString(ApiConstants.authTokenKey, newToken);
          if (newRefreshToken != null) {
            await prefs.setString(
              ApiConstants.refreshTokenKey,
              newRefreshToken,
            );
          }
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Token refresh failed: $e');
      }
    }

    return false;
  }

  /// Retry the original request with new token
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConstants.authTokenKey);

    if (token != null) {
      requestOptions.headers[ApiConstants.authHeader] = 'Bearer $token';
    }

    final dio = Dio();
    return dio.fetch(requestOptions);
  }

  /// Clear stored tokens
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.authTokenKey);
    await prefs.remove(ApiConstants.refreshTokenKey);
  }
}

/// Logging interceptor for debugging API calls
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
      print('Headers: ${options.headers}');
      if (options.queryParameters.isNotEmpty) {
        print('Query Parameters: ${options.queryParameters}');
      }
      if (options.data != null) {
        print('Data: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print(
        '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      );
      print('Data: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print(
        '❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
      );
      print('Message: ${err.message}');
      if (err.response != null) {
        print('Response Data: ${err.response?.data}');
      }
    }
    handler.next(err);
  }
}

/// Retry interceptor for handling network failures
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration delay;

  RetryInterceptor({
    this.maxRetries = 3,
    this.delay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) && err.requestOptions.extra['retryCount'] == null) {
      err.requestOptions.extra['retryCount'] = 0;
    }

    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    if (retryCount < maxRetries && _shouldRetry(err)) {
      err.requestOptions.extra['retryCount'] = retryCount + 1;

      if (kDebugMode) {
        print(
          '🔄 Retrying request (${retryCount + 1}/$maxRetries): ${err.requestOptions.path}',
        );
      }

      await Future.delayed(delay * (retryCount + 1));

      try {
        final response = await Dio().fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(
          DioException(requestOptions: err.requestOptions, error: e),
        );
      }
    }

    handler.next(err);
  }

  /// Determine if the request should be retried
  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}

/// Cache interceptor for caching GET requests
class CacheInterceptor extends Interceptor {
  final Map<String, CacheItem> _cache = {};
  final Duration defaultCacheDuration;

  CacheInterceptor({this.defaultCacheDuration = const Duration(minutes: 5)});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() == 'GET' && _shouldCache(options)) {
      final cacheKey = _generateCacheKey(options);
      final cachedItem = _cache[cacheKey];

      if (cachedItem != null && !cachedItem.isExpired) {
        if (kDebugMode) {
          print('📦 Returning cached response for: ${options.path}');
        }

        return handler.resolve(
          Response(
            requestOptions: options,
            data: cachedItem.data,
            statusCode: 200,
            headers: Headers.fromMap({
              'x-cached': ['true'],
            }),
          ),
        );
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        _shouldCache(response.requestOptions) &&
        response.statusCode == 200) {
      final cacheKey = _generateCacheKey(response.requestOptions);
      _cache[cacheKey] = CacheItem(
        data: response.data,
        expiry: DateTime.now().add(defaultCacheDuration),
      );

      if (kDebugMode) {
        print('💾 Cached response for: ${response.requestOptions.path}');
      }
    }

    handler.next(response);
  }

  /// Check if the request should be cached
  bool _shouldCache(RequestOptions options) {
    final cachePaths = [
      ApiConstants.profile,
      ApiConstants.getStreams,
      ApiConstants.getCategories,
      ApiConstants.getTrendingStreams,
    ];

    return cachePaths.any((path) => options.path.contains(path));
  }

  /// Generate cache key from request options
  String _generateCacheKey(RequestOptions options) {
    final uri = Uri(
      path: options.path,
      queryParameters: options.queryParameters.isNotEmpty
          ? options.queryParameters.map((k, v) => MapEntry(k, v.toString()))
          : null,
    );
    return uri.toString();
  }

  /// Clear all cached items
  void clearCache() {
    _cache.clear();
  }

  /// Clear expired cache items
  void clearExpiredCache() {
    _cache.removeWhere((_, item) => item.isExpired);
  }
}

/// Cache item model
class CacheItem {
  final dynamic data;
  final DateTime expiry;

  CacheItem({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}
