import 'package:equatable/equatable.dart';
import 'order_status.dart';

class OrderSummary extends Equatable {
  final int id;
  final String orderNumber;
  final OrderStatus status;
  final String rawStatus;
  final String customerName;
  final int itemsCount;
  final bool canUploadPhotos;
  final bool hasShipmentPhotos;
  final bool hasWaybillPhotos;
  final int shipmentPhotosCount;
  final int waybillPhotosCount;
  final bool hasExternalWarehouseInvoice;
  final int externalWarehouseInvoicesCount;
  final String? createdAt;
  final String? confirmedAt;
  final String? shippedAt;

  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.rawStatus,
    required this.customerName,
    required this.itemsCount,
    required this.canUploadPhotos,
    required this.hasShipmentPhotos,
    required this.hasWaybillPhotos,
    required this.shipmentPhotosCount,
    required this.waybillPhotosCount,
    this.hasExternalWarehouseInvoice = false,
    this.externalWarehouseInvoicesCount = 0,
    this.createdAt,
    this.confirmedAt,
    this.shippedAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString() ?? '';
    final status = OrderStatus.fromString(rawStatus);

    return OrderSummary(
      id: _parseInt(json['id']),
      orderNumber: json['order_number']?.toString() ?? '',
      status: status,
      rawStatus: rawStatus,
      customerName: json['customer_name']?.toString() ?? '',
      itemsCount: _parseInt(json['items_count']),
      canUploadPhotos: _parseBool(json['can_upload_photos']),
      hasShipmentPhotos: _parseBool(json['has_shipment_photos']),
      hasWaybillPhotos: _parseBool(json['has_waybill_photos']),
      shipmentPhotosCount: _parseInt(json['shipment_photos_count']),
      waybillPhotosCount: _parseInt(json['waybill_photos_count']),
      hasExternalWarehouseInvoice: _parseBool(json['has_external_warehouse_invoice']),
      externalWarehouseInvoicesCount: _parseInt(json['external_warehouse_invoices_count']),
      createdAt: json['created_at']?.toString(),
      confirmedAt: json['confirmed_at']?.toString(),
      shippedAt: json['shipped_at']?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        rawStatus,
        customerName,
        itemsCount,
        canUploadPhotos,
        hasShipmentPhotos,
        hasWaybillPhotos,
        shipmentPhotosCount,
        waybillPhotosCount,
        hasExternalWarehouseInvoice,
        externalWarehouseInvoicesCount,
        createdAt,
        confirmedAt,
        shippedAt,
      ];
}
