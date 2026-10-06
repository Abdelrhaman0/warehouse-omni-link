import 'order_summary.dart';

class PaginatedOrders {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final List<OrderSummary> orders;

  const PaginatedOrders({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.nextPageUrl,
    this.prevPageUrl,
    required this.orders,
  });

  bool get hasMorePages => currentPage < lastPage;

  factory PaginatedOrders.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List<dynamic>? ?? [];
    final parsedOrders = rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => OrderSummary.fromJson(item))
        .toList();

    // Standard Laravel pagination has pagination metadata inside 'meta' and links inside 'links'
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : json;
    final links = json['links'] is Map<String, dynamic>
        ? json['links'] as Map<String, dynamic>
        : json;

    return PaginatedOrders(
      currentPage: _parseInt(meta['current_page'] ?? json['current_page'], fallback: 1),
      lastPage: _parseInt(meta['last_page'] ?? json['last_page'], fallback: 1),
      perPage: _parseInt(meta['per_page'] ?? json['per_page'], fallback: 30),
      total: _parseInt(meta['total'] ?? json['total'], fallback: parsedOrders.length),
      nextPageUrl: (links['next'] ?? json['next_page_url'])?.toString(),
      prevPageUrl: (links['prev'] ?? json['prev_page_url'])?.toString(),
      orders: parsedOrders,
    );
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
