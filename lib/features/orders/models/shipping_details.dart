import 'package:equatable/equatable.dart';
import 'order_media.dart';

class ShippingDetails extends Equatable {
  final String? waybillNumber;
  final String? trackingUrl;
  final String? labelUrl;
  final bool hasWaybillPhotos;
  final List<OrderMedia> waybillPhotos;
  final String? internalStatus;
  final String? internalStatusText;
  final String? courierStatusCode;

  const ShippingDetails({
    this.waybillNumber,
    this.trackingUrl,
    this.labelUrl,
    this.hasWaybillPhotos = false,
    this.waybillPhotos = const [],
    this.internalStatus,
    this.internalStatusText,
    this.courierStatusCode,
  });

  factory ShippingDetails.fromJson(Map<String, dynamic> json) {
    final rawPhotos = (json['waybill_photo_urls'] ?? json['waybill_photos']) as List<dynamic>? ?? [];
    final photos = rawPhotos
        .whereType<Map<String, dynamic>>()
        .map((p) => OrderMedia.fromJson(p))
        .toList();

    return ShippingDetails(
      waybillNumber: json['waybill_number']?.toString(),
      trackingUrl: json['tracking_url']?.toString(),
      labelUrl: json['label_url']?.toString(),
      hasWaybillPhotos: json['has_waybill_photos'] == true || photos.isNotEmpty,
      waybillPhotos: photos,
      internalStatus: json['internal_status']?.toString(),
      internalStatusText: json['internal_status_text']?.toString(),
      courierStatusCode: json['courier_status_code']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        waybillNumber,
        trackingUrl,
        labelUrl,
        hasWaybillPhotos,
        waybillPhotos,
        internalStatus,
        internalStatusText,
        courierStatusCode,
      ];
}
