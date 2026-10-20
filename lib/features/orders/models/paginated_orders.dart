import 'order_status_statistic.dart';
import 'order_summary.dart';

export 'order_status_statistic.dart';

class PaginatedOrders {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final String? firstPageUrl;
  final String? lastPageUrl;
  final bool? hasNextPage;
  final List<OrderSummary> orders;
  final List<OrderStatusStatistic>? statistics;

  const PaginatedOrders({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.nextPageUrl,
    this.prevPageUrl,
    this.firstPageUrl,
    this.lastPageUrl,
    this.hasNextPage,
    required this.orders,
    this.statistics,
  });

  /// True if there are more pages available to load.
  /// Stops when the current page has reached or passed the last page,
  /// when the order list is empty, or when the backend explicitly
  /// indicates there is no next page via a null next link.
  bool get hasMorePages {
    if (orders.isEmpty) return false;
    if (currentPage >= lastPage) return false;
    if (hasNextPage != null) return hasNextPage!;
    if (nextPageUrl != null && nextPageUrl!.isEmpty) return false;
    return currentPage < lastPage;
  }

  factory PaginatedOrders.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> dataMap = json;
    dynamic rawOrders = json['data'];

    // Safely distinguish outer response object from inner data object:
    // e.g. { "data": { "data": [...orders...], "meta": {...}, "links": {...} } }
    if (rawOrders is Map<String, dynamic>) {
      dataMap = rawOrders;
      rawOrders = rawOrders['data'];
    }

    final rawList = rawOrders is List<dynamic> ? rawOrders : <dynamic>[];
    final parsedOrders = rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => OrderSummary.fromJson(item))
        .toList();

    // Standard Laravel pagination has pagination metadata inside 'meta' and links inside 'links'
    final meta = dataMap['meta'] is Map<String, dynamic>
        ? dataMap['meta'] as Map<String, dynamic>
        : (json['meta'] is Map<String, dynamic>
              ? json['meta'] as Map<String, dynamic>
              : dataMap);

    final links = dataMap['links'] is Map<String, dynamic>
        ? dataMap['links'] as Map<String, dynamic>
        : (json['links'] is Map<String, dynamic>
              ? json['links'] as Map<String, dynamic>
              : dataMap);

    final hasNextLinkKey =
        links.containsKey('next') ||
        dataMap.containsKey('next_page_url') ||
        json.containsKey('next_page_url');
    final nextLinkRaw =
        links['next'] ?? dataMap['next_page_url'] ?? json['next_page_url'];

    final bool? hasNextPage = hasNextLinkKey
        ? (nextLinkRaw != null && nextLinkRaw.toString().isNotEmpty)
        : null;

    final prevLinkRaw =
        links['prev'] ?? dataMap['prev_page_url'] ?? json['prev_page_url'];
    final firstLinkRaw =
        links['first'] ?? dataMap['first_page_url'] ?? json['first_page_url'];
    final lastLinkRaw =
        links['last'] ?? dataMap['last_page_url'] ?? json['last_page_url'];

    final rawCurrentPage = _parseInt(
      meta['current_page'] ?? json['current_page'],
      fallback: 1,
    );
    final rawLastPage = _parseInt(
      meta['last_page'] ?? json['last_page'],
      fallback: 1,
    );
    final rawPerPage = _parseInt(
      meta['per_page'] ?? json['per_page'],
      fallback: 30,
    );
    final rawTotal = _parseInt(
      meta['total'] ?? json['total'],
      fallback: parsedOrders.length,
    );

    final dynamic rawStats =
        meta['statistics'] ?? json['statistics'] ?? dataMap['statistics'];
    final List<OrderStatusStatistic>? statistics = rawStats is List
        ? rawStats
              .whereType<Map<String, dynamic>>()
              .map((item) => OrderStatusStatistic.fromJson(item))
              .toList()
        : null;

    return PaginatedOrders(
      currentPage: rawCurrentPage < 1 ? 1 : rawCurrentPage,
      lastPage: rawLastPage < 1 ? 1 : rawLastPage,
      perPage: rawPerPage < 1 ? 30 : rawPerPage,
      total: rawTotal < 0 ? parsedOrders.length : rawTotal,
      nextPageUrl: nextLinkRaw?.toString(),
      prevPageUrl: prevLinkRaw?.toString(),
      firstPageUrl: firstLinkRaw?.toString(),
      lastPageUrl: lastLinkRaw?.toString(),
      hasNextPage: hasNextPage,
      orders: parsedOrders,
      statistics: statistics,
    );
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
