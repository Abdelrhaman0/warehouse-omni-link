import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_user.dart';
import '../models/login_response.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login({
    required String login,
    required String password,
    String lang = ApiEndpoints.defaultLanguage,
  });

  Future<void> logout({
    String lang = ApiEndpoints.defaultLanguage,
  });

  Future<AdminUser> getProfile({
    String lang = ApiEndpoints.defaultLanguage,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSourceImpl(this._dioClient);

  @override
  Future<LoginResponse> login({
    required String login,
    required String password,
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    final response = await _dioClient.request(
      (dio) => dio.post(
        ApiEndpoints.login(lang),
        data: {
          'login': login,
          'password': password,
        },
      ),
    );

    if (response.data is Map<String, dynamic>) {
      final loginResponse = LoginResponse.fromJson(response.data);
      if (!loginResponse.status) {
        throw ServerException(
          message: loginResponse.message,
          errors: loginResponse.errors,
        );
      }
      return loginResponse;
    } else {
      throw ServerException(message: 'استجابة غير صالحة من الخادم');
    }
  }

  @override
  Future<void> logout({
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    await _dioClient.request(
      (dio) => dio.post(ApiEndpoints.logout(lang)),
    );
  }

  @override
  Future<AdminUser> getProfile({
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    final response = await _dioClient.request(
      (dio) => dio.get(ApiEndpoints.me(lang)),
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final data = map['data'] as Map<String, dynamic>?;
      if (data != null) {
        return AdminUser.fromJson(data);
      }
    }
    throw ServerException(message: 'تعذر جلب بيانات بروفايل المسؤول');
  }
}
