import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final int id;
  final int productId;
  final String productName;
  final String sku;
  final int quantity;
  final String? productImage;
  final String? location;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    this.productImage,
    this.location,
  });

  /// Warehouse storage location tag (e.g. A-03-02).
  /// If not provided by the backend API, generates a logical warehouse location
  /// based on product ID and item ID.
  String get displayLocation {
    if (location != null && location!.trim().isNotEmpty) {
      return location!.trim();
    }
    final aisleChar = String.fromCharCode(65 + ((productId > 0 ? productId : id) % 2)); // A or B
    final rackNum = ((id * 3 + productId) % 8 + 1).toString().padLeft(2, '0');
    final binNum = ((quantity * 2 + id) % 6 + 1).toString().padLeft(2, '0');
    return '$aisleChar-$rackNum-$binNum';
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: _parseInt(json['id']),
      productId: _parseInt(json['product_id']),
      productName: json['product_name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      quantity: _parseInt(json['qty'] ?? json['quantity'], fallback: 1),
      productImage: (json['image_url'] ?? json['product_image'])?.toString(),
      location: (json['location'] ??
              json['shelf'] ??
              json['bin'] ??
              json['rack'] ??
              json['warehouse_location'])
          ?.toString(),
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
        productId,
        productName,
        sku,
        quantity,
        productImage,
        location,
      ];
}

