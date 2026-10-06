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
  });
  Future<PaginatedOrders> getCompletedOrders({int page = 1, int perPage = AppConstants.defaultPerPage});
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
  }) async {
    try {
      final result = await remoteDataSource.getOrders(
        tab: tab ?? 'pending',
        page: page,
        perPage: perPage,
      );

      final openOrders = result.orders
          .where((order) => order.status.isOpen)
          .toList();

      return PaginatedOrders(
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        perPage: result.perPage,
        total: result.total,
        nextPageUrl: result.nextPageUrl,
        prevPageUrl: result.prevPageUrl,
        orders: openOrders,
      );
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
  }) async {
    try {
      final result = await remoteDataSource.getOrders(
        tab: 'completed',
        page: page,
        perPage: perPage,
      );

      final completedOrders = result.orders
          .where((order) => order.status.isCompleted)
          .toList();

      return PaginatedOrders(
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        perPage: result.perPage,
        total: result.total,
        nextPageUrl: result.nextPageUrl,
        prevPageUrl: result.prevPageUrl,
        orders: completedOrders,
      );
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
}
