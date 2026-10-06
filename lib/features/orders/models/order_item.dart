import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final int id;
  final int productId;
  final String productName;
  final String sku;
  final int quantity;
  final String? productImage;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    this.productImage,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: _parseInt(json['id']),
      productId: _parseInt(json['product_id']),
      productName: json['product_name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      quantity: _parseInt(json['qty'] ?? json['quantity'], fallback: 1),
      productImage: (json['image_url'] ?? json['product_image'])?.toString(),
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
      ];
}
