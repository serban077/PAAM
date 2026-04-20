import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logging interceptor — active in debug builds only.
///
/// Prints request method + URI on send, status code on response, and the
/// message on error. Add to any Dio instance via `_dio.interceptors.add(AppLogInterceptor())`.
class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP] ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP] ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP ERROR] ${err.type.name}: ${err.message}');
    }
    handler.next(err);
  }
}

/// Thrown when [assertConnected] detects no active network interface.
///
/// Services catch this and surface a "No internet connection" message
/// immediately instead of waiting for the full Dio timeout.
class NetworkOfflineException implements Exception {
  const NetworkOfflineException();

  @override
  String toString() => 'No internet connection';
}

/// Checks connectivity and throws [NetworkOfflineException] when offline.
///
/// Call at the top of any external-API method so the caller receives an
/// immediate error instead of waiting 15 s for the connection to time out.
Future<void> assertConnected() async {
  final results = await Connectivity().checkConnectivity();
  if (results.every((r) => r == ConnectivityResult.none)) {
    throw const NetworkOfflineException();
  }
}

/// Executes [fn] with exponential-backoff retry.
///
/// - Retries on `DioExceptionType` connection/timeout errors and HTTP 5xx.
/// - Does NOT retry on 4xx (product-not-found is not a transient failure).
/// - Immediately re-throws [NetworkOfflineException] without retrying.
/// - [baseDelay] scales linearly: attempt 1 → baseDelay, 2 → 2×baseDelay, …
///
/// Typical usage for OFF/USDA (3 retries, 500 ms base):
/// ```dart
/// return withRetry(() async { ... });
/// ```
Future<T> withRetry<T>(
  Future<T> Function() fn, {
  int maxRetries = 3,
  Duration baseDelay = const Duration(milliseconds: 500),
}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } on NetworkOfflineException {
      rethrow; // offline → fail immediately, no point retrying
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final isRetryable = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          statusCode >= 500;
      if (!isRetryable || attempt == maxRetries) rethrow;
      if (kDebugMode) {
        debugPrint('[HTTP RETRY] attempt $attempt/$maxRetries after ${baseDelay * attempt}');
      }
      await Future<void>.delayed(baseDelay * attempt);
    }
  }
  // Unreachable — loop always returns or rethrows before here.
  throw DioException(requestOptions: RequestOptions());
}
