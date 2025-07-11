/// Generic wrapper for API responses
/// Handles both success and failure states
abstract class ApiResult<T> {
  const factory ApiResult.success(T data) = Success<T>;
  const factory ApiResult.failure(String error) = Failure<T>;

  /// Check if the result is successful
  bool get isSuccess;

  /// Check if the result is a failure
  bool get isFailure;

  /// Get data if success, null if failure
  T? get dataOrNull;

  /// Get error message if failure, null if success
  String? get errorOrNull;

  /// Transform success data to another type
  ApiResult<R> map<R>(R Function(T) transform);

  /// Transform success data to another ApiResult
  ApiResult<R> flatMap<R>(ApiResult<R> Function(T) transform);

  /// Execute action if success
  ApiResult<T> onSuccess(void Function(T) action);

  /// Execute action if failure
  ApiResult<T> onFailure(void Function(String) action);

  /// Get data or provide default value
  T getOrElse(T defaultValue);

  /// Get data or execute fallback function
  T getOrElseGet(T Function() fallback);

  /// Fold the result into a single value
  R fold<R>(R Function(T) onSuccess, R Function(String) onFailure);

  /// Pattern matching method
  R when<R>({
    required R Function(T) success,
    required R Function(String) failure,
  });
}

/// Success implementation
class Success<T> implements ApiResult<T> {
  final T data;

  const Success(this.data);

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  T? get dataOrNull => data;

  @override
  String? get errorOrNull => null;

  @override
  ApiResult<R> map<R>(R Function(T) transform) {
    return ApiResult.success(transform(data));
  }

  @override
  ApiResult<R> flatMap<R>(ApiResult<R> Function(T) transform) {
    return transform(data);
  }

  @override
  ApiResult<T> onSuccess(void Function(T) action) {
    action(data);
    return this;
  }

  @override
  ApiResult<T> onFailure(void Function(String) action) {
    return this;
  }

  @override
  T getOrElse(T defaultValue) => data;

  @override
  T getOrElseGet(T Function() fallback) => data;

  @override
  R fold<R>(R Function(T) onSuccess, R Function(String) onFailure) {
    return onSuccess(data);
  }

  @override
  R when<R>({
    required R Function(T) success,
    required R Function(String) failure,
  }) {
    return success(data);
  }

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Failure implementation
class Failure<T> implements ApiResult<T> {
  final String error;

  const Failure(this.error);

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  T? get dataOrNull => null;

  @override
  String? get errorOrNull => error;

  @override
  ApiResult<R> map<R>(R Function(T) transform) {
    return ApiResult.failure(error);
  }

  @override
  ApiResult<R> flatMap<R>(ApiResult<R> Function(T) transform) {
    return ApiResult.failure(error);
  }

  @override
  ApiResult<T> onSuccess(void Function(T) action) {
    return this;
  }

  @override
  ApiResult<T> onFailure(void Function(String) action) {
    action(error);
    return this;
  }

  @override
  T getOrElse(T defaultValue) => defaultValue;

  @override
  T getOrElseGet(T Function() fallback) => fallback();

  @override
  R fold<R>(R Function(T) onSuccess, R Function(String) onFailure) {
    return onFailure(error);
  }

  @override
  R when<R>({
    required R Function(T) success,
    required R Function(String) failure,
  }) {
    return failure(error);
  }

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}
