import 'package:equatable/equatable.dart';

import 'order_media.dart';

class ShippingDetails extends Equatable {
  final String? shippingCompany;
  final String? waybillNumber;
  final String? trackingUrl;
  final String? labelUrl;
  final bool hasWaybillPhotos;
  final List<OrderMedia> waybillPhotos;
  final String? internalStatus;
  final String? internalStatusText;
  final String? courierStatusCode;
  /// Cancellation reason returned by the API under `shipping_details.cancelled_reason`.
  /// Null when the order is not cancelled or when no reason was provided.
  final String? cancelledReason;

  const ShippingDetails({
    this.shippingCompany,
    this.waybillNumber,
    this.trackingUrl,
    this.labelUrl,
    this.hasWaybillPhotos = false,
    this.waybillPhotos = const [],
    this.internalStatus,
    this.internalStatusText,
    this.courierStatusCode,
    this.cancelledReason,
  });

  factory ShippingDetails.fromJson(Map<String, dynamic> json) {
    final rawPhotos =
        (json['waybill_photo_urls'] ?? json['waybill_photos'])
            as List<dynamic>? ??
        [];
    final photos = rawPhotos
        .whereType<Map<String, dynamic>>()
        .map((p) => OrderMedia.fromJson(p))
        .toList();

    // Support both new keys (status / status_text) and legacy keys
    // (internal_status / internal_status_text) from older API versions.
    final internalStatus =
        (json['internal_status'] ?? json['status'])?.toString();
    final internalStatusText =
        (json['internal_status_text'] ?? json['status_text'])?.toString();

    return ShippingDetails(
      shippingCompany: json['shipping_company']?.toString(),
      waybillNumber: json['waybill_number']?.toString(),
      trackingUrl: json['tracking_url']?.toString(),
      labelUrl: json['label_url']?.toString(),
      hasWaybillPhotos: json['has_waybill_photos'] == true || photos.isNotEmpty,
      waybillPhotos: photos,
      internalStatus: internalStatus,
      internalStatusText: internalStatusText,
      courierStatusCode: json['courier_status_code']?.toString(),
      cancelledReason: json['cancelled_reason']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    shippingCompany,
    waybillNumber,
    trackingUrl,
    labelUrl,
    hasWaybillPhotos,
    waybillPhotos,
    internalStatus,
    internalStatusText,
    courierStatusCode,
    cancelledReason,
  ];
}
