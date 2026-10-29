import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../models/safe_responses.dart';
import 'safes_remote_data_source.dart';

/// Repository for safe management operations.
/// Follows the same exception → failure mapping pattern as [OrdersRepositoryImpl].
abstract class SafesRepository {
  Future<SafeListResponse> getSafes();
  Future<SafeDetailsResponse> getSafeDetails(int safeId, {int page = 1});
  Future<SafeOperationResponse> createSafe(Map<String, dynamic> body);
  Future<SafeOperationResponse> deposit(int safeId, Map<String, dynamic> body);
  Future<SafeOperationResponse> withdraw(int safeId, Map<String, dynamic> body);
  Future<TransferResponse> transfer(Map<String, dynamic> body);
}

class SafesRepositoryImpl implements SafesRepository {
  final SafesRemoteDataSource remoteDataSource;

  SafesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SafeListResponse> getSafes() async {
    try {
      return await remoteDataSource.getSafes();
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
      throw const ServerFailure('حدث خطأ أثناء تحميل الخزن.');
    }
  }

  @override
  Future<SafeDetailsResponse> getSafeDetails(int safeId, {int page = 1}) async {
    try {
      return await remoteDataSource.getSafeDetails(safeId: safeId, page: page);
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
      throw const ServerFailure('حدث خطأ أثناء تحميل تفاصيل الخزنة.');
    }
  }

  @override
  Future<SafeOperationResponse> createSafe(Map<String, dynamic> body) async {
    try {
      return await remoteDataSource.createSafe(body: body);
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
      throw const ServerFailure('حدث خطأ أثناء إنشاء الخزنة.');
    }
  }

  @override
  Future<SafeOperationResponse> deposit(int safeId, Map<String, dynamic> body) async {
    try {
      return await remoteDataSource.deposit(safeId: safeId, body: body);
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
      throw const ServerFailure('حدث خطأ أثناء عملية الإيداع.');
    }
  }

  @override
  Future<SafeOperationResponse> withdraw(int safeId, Map<String, dynamic> body) async {
    try {
      return await remoteDataSource.withdraw(safeId: safeId, body: body);
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
      throw const ServerFailure('حدث خطأ أثناء عملية السحب.');
    }
  }

  @override
  Future<TransferResponse> transfer(Map<String, dynamic> body) async {
    try {
      return await remoteDataSource.transfer(body: body);
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
      throw const ServerFailure('حدث خطأ أثناء عملية التحويل.');
    }
  }
}
