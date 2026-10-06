import 'dart:io';
import 'package:dio/dio.dart';
import '../error/exceptions.dart';
import '../localization/app_strings.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

class DioClient {
  late final Dio _dio;
  late final AuthInterceptor _authInterceptor;

  DioClient({
    required SecureStorageService storageService,
    OnUnauthorizedCallback? onUnauthorized,
    Dio? customDio,
    AuthInterceptor? customAuthInterceptor,
  }) {
    _authInterceptor = customAuthInterceptor ??
        AuthInterceptor(
          storageService: storageService,
          onUnauthorized: onUnauthorized,
        );

    _dio = customDio ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 60), // Allow time for image uploads
            headers: {
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(_authInterceptor);
    _dio.interceptors.add(LoggingInterceptor());
  }

  Dio get dio => _dio;
  AuthInterceptor get authInterceptor => _authInterceptor;

  /// Resets the session expiration guard on the interceptor
  void resetSessionExpirationGuard() {
    _authInterceptor.resetSessionExpirationGuard();
  }

  /// Sets or updates the global session expiration callback
  void setOnUnauthorizedCallback(OnUnauthorizedCallback callback) {
    _authInterceptor.onUnauthorized = callback;
  }

  /// Helper to wrap network requests and map DioException into custom exceptions
  Future<Response<T>> request<T>(Future<Response<T>> Function(Dio dio) call) async {
    try {
      return await call(_dio);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw NetworkException(message: AppStrings.errorNetwork);
    } catch (e) {
      if (e is ServerException ||
          e is NetworkException ||
          e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException(message: AppStrings.errorGeneric);
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(message: AppStrings.errorTimeout);

      case DioExceptionType.connectionError:
        return NetworkException(message: AppStrings.errorNetwork);

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        String message = AppStrings.errorServer;
        dynamic errorDetails;

        if (responseData is Map<String, dynamic>) {
          if (responseData['message'] != null &&
              responseData['message'].toString().trim().isNotEmpty) {
            message = responseData['message'].toString();
          }
          errorDetails = responseData['errors'];
        }

        if (statusCode == 401) {
          return SessionExpiredException(message: AppStrings.errorUnauthorized);
        } else if (statusCode == 403) {
          return ServerException(
            message: AppStrings.errorForbidden,
            statusCode: 403,
          );
        } else if (statusCode == 404) {
          return ServerException(
            message: AppStrings.errorNotFound,
            statusCode: 404,
          );
        } else if (statusCode == 422) {
          return ServerException(
            message: message,
            statusCode: 422,
            errors: errorDetails,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
            message: AppStrings.errorServer,
            statusCode: statusCode,
          );
        }

        return ServerException(
          message: message,
          statusCode: statusCode,
          errors: errorDetails,
        );

      case DioExceptionType.cancel:
        return ServerException(message: 'تم إلغاء الطلب');

      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          return NetworkException(message: AppStrings.errorNetwork);
        }
        return ServerException(message: AppStrings.errorGeneric);
    }
  }
}
