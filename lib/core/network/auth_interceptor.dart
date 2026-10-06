import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

typedef OnUnauthorizedCallback = void Function();

/// Dio Interceptor that attaches Bearer tokens and handles 401 Unauthorized responses.
/// Strictly ensures sensitive auth tokens and passwords are never logged.
class AuthInterceptor extends Interceptor {
  final SecureStorageService storageService;
  OnUnauthorizedCallback? onUnauthorized;

  /// Guard to prevent concurrent or repeated session expiration workflows.
  bool _isHandlingSessionExpiration = false;

  AuthInterceptor({
    required this.storageService,
    this.onUnauthorized,
  });

  /// Indicates if session expiration handling is currently active.
  bool get isHandlingSessionExpiration => _isHandlingSessionExpiration;

  /// Resets the guard, allowing future session expiration handling (e.g. after re-login).
  void resetSessionExpirationGuard() {
    _isHandlingSessionExpiration = false;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';

    // Add authorization header if token exists and not explicitly excluded
    final token = await storageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    if (statusCode == 401 && _shouldTriggerSessionExpiration(err.requestOptions)) {
      if (!_isHandlingSessionExpiration) {
        _isHandlingSessionExpiration = true;

        // Clear only authentication/session data immediately
        try {
          await storageService.clearAuthData();
        } catch (_) {
          // ignore local secure storage deletion errors
        }

        // Notify global application listener
        onUnauthorized?.call();
      }
    }

    return handler.next(err);
  }

  /// Determines whether a 401 response indicates an expired authenticated session.
  /// Public endpoints (like login) or logout endpoints MUST NOT trigger session expiration.
  bool _shouldTriggerSessionExpiration(RequestOptions options) {
    final path = options.path.toLowerCase();

    // 1. Exclude public auth endpoints:
    // A 401 on /login indicates invalid credentials, NOT session expiration.
    // A 401 on /logout should not trigger recursive session expiration flows.
    if (path.contains('/auth/login') || path.contains('/auth/logout')) {
      return false;
    }

    // 2. An authenticated request must have had an Authorization header
    final hasAuthHeader = options.headers.containsKey('Authorization') &&
        options.headers['Authorization'] != null &&
        (options.headers['Authorization'] as String).isNotEmpty;

    return hasAuthHeader;
  }
}

