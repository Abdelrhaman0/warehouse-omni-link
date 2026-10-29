import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/safe_responses.dart';

/// Remote data source for safe management endpoints.
/// Follows the same patterns as [AuthRemoteDataSourceImpl] and [OrdersRemoteDataSourceImpl].
abstract class SafesRemoteDataSource {
  /// GET /{lang}/v1/admin/safes
  Future<SafeListResponse> getSafes({
    String lang = ApiEndpoints.defaultLanguage,
  });

  /// GET /{lang}/v1/admin/safes/{id}?page={page}
  Future<SafeDetailsResponse> getSafeDetails({
    required int safeId,
    int page = 1,
    String lang = ApiEndpoints.defaultLanguage,
  });

  /// POST /{lang}/v1/admin/safes
  Future<SafeOperationResponse> createSafe({
    required Map<String, dynamic> body,
    String lang = ApiEndpoints.defaultLanguage,
  });

  /// POST /{lang}/v1/admin/safes/{id}/deposit
  Future<SafeOperationResponse> deposit({
    required int safeId,
    required Map<String, dynamic> body,
    String lang = ApiEndpoints.defaultLanguage,
  });

  /// POST /{lang}/v1/admin/safes/{id}/withdraw
  Future<SafeOperationResponse> withdraw({
    required int safeId,
    required Map<String, dynamic> body,
    String lang = ApiEndpoints.defaultLanguage,
  });

  /// POST /{lang}/v1/admin/safes/transfer
  Future<TransferResponse> transfer({
    required Map<String, dynamic> body,
    String lang = ApiEndpoints.defaultLanguage,
  });
}

class SafesRemoteDataSourceImpl implements SafesRemoteDataSource {
  final DioClient _dioClient;

  SafesRemoteDataSourceImpl(this._dioClient);

  static String _safesUrl(String lang) =>
      '${ApiEndpoints.localizedBase(lang)}/admin/safes';

  static String _safeDetailsUrl(String lang, int id) =>
      '${ApiEndpoints.localizedBase(lang)}/admin/safes/$id';

  static String _depositUrl(String lang, int id) =>
      '${ApiEndpoints.localizedBase(lang)}/admin/safes/$id/deposit';

  static String _withdrawUrl(String lang, int id) =>
      '${ApiEndpoints.localizedBase(lang)}/admin/safes/$id/withdraw';

  static String _transferUrl(String lang) =>
      '${ApiEndpoints.localizedBase(lang)}/admin/safes/transfer';

  @override
  Future<SafeListResponse> getSafes({
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    final response = await _dioClient.request(
      (dio) => dio.get(_safesUrl(lang)),
    );

    if (response.data is Map<String, dynamic>) {
      final listResponse = SafeListResponse.fromJson(response.data);
      if (!listResponse.status) {
        throw ServerException(message: listResponse.message);
      }
      return listResponse;
    }
    throw ServerException(message: 'استجابة غير صالحة من الخادم');
  }

  @override
  Future<SafeDetailsResponse> getSafeDetails({
    required int safeId,
    int page = 1,
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page > 1) {
      queryParams['page'] = page;
    }

    final response = await _dioClient.request(
      (dio) => dio.get(
        _safeDetailsUrl(lang, safeId),
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      ),
    );

    if (response.data is Map<String, dynamic>) {
      final detailsResponse = SafeDetailsResponse.fromJson(response.data);
      if (!detailsResponse.status) {
        throw ServerException(message: detailsResponse.message);
      }
      return detailsResponse;
    }
    throw ServerException(message: 'استجابة غير صالحة من الخادم');
  }

  @override
  Future<SafeOperationResponse> createSafe({
    required Map<String, dynamic> body,
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    final response = await _dioClient.request(
      (dio) => dio.post(_safesUrl(lang), data: body),
    );

    if (response.data is Map<String, dynamic>) {
      final operationResponse = SafeOperationResponse.fromJson(response.data);
      if (!operationResponse.status) {
        throw ServerException(
          message: operationResponse.message,
          errors: operationResponse.errors,
        );
      }
      return operationResponse;
    }
    throw ServerException(message: 'استجابة غير صالحة من الخادم');
  }

  @override
  Future<SafeOperationResponse> deposit({
    required int safeId,
    required Map<String, dynamic> body,
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    final response = await _dioClient.request(
      (dio) => dio.post(_depositUrl(lang, safeId), data: body),
    );

    if (response.data is Map<String, dynamic>) {
      final operationResponse = SafeOperationResponse.fromJson(response.data);
      if (!operationResponse.status) {
        throw ServerException(
          message: operationResponse.message,
          errors: operationResponse.errors,
        );
      }
      return operationResponse;
    }
    throw ServerException(message: 'استجابة غير صالحة من الخادم');
  }

  @override
  Future<SafeOperationResponse> withdraw({
    required int safeId,
    required Map<String, dynamic> body,
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    final response = await _dioClient.request(
      (dio) => dio.post(_withdrawUrl(lang, safeId), data: body),
    );

    if (response.data is Map<String, dynamic>) {
      final operationResponse = SafeOperationResponse.fromJson(response.data);
      if (!operationResponse.status) {
        throw ServerException(
          message: operationResponse.message,
          errors: operationResponse.errors,
        );
      }
      return operationResponse;
    }
    throw ServerException(message: 'استجابة غير صالحة من الخادم');
  }

  @override
  Future<TransferResponse> transfer({
    required Map<String, dynamic> body,
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    final response = await _dioClient.request(
      (dio) => dio.post(_transferUrl(lang), data: body),
    );

    if (response.data is Map<String, dynamic>) {
      final transferResponse = TransferResponse.fromJson(response.data);
      if (!transferResponse.status) {
        throw ServerException(
          message: transferResponse.message,
          errors: transferResponse.errors,
        );
      }
      return transferResponse;
    }
    throw ServerException(message: 'استجابة غير صالحة من الخادم');
  }
}
