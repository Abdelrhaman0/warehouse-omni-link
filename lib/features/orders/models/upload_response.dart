import 'order_media.dart';

class ShipmentPhotoUploadResponse {
  final bool status;
  final String message;
  final List<OrderMedia> shipmentPhotos;
  final dynamic errors;

  ShipmentPhotoUploadResponse({
    required this.status,
    required this.message,
    required this.shipmentPhotos,
    this.errors,
  });

  factory ShipmentPhotoUploadResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final rawPhotos = (data?['shipment_photo_urls'] ?? data?['shipment_photos']) as List<dynamic>? ?? [];
    final photos = rawPhotos
        .whereType<Map<String, dynamic>>()
        .map((item) => OrderMedia.fromJson(item))
        .toList();

    return ShipmentPhotoUploadResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      shipmentPhotos: photos,
      errors: json['errors'],
    );
  }
}

class WaybillPhotoUploadResponse {
  final bool status;
  final String message;
  final List<OrderMedia> waybillPhotos;
  final dynamic errors;

  WaybillPhotoUploadResponse({
    required this.status,
    required this.message,
    required this.waybillPhotos,
    this.errors,
  });

  factory WaybillPhotoUploadResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final rawPhotos = (data?['waybill_photo_urls'] ?? data?['waybill_photos']) as List<dynamic>? ?? [];
    final photos = rawPhotos
        .whereType<Map<String, dynamic>>()
        .map((item) => OrderMedia.fromJson(item))
        .toList();

    return WaybillPhotoUploadResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      waybillPhotos: photos,
      errors: json['errors'],
    );
  }
}
