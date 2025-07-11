import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Network exception handler
class NetworkExceptions {
  /// Handle different types of errors
  static String handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else {
      return 'Unknown error occurred: ${error.toString()}';
    }
  }

  /// Handle Dio specific errors
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';

      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';

      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';

      case DioExceptionType.badResponse:
        return _handleStatusCodeError(
          error.response?.statusCode,
          error.response?.data,
        );

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';

      case DioExceptionType.badCertificate:
        return 'Certificate verification failed.';
      case DioExceptionType.unknown:
        return 'Network error occurred. Please try again.';
    }
  }

  /// Handle HTTP status code errors
  static String _handleStatusCodeError(int? statusCode, dynamic responseData) {
    switch (statusCode) {
      case 400:
        return _extractErrorMessage(responseData) ??
            'Bad request. Please check your input.';

      case 401:
        return 'Unauthorized. Please login again.';

      case 403:
        return 'Access forbidden. You don\'t have permission to perform this action.';

      case 404:
        return 'Resource not found.';

      case 408:
        return 'Request timeout. Please try again.';

      case 409:
        return 'Conflict. The resource already exists or has been modified.';

      case 422:
        return _extractValidationErrors(responseData) ??
            'Validation failed. Please check your input.';

      case 429:
        return 'Too many requests. Please wait a moment and try again.';

      case 500:
        return 'Internal server error. Please try again later.';

      case 502:
        return 'Bad gateway. Server is temporarily unavailable.';

      case 503:
        return 'Service unavailable. Please try again later.';

      case 504:
        return 'Gateway timeout. Please try again.';

      default:
        if (statusCode != null && statusCode >= 500) {
          return 'Server error ($statusCode). Please try again later.';
        } else if (statusCode != null && statusCode >= 400) {
          return 'Client error ($statusCode). Please check your request.';
        } else {
          return 'Unexpected error occurred. Please try again.';
        }
    }
  }

  /// Extract error message from response data
  static String? _extractErrorMessage(dynamic responseData) {
    if (responseData == null) return null;

    try {
      if (responseData is Map<String, dynamic>) {
        // Common error message fields
        final commonFields = ['message', 'error', 'detail', 'description'];

        for (final field in commonFields) {
          if (responseData.containsKey(field) &&
              responseData[field] is String) {
            return responseData[field] as String;
          }
        }

        // Check for nested error object
        if (responseData.containsKey('error') && responseData['error'] is Map) {
          final errorObj = responseData['error'] as Map<String, dynamic>;
          for (final field in commonFields) {
            if (errorObj.containsKey(field) && errorObj[field] is String) {
              return errorObj[field] as String;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting error message: $e');
      }
    }

    return null;
  }

  /// Extract validation errors from response data
  static String? _extractValidationErrors(dynamic responseData) {
    if (responseData == null) return null;

    try {
      if (responseData is Map<String, dynamic>) {
        // Check for validation errors
        if (responseData.containsKey('errors') &&
            responseData['errors'] is Map) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          final errorMessages = <String>[];

          errors.forEach((field, messages) {
            if (messages is List) {
              for (final message in messages) {
                if (message is String) {
                  errorMessages.add('$field: $message');
                }
              }
            } else if (messages is String) {
              errorMessages.add('$field: $messages');
            }
          });

          if (errorMessages.isNotEmpty) {
            return errorMessages.join('\n');
          }
        }

        // Check for single validation error
        if (responseData.containsKey('validation_errors') &&
            responseData['validation_errors'] is List) {
          final errors = responseData['validation_errors'] as List;
          return errors.map((e) => e.toString()).join('\n');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting validation errors: $e');
      }
    }

    return _extractErrorMessage(responseData);
  }

  /// Create a default error message
  static String defaultError(String message) {
    return message;
  }

  /// Create a network error
  static String networkError() {
    return 'Network connection failed. Please check your internet connection.';
  }

  /// Create a timeout error
  static String timeoutError() {
    return 'Request timeout. Please try again.';
  }

  /// Create a server error
  static String serverError() {
    return 'Server error occurred. Please try again later.';
  }

  /// Create an unauthorized error
  static String unauthorizedError() {
    return 'Unauthorized access. Please login again.';
  }

  /// Create a forbidden error
  static String forbiddenError() {
    return 'Access forbidden. You don\'t have permission.';
  }

  /// Create a not found error
  static String notFoundError() {
    return 'Resource not found.';
  }

  /// Create a validation error
  static String validationError(String message) {
    return 'Validation failed: $message';
  }
}
