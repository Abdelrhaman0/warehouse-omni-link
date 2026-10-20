import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/models/paginated_orders.dart';

void main() {
  group('PaginatedOrders - JSON Parsing & Nested Data', () {
    test('Scenario 13: Correctly parses nested data.data, data.links, and data.meta from root response', () {
      final json = {
        'status': true,
        'message': 'Orders retrieved successfully',
        'data': {
          'data': [
            {
              'id': 101,
              'order_number': 'ORD-101',
              'status': 'confirmed',
              'customer_name': 'Ali Ahmad',
              'items_count': 3,
            },
            {
              'id': 102,
              'order_number': 'ORD-102',
              'status': 'processing',
              'customer_name': 'Sara Saleh',
              'items_count': 1,
            },
          ],
          'links': {
            'first': 'https://example.com/api/orders?page=1',
            'last': 'https://example.com/api/orders?page=5',
            'prev': null,
            'next': 'https://example.com/api/orders?page=2',
          },
          'meta': {
            'current_page': 1,
            'last_page': 5,
            'per_page': 30,
            'total': 150,
          },
        },
      };

      final result = PaginatedOrders.fromJson(json);

      expect(result.orders.length, 2);
      expect(result.orders[0].id, 101);
      expect(result.orders[0].orderNumber, 'ORD-101');
      expect(result.orders[0].status, OrderStatus.confirmed);
      expect(result.orders[1].id, 102);
      expect(result.currentPage, 1);
      expect(result.lastPage, 5);
      expect(result.perPage, 30);
      expect(result.total, 150);
      expect(result.nextPageUrl, 'https://example.com/api/orders?page=2');
      expect(result.prevPageUrl, isNull);
      expect(result.hasMorePages, isTrue);
    });

    test('Scenario 13b: Correctly parses when json is already unwrapped to data object', () {
      final json = {
        'data': [
          {
            'id': 201,
            'order_number': 'ORD-201',
            'status': 'shipped',
            'customer_name': 'Khaled Omar',
            'items_count': 2,
          },
        ],
        'links': {
          'first': 'https://example.com/api/orders?page=1',
          'last': 'https://example.com/api/orders?page=1',
          'prev': null,
          'next': null,
        },
        'meta': {'current_page': 1, 'last_page': 1, 'per_page': 30, 'total': 1},
      };

      final result = PaginatedOrders.fromJson(json);

      expect(result.orders.length, 1);
      expect(result.orders[0].id, 201);
      expect(result.currentPage, 1);
      expect(result.lastPage, 1);
      expect(result.hasMorePages, isFalse);
    });

    test('Scenario 5: Handling a null next-page link stops pagination (hasMorePages is false)', () {
      final json = {
        'data': {
          'data': [
            {'id': 301, 'order_number': 'ORD-301', 'status': 'delivered'},
          ],
          'links': {
            'first': 'https://example.com/api/orders?page=1',
            'last': 'https://example.com/api/orders?page=3',
            'prev': 'https://example.com/api/orders?page=2',
            'next': null,
          },
          'meta': {
            'current_page': 2,
            'last_page': 3,
            'per_page': 15,
            'total': 45,
          },
        },
      };

      final result = PaginatedOrders.fromJson(json);

      expect(result.nextPageUrl, isNull);
      expect(
        result.hasMorePages,
        isFalse,
        reason: 'A null next link from the backend must indicate no more pages',
      );
    });

    test('Scenario 6: Handling an empty first-page response safely', () {
      final json = {
        'data': {
          'data': [],
          'links': {
            'first': 'https://example.com/api/orders?page=1',
            'last': 'https://example.com/api/orders?page=1',
            'prev': null,
            'next': null,
          },
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'per_page': 30,
            'total': 0,
          },
        },
      };

      final result = PaginatedOrders.fromJson(json);

      expect(result.orders, isEmpty);
      expect(result.total, 0);
      expect(result.hasMorePages, isFalse);
    });

    test('Safely handles unexpected/missing metadata and string integers', () {
      final json = {
        'data': {
          'data': null,
          'meta': {
            'current_page': '2',
            'last_page': '4',
            'per_page': '30',
            'total': '120',
          },
        },
      };

      final result = PaginatedOrders.fromJson(json);

      expect(result.orders, isEmpty);
      expect(result.currentPage, 2);
      expect(result.lastPage, 4);
      expect(result.perPage, 30);
      expect(result.total, 120);
      // Empty orders means no more pages to load
      expect(result.hasMorePages, isFalse);
    });

    test('Combined response: parses orders, pagination metadata, and statistics list correctly', () {
      final json = {
        'data': [
          {
            'id': 1,
            'order_number': 'ORD-001',
            'status': 'delivered',
            'customer_name': 'Test Customer',
            'items_count': 2,
          },
        ],
        'meta': {
          'current_page': 1,
          'last_page': 10,
          'per_page': 15,
          'total': 143,
          'statistics': [
            {'status': 'delivered', 'status_text': 'تم التوصيل', 'count': 108},
            {'status': 'cancelled', 'status_text': 'ألغيت', 'count': 30},
            {
              'status': 'refused_delivery',
              'status_text': 'رفض الاستلام',
              'count': 2,
            },
            {'status': 'pending', 'status_text': 'في الانتظار', 'count': 1},
            {'status': 'confirmed', 'status_text': 'تم التأكيد', 'count': 1},
            {
              'status': 'processing',
              'status_text': 'جاري المعالجة',
              'count': 1,
            },
            {'status': 'total', 'status_text': 'الاجمالي', 'count': 143},
          ],
        },
      };

      final result = PaginatedOrders.fromJson(json);

      expect(result.orders.length, 1);
      expect(result.total, 143);
      expect(result.currentPage, 1);
      expect(result.lastPage, 10);
      expect(result.perPage, 15);
      expect(result.statistics, isNotNull);
      expect(result.statistics!.length, 7);

      final delivered = result.statistics!.firstWhere(
        (s) => s.status == 'delivered',
      );
      expect(delivered.count, 108);
      expect(delivered.statusText, 'تم التوصيل');
      expect(delivered.isValidCount, isTrue);

      final total = result.statistics!.firstWhere((s) => s.status == 'total');
      expect(total.count, 143);
      expect(total.statusText, 'الاجمالي');
    });

    test('Missing statistics in orders-only response leaves statistics as null without failing', () {
      final json = {
        'data': [
          {'id': 2, 'order_number': 'ORD-002', 'status': 'confirmed'},
        ],
        'meta': {
          'current_page': 2,
          'last_page': 5,
          'per_page': 15,
          'total': 75,
        },
      };

      final result = PaginatedOrders.fromJson(json);

      expect(result.orders.length, 1);
      expect(result.statistics, isNull);
      expect(result.total, 75);
    });

    test('Handles numeric strings and unknown status identifiers safely', () {
      final json = {
        'data': [],
        'meta': {
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 50,
          'statistics': [
            {
              'status': 'custom_unknown_status',
              'status_text': 'حالة مخصصة',
              'count': '42',
            },
            {'status': 'invalid_count_status', 'count': null},
          ],
        },
      };

      final result = PaginatedOrders.fromJson(json);

      expect(result.statistics, isNotNull);
      expect(result.statistics!.length, 2);
      expect(result.statistics![0].status, 'custom_unknown_status');
      expect(result.statistics![0].count, 42);
      expect(result.statistics![0].statusText, 'حالة مخصصة');
      expect(result.statistics![0].isValidCount, isTrue);

      expect(result.statistics![1].status, 'invalid_count_status');
      expect(result.statistics![1].count, 0);
      expect(result.statistics![1].isValidCount, isFalse);
    });
  });
}
