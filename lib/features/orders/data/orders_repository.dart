import 'dart:typed_data';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/storage/media_hash_storage.dart';
import '../models/order_details.dart';
import '../models/paginated_orders.dart';
import 'orders_remote_data_source.dart';

abstract class OrdersRepository {
  Future<PaginatedOrders> getOpenOrders({
    int page = 1,
    int perPage = AppConstants.defaultPerPage,
    String? tab,
    String? status,
    String? dataType,
  });
  Future<PaginatedOrders> getCompletedOrders({
    int page = 1,
    int perPage = AppConstants.defaultPerPage,
    String? status,
    String? dataType,
  });
  Future<OrderDetails> getOrderDetails(int orderId);

  Future<OrderDetails> uploadShipmentPhotos({
    required int orderId,
    required List<({String name, Uint8List bytes, String hash})> photos,
    void Function(int sent, int total)? onSendProgress,
  });

  Future<OrderDetails> uploadWaybillPhotos({
    required int orderId,
    required List<({String name, Uint8List bytes, String hash})> photos,
    void Function(int sent, int total)? onSendProgress,
  });

  Future<OrderDetails> updateOrderStatus({
    required int orderId,
    required String status,
    String? reason,
    bool? restoreStock,
  });

  Set<String> getUploadedHashes(int orderId);
}

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource remoteDataSource;
  final MediaHashStorage mediaHashStorage;

  OrdersRepositoryImpl({
    required this.remoteDataSource,
    required this.mediaHashStorage,
  });

  @override
  Future<PaginatedOrders> getOpenOrders({
    int page = 1,
    int perPage = AppConstants.defaultPerPage,
    String? tab,
    String? status,
    String? dataType,
  }) async {
    final effectiveDataType = dataType ?? (page > 1 ? 'orders' : 'all');
    try {
      final result = await remoteDataSource.getOrders(
        tab: tab ?? 'pending',
        status: status,
        page: page,
        perPage: perPage,
        dataType: effectiveDataType,
      );

      // The backend is the source of truth for which orders belong to the
      // open-orders tab. Client-side status filtering was discarding orders
      // (e.g. shipped) that the backend legitimately includes in this tab.
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on UnauthorizedException catch (e) {
      throw UnauthorizedFailure(e.message);
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure(AppStrings.errorOrdersLoad);
    }
  }

  @override
  Future<PaginatedOrders> getCompletedOrders({
    int page = 1,
    int perPage = AppConstants.defaultPerPage,
    String? status,
    String? dataType,
  }) async {
    final effectiveDataType = dataType ?? (page > 1 ? 'orders' : 'all');
    try {
      final result = await remoteDataSource.getOrders(
        tab: 'completed',
        status: status,
        page: page,
        perPage: perPage,
        dataType: effectiveDataType,
      );

      // The backend is the source of truth for which orders belong to the
      // completed tab. Return all orders the backend provides.
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on UnauthorizedException catch (e) {
      throw UnauthorizedFailure(e.message);
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure(AppStrings.errorOrdersLoad);
    }
  }

  @override
  Future<OrderDetails> getOrderDetails(int orderId) async {
    try {
      return await remoteDataSource.getOrderDetails(orderId: orderId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on UnauthorizedException catch (e) {
      throw UnauthorizedFailure(e.message);
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure(AppStrings.errorOrderDetailsLoad);
    }
  }

  @override
  Future<OrderDetails> uploadShipmentPhotos({
    required int orderId,
    required List<({String name, Uint8List bytes, String hash})> photos,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      await remoteDataSource.uploadShipmentPhotos(
        orderId: orderId,
        photos: photos.map((p) => (name: p.name, bytes: p.bytes)).toList(),
        onSendProgress: onSendProgress,
      );

      // 1. Persist successful hashes locally
      final hashes = photos.map((p) => p.hash);
      await mediaHashStorage.addUploadedHashes(orderId, hashes);

      // 2. Section 38 Mandatory: refresh order details from backend
      return await getOrderDetails(orderId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on UnauthorizedException catch (e) {
      throw UnauthorizedFailure(e.message);
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure(AppStrings.errorShipmentUpload);
    }
  }

  @override
  Future<OrderDetails> uploadWaybillPhotos({
    required int orderId,
    required List<({String name, Uint8List bytes, String hash})> photos,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      await remoteDataSource.uploadWaybillPhotos(
        orderId: orderId,
        photos: photos.map((p) => (name: p.name, bytes: p.bytes)).toList(),
        onSendProgress: onSendProgress,
      );

      // Persist successful hashes
      final hashes = photos.map((p) => p.hash);
      await mediaHashStorage.addUploadedHashes(orderId, hashes);

      // Section 38 Mandatory: refresh order details from backend
      return await getOrderDetails(orderId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on UnauthorizedException catch (e) {
      throw UnauthorizedFailure(e.message);
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure(AppStrings.errorWaybillUpload);
    }
  }

  @override
  Set<String> getUploadedHashes(int orderId) {
    return mediaHashStorage.getUploadedHashes(orderId);
  }

  @override
  Future<OrderDetails> updateOrderStatus({
    required int orderId,
    required String status,
    String? reason,
    bool? restoreStock,
  }) async {
    try {
      return await remoteDataSource.updateOrderStatus(
        orderId: orderId,
        status: status,
        reason: reason,
        restoreStock: restoreStock,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on UnauthorizedException catch (e) {
      throw UnauthorizedFailure(e.message);
    } catch (e) {
      if (e is Failure) rethrow;
      throw const ServerFailure(AppStrings.errorStatusUpdate);
    }
  }
}
