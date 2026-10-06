import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/order_details.dart';
import '../models/paginated_orders.dart';
import '../models/upload_response.dart';

abstract class OrdersRemoteDataSource {
  Future<PaginatedOrders> getOrders({
    String? status,
    String? tab,
    int page = 1,
    int perPage = AppConstants.defaultPerPage,
    String lang = ApiEndpoints.defaultLanguage,
  });

  Future<OrderDetails> getOrderDetails({
    required int orderId,
    String lang = ApiEndpoints.defaultLanguage,
  });

  Future<ShipmentPhotoUploadResponse> uploadShipmentPhotos({
    required int orderId,
    required List<({String name, Uint8List bytes})> photos,
    void Function(int sent, int total)? onSendProgress,
    String lang = ApiEndpoints.defaultLanguage,
  });

  Future<WaybillPhotoUploadResponse> uploadWaybillPhotos({
    required int orderId,
    required List<({String name, Uint8List bytes})> photos,
    void Function(int sent, int total)? onSendProgress,
    String lang = ApiEndpoints.defaultLanguage,
  });
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final DioClient _dioClient;

  OrdersRemoteDataSourceImpl(this._dioClient);

  @override
  Future<PaginatedOrders> getOrders({
    String? status,
    String? tab,
    int page = 1,
    int perPage = AppConstants.defaultPerPage,
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    final queryParams = <String, dynamic>{
      'per_page': perPage,
    };
    if (page > 1) {
      queryParams['page'] = page;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (tab != null && tab.isNotEmpty) {
      queryParams['tab'] = tab;
    }

    final response = await _dioClient.request(
      (dio) => dio.get(
        ApiEndpoints.orders(lang),
        queryParameters: queryParams,
      ),
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final data = map['data'] as Map<String, dynamic>?;
      if (data != null) {
        return PaginatedOrders.fromJson(data);
      }
    }
    throw ServerException(message: 'تعذر جلب طلبات المستودع');
  }

  @override
  Future<OrderDetails> getOrderDetails({
    required int orderId,
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    final response = await _dioClient.request(
      (dio) => dio.get(ApiEndpoints.orderDetails(lang, orderId)),
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final data = map['data'] as Map<String, dynamic>?;
      if (data != null) {
        return OrderDetails.fromJson(data);
      }
    }
    throw ServerException(message: 'تعذر جلب تفاصيل الطلب');
  }

  @override
  Future<ShipmentPhotoUploadResponse> uploadShipmentPhotos({
    required int orderId,
    required List<({String name, Uint8List bytes})> photos,
    void Function(int sent, int total)? onSendProgress,
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    final formData = FormData();

    for (var i = 0; i < photos.length; i++) {
      final item = photos[i];
      final filename = item.name.isNotEmpty ? item.name : 'shipment_photo_$i.jpg';
      formData.files.add(
        MapEntry(
          'photos[]',
          MultipartFile.fromBytes(
            item.bytes,
            filename: filename,
          ),
        ),
      );
    }

    final url = ApiEndpoints.shipmentPhotos(lang, orderId);
    final fieldNames = formData.fields.map((e) => e.key).toList() +
        formData.files.map((e) => e.key).toList();
    final filesSummary = formData.files.map((entry) {
      final file = entry.value;
      return 'name: ${file.filename}, size: ${file.length} bytes, MIME: ${file.contentType ?? "Not set (Dio default)"}';
    }).join('\n   - ');

    // ignore: avoid_print
    print('''
🔥 WAREHOUSE IMAGE UPLOAD: ABOUT TO SEND REQUEST
   URL: $url
   HTTP Method: POST
   FormData Fields: $fieldNames
   File Path: N/A (Uploaded from in-memory Uint8List bytes)
   Files (${formData.files.length}):
   - $filesSummary''');

    final response = await _dioClient.request(
      (dio) async {
        try {
          final res = await dio.post(
            url,
            data: formData,
            onSendProgress: onSendProgress,
          );
          // ignore: avoid_print
          print('''
✅ WAREHOUSE IMAGE UPLOAD: RESPONSE RECEIVED
   URL: $url
   Status Code: ${res.statusCode}
   Response Body: ${res.data}''');
          return res;
        } on DioException catch (dioErr) {
          // ignore: avoid_print
          print('''
❌ WAREHOUSE IMAGE UPLOAD: DIO EXCEPTION
   URL: $url
   Status Code: ${dioErr.response?.statusCode}
   Response Body: ${dioErr.response?.data}
   Error Type: ${dioErr.type}
   Message: ${dioErr.message}''');
          rethrow;
        } catch (e) {
          // ignore: avoid_print
          print('''
❌ WAREHOUSE IMAGE UPLOAD: UNEXPECTED EXCEPTION
   URL: $url
   Exception: $e''');
          rethrow;
        }
      },
    );

    if (response.data is Map<String, dynamic>) {
      final uploadResponse = ShipmentPhotoUploadResponse.fromJson(response.data);
      if (!uploadResponse.status) {
        throw ServerException(
          message: uploadResponse.message,
          errors: uploadResponse.errors,
        );
      }
      return uploadResponse;
    }
    throw ServerException(message: 'تعذر رفع صور الشحنة والمنتجات');
  }

  @override
  Future<WaybillPhotoUploadResponse> uploadWaybillPhotos({
    required int orderId,
    required List<({String name, Uint8List bytes})> photos,
    void Function(int sent, int total)? onSendProgress,
    String lang = ApiEndpoints.defaultLanguage,
  }) async {
    final formData = FormData();

    for (var i = 0; i < photos.length; i++) {
      final item = photos[i];
      final filename = item.name.isNotEmpty ? item.name : 'waybill_photo_$i.jpg';
      formData.files.add(
        MapEntry(
          'photos[]',
          MultipartFile.fromBytes(
            item.bytes,
            filename: filename,
          ),
        ),
      );
    }

    final url = ApiEndpoints.waybillPhotos(lang, orderId);
    final fieldNames = formData.fields.map((e) => e.key).toList() +
        formData.files.map((e) => e.key).toList();
    final filesSummary = formData.files.map((entry) {
      final file = entry.value;
      return 'name: ${file.filename}, size: ${file.length} bytes, MIME: ${file.contentType ?? "Not set (Dio default)"}';
    }).join('\n   - ');

    // ignore: avoid_print
    print('''
🔥 WAREHOUSE IMAGE UPLOAD: ABOUT TO SEND REQUEST
   URL: $url
   HTTP Method: POST
   FormData Fields: $fieldNames
   File Path: N/A (Uploaded from in-memory Uint8List bytes)
   Files (${formData.files.length}):
   - $filesSummary''');

    final response = await _dioClient.request(
      (dio) async {
        try {
          final res = await dio.post(
            url,
            data: formData,
            onSendProgress: onSendProgress,
          );
          // ignore: avoid_print
          print('''
✅ WAREHOUSE IMAGE UPLOAD: RESPONSE RECEIVED
   URL: $url
   Status Code: ${res.statusCode}
   Response Body: ${res.data}''');
          return res;
        } on DioException catch (dioErr) {
          // ignore: avoid_print
          print('''
❌ WAREHOUSE IMAGE UPLOAD: DIO EXCEPTION
   URL: $url
   Status Code: ${dioErr.response?.statusCode}
   Response Body: ${dioErr.response?.data}
   Error Type: ${dioErr.type}
   Message: ${dioErr.message}''');
          rethrow;
        } catch (e) {
          // ignore: avoid_print
          print('''
❌ WAREHOUSE IMAGE UPLOAD: UNEXPECTED EXCEPTION
   URL: $url
   Exception: $e''');
          rethrow;
        }
      },
    );

    if (response.data is Map<String, dynamic>) {
      final uploadResponse = WaybillPhotoUploadResponse.fromJson(response.data);
      if (!uploadResponse.status) {
        throw ServerException(
          message: uploadResponse.message,
          errors: uploadResponse.errors,
        );
      }
      return uploadResponse;
    }
    throw ServerException(message: 'تعذر رفع صور بوليصة الشحن');
  }
}
