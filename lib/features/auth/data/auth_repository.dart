import 'dart:async';
import 'dart:convert';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/admin_user.dart';
import 'auth_remote_data_source.dart';

abstract class AuthRepository {
  Future<AdminUser> login(String login, String password);
  Future<void> logout();
  Future<AdminUser?> checkAuthStatus();
  Future<AdminUser> getProfile();

  /// Stream of session expiration events triggered by HTTP 401 on authenticated requests
  Stream<void> get sessionExpiredStream;

  /// Resets the session expiration guard to allow future 401 handling
  void resetSessionExpirationGuard();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService storageService;
  final DioClient? dioClient;
  final StreamController<void> _sessionExpiredController = StreamController<void>.broadcast();

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
    this.dioClient,
  }) {
    dioClient?.setOnUnauthorizedCallback(() {
      _sessionExpiredController.add(null);
    });
  }

  @override
  Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  @override
  void resetSessionExpirationGuard() {
    dioClient?.resetSessionExpirationGuard();
  }

  @override
  Future<AdminUser> login(String login, String password) async {
    try {
      final response = await remoteDataSource.login(
        login: login,
        password: password,
      );

      final token = response.token;
      final admin = response.admin;

      if (token == null || admin == null) {
        throw const ServerFailure('بيانات الدخول غير مكتملة');
      }

      await storageService.saveAuthToken(token);
      await storageService.saveUserData(jsonEncode(admin.toJson()));
      resetSessionExpirationGuard();

      return admin;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on SessionExpiredException catch (e) {
      throw SessionExpiredFailure(e.message);
    } on UnauthorizedException catch (e) {
      throw UnauthorizedFailure(e.message);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Attempt remote logout
      await remoteDataSource.logout();
    } catch (_) {
      // Per spec: Even if logout API fails because of a network problem,
      // the UI should provide a safe local logout behavior.
    } finally {
      await storageService.clearAuthData();
      resetSessionExpirationGuard();
    }
  }

  @override
  Future<AdminUser?> checkAuthStatus() async {
    try {
      final hasToken = await storageService.hasToken();
      if (!hasToken) return null;

      final userDataString = await storageService.getUserData();
      if (userDataString != null) {
        final Map<String, dynamic> json = jsonDecode(userDataString);
        return AdminUser.fromJson(json);
      }

      // If user data wasn't cached, try fetching profile
      try {
        final profile = await remoteDataSource.getProfile();
        await storageService.saveUserData(jsonEncode(profile.toJson()));
        return profile;
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AdminUser> getProfile() async {
    try {
      final profile = await remoteDataSource.getProfile();
      await storageService.saveUserData(jsonEncode(profile.toJson()));
      return profile;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on SessionExpiredException catch (e) {
      throw SessionExpiredFailure(e.message);
    } on UnauthorizedException catch (e) {
      throw UnauthorizedFailure(e.message);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString());
    }
  }
}
