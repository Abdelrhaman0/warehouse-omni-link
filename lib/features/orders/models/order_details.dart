import 'package:equatable/equatable.dart';
import 'order_item.dart';
import 'order_media.dart';
import 'order_status.dart';
import 'shipping_details.dart';

class OrderDetails extends Equatable {
  final int id;
  final String orderNumber;
  final OrderStatus status;
  final String rawStatus;
  final String customerName;
  final String? phone;
  final String? whatsapp;
  final String? address;
  final bool canUploadPhotos;
  final bool hasShipmentPhotos;
  final bool hasWaybillPhotos;
  final bool hasExternalWarehouseInvoice;
  final List<OrderMedia> shipmentPhotos;
  final List<OrderMedia> waybillPhotos;
  final List<OrderMedia> externalWarehouseInvoices;
  final List<OrderItem> items;
  final ShippingDetails? shippingDetails;
  final String? createdAt;
  final String? confirmedAt;
  final String? shippedAt;

  const OrderDetails({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.rawStatus,
    required this.customerName,
    this.phone,
    this.whatsapp,
    this.address,
    required this.canUploadPhotos,
    required this.hasShipmentPhotos,
    required this.hasWaybillPhotos,
    required this.hasExternalWarehouseInvoice,
    required this.shipmentPhotos,
    required this.waybillPhotos,
    required this.externalWarehouseInvoices,
    required this.items,
    this.shippingDetails,
    this.createdAt,
    this.confirmedAt,
    this.shippedAt,
  });

  /// Completed orders (shipped or delivered) are read-only.
  /// Upload controls must be hidden and no modifications are allowed.
  bool get isReadOnly =>
      status == OrderStatus.shipped || status == OrderStatus.delivered;

  /// Whether store keeper is allowed to upload photos for this order:
  /// Backend source of truth is canUploadPhotos, but additionally must NOT be a completed order.
  bool get canPerformUpload => canUploadPhotos && !isReadOnly;

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString() ?? '';
    final status = OrderStatus.fromString(rawStatus);

    // Parse items
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map((item) => OrderItem.fromJson(item))
        .toList();

    // Parse photos arrays: backend returns media objects.
    // Supports both new API response keys (*_urls) and legacy keys (*_photos / invoices).
    final rawShipmentPhotos = (json['shipment_photo_urls'] ?? json['shipment_photos']) as List<dynamic>? ?? [];
    final shipmentPhotos = rawShipmentPhotos
        .whereType<Map<String, dynamic>>()
        .map((item) => OrderMedia.fromJson(item))
        .toList();

    final rawShippingDetails = json['shipping_details'] as Map<String, dynamic>?;
    final shippingDetails = rawShippingDetails != null
        ? ShippingDetails.fromJson(rawShippingDetails)
        : null;

    final rawWaybillPhotos = (json['waybill_photo_urls'] ??
            json['waybill_photos'] ??
            rawShippingDetails?['waybill_photos']) as List<dynamic>? ??
        [];
    final waybillPhotos = rawWaybillPhotos
        .whereType<Map<String, dynamic>>()
        .map((item) => OrderMedia.fromJson(item))
        .toList();

    final rawExternalInvoices = (json['external_warehouse_invoice_urls'] ??
            json['external_warehouse_invoices']) as List<dynamic>? ??
        [];
    final externalWarehouseInvoices = rawExternalInvoices
        .whereType<Map<String, dynamic>>()
        .map((item) => OrderMedia.fromJson(item))
        .toList();

    // Parse timestamps (can be nested or flat)
    String? createdAt;
    String? confirmedAt;
    String? shippedAt;

    if (json['timestamps'] is Map<String, dynamic>) {
      final t = json['timestamps'] as Map<String, dynamic>;
      createdAt = t['created_at']?.toString();
      confirmedAt = t['confirmed_at']?.toString();
      shippedAt = t['shipped_at']?.toString();
    } else {
      createdAt = json['created_at']?.toString();
      confirmedAt = json['confirmed_at']?.toString();
      shippedAt = json['shipped_at']?.toString();
    }

    return OrderDetails(
      id: _parseInt(json['id']),
      orderNumber: json['order_number']?.toString() ?? '',
      status: status,
      rawStatus: rawStatus,
      customerName: json['customer_name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      address: json['address']?.toString(),
      canUploadPhotos: json['can_upload_photos'] == true,
      hasShipmentPhotos: json['has_shipment_photos'] == true || shipmentPhotos.isNotEmpty,
      hasWaybillPhotos: json['has_waybill_photos'] == true || waybillPhotos.isNotEmpty,
      hasExternalWarehouseInvoice:
          json['has_external_warehouse_invoice'] == true || externalWarehouseInvoices.isNotEmpty,
      shipmentPhotos: shipmentPhotos,
      waybillPhotos: waybillPhotos,
      externalWarehouseInvoices: externalWarehouseInvoices,
      items: items,
      shippingDetails: shippingDetails,
      createdAt: createdAt,
      confirmedAt: confirmedAt,
      shippedAt: shippedAt,
    );
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        rawStatus,
        customerName,
        phone,
        whatsapp,
        address,
        canUploadPhotos,
        hasShipmentPhotos,
        hasWaybillPhotos,
        hasExternalWarehouseInvoice,
        shipmentPhotos,
        waybillPhotos,
        externalWarehouseInvoices,
        items,
        shippingDetails,
        createdAt,
        confirmedAt,
        shippedAt,
      ];
}
