// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_details.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_media.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_summary.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/order_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Builds a minimal but valid order-summary JSON map.
Map<String, dynamic> _baseOrderSummaryJson({Map<String, dynamic>? overrides}) {
  final base = <String, dynamic>{
    'id': 75,
    'order_number': 'ORD-bbYAoryppp',
    'status': 'confirmed',
    'customer_name': 'ali ahmed',
    'items_count': 3,
    'can_upload_photos': true,
    'has_shipment_photos': false,
    'has_waybill_photos': false,
    'shipment_photos_count': 0,
    'waybill_photos_count': 0,
    'created_at': '2026-09-26T10:00:00+00:00',
  };
  if (overrides != null) base.addAll(overrides);
  return base;
}

/// Builds a minimal but valid order-details JSON map.
/// Callers may override individual keys via [overrides].
Map<String, dynamic> _baseOrderJson({Map<String, dynamic>? overrides}) {
  final base = <String, dynamic>{
    'id': 75,
    'order_number': 'ORD-bbYAoryppp',
    'status': 'confirmed',
    'customer_name': 'ali ahmed',
    'phone': '+201066644016',
    'whatsapp': null,
    'address': null,
    'can_upload_photos': true,
    'has_shipment_photos': false,
    'has_waybill_photos': false,
    'shipment_photos': <dynamic>[],
    'waybill_photos': <dynamic>[],
    'items': <dynamic>[],
    'timestamps': {
      'created_at': '2026-09-26T10:00:00+00:00',
      'confirmed_at': null,
      'shipped_at': null,
    },
  };
  if (overrides != null) base.addAll(overrides);
  return base;
}

/// A complete invoice object matching the backend response shape.
const Map<String, dynamic> _invoiceJson = {
  'id': 1198,
  'file_name': 'Screenshot-2026-09-20-172245.png',
  'mime_type': 'image/png',
  'size': 34442,
  'url': 'https://test.omni-link.net/storage/1198/Screenshot-2026-09-20-172245.png',
  'created_at': '2026-09-26T11:45:42+00:00',
};

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. Model: OrderMedia reuse ───────────────────────────────────────────
  group('OrderMedia – reused as ExternalWarehouseInvoice attachment', () {
    test('fromJson parses all expected fields from an invoice object', () {
      final media = OrderMedia.fromJson(_invoiceJson);

      expect(media.id, 1198);
      expect(media.fileName, 'Screenshot-2026-09-20-172245.png');
      expect(media.mimeType, 'image/png');
      expect(media.size, 34442);
      expect(
        media.url,
        'https://test.omni-link.net/storage/1198/Screenshot-2026-09-20-172245.png',
      );
      expect(media.createdAt, isNotNull);
    });

    test('url is the plain HTTPS URL string, not a stringified object', () {
      final media = OrderMedia.fromJson(_invoiceJson);
      expect(media.url, startsWith('https://'));
      expect(media.toString(), isNot(startsWith('https://')));
    });
  });

  // ── 2. OrderDetails: new fields are parsed ───────────────────────────────
  group('OrderDetails – external_warehouse_invoices field parsing', () {
    test('parses one invoice correctly when backend returns one item', () {
      final json = _baseOrderJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices': [_invoiceJson],
      });

      final order = OrderDetails.fromJson(json);

      expect(order.hasExternalWarehouseInvoice, isTrue);
      expect(order.externalWarehouseInvoices.length, 1);
      expect(
        order.externalWarehouseInvoices.first.url,
        'https://test.omni-link.net/storage/1198/Screenshot-2026-09-20-172245.png',
      );
    });

    test('parses multiple invoices correctly', () {
      final secondInvoice = <String, dynamic>{
        'id': 1200,
        'file_name': 'invoice2.png',
        'mime_type': 'image/png',
        'size': 10000,
        'url': 'https://test.omni-link.net/storage/1200/invoice2.png',
        'created_at': '2026-09-26T12:00:00+00:00',
      };
      final json = _baseOrderJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices': [_invoiceJson, secondInvoice],
      });

      final order = OrderDetails.fromJson(json);

      expect(order.externalWarehouseInvoices.length, 2);
      expect(order.externalWarehouseInvoices[0].id, 1198);
      expect(order.externalWarehouseInvoices[1].id, 1200);
    });

    test('hasExternalWarehouseInvoice is false when both flag and list are absent', () {
      final json = _baseOrderJson();
      final order = OrderDetails.fromJson(json);

      expect(order.hasExternalWarehouseInvoice, isFalse);
      expect(order.externalWarehouseInvoices, isEmpty);
    });

    test('hasExternalWarehouseInvoice is false when flag is false and list is empty', () {
      final json = _baseOrderJson(overrides: {
        'has_external_warehouse_invoice': false,
        'external_warehouse_invoices': <dynamic>[],
      });
      final order = OrderDetails.fromJson(json);

      expect(order.hasExternalWarehouseInvoice, isFalse);
      expect(order.externalWarehouseInvoices, isEmpty);
    });
  });

  // ── 3. Backward compatibility ────────────────────────────────────────────
  group('OrderDetails – backward compatibility (old responses without invoice fields)', () {
    test('parses successfully when both invoice fields are missing from JSON', () {
      // Simulates old backend responses that do not yet include the new fields.
      final json = _baseOrderJson();
      expect(() => OrderDetails.fromJson(json), returnsNormally);
    });

    test('externalWarehouseInvoices defaults to an empty list when key is missing', () {
      final order = OrderDetails.fromJson(_baseOrderJson());
      expect(order.externalWarehouseInvoices, isEmpty);
    });

    test('hasExternalWarehouseInvoice defaults to false when key is missing', () {
      final order = OrderDetails.fromJson(_baseOrderJson());
      expect(order.hasExternalWarehouseInvoice, isFalse);
    });

    test('null value for external_warehouse_invoices is treated as empty list', () {
      final json = _baseOrderJson(overrides: {
        'has_external_warehouse_invoice': null,
        'external_warehouse_invoices': null,
      });
      final order = OrderDetails.fromJson(json);

      expect(order.externalWarehouseInvoices, isEmpty);
      expect(order.hasExternalWarehouseInvoice, isFalse);
    });
  });

  // ── 4. Flag derivation logic ─────────────────────────────────────────────
  group('hasExternalWarehouseInvoice flag derivation', () {
    test('is true when flag is true but list is empty (flag takes precedence)', () {
      final json = _baseOrderJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices': <dynamic>[],
      });
      final order = OrderDetails.fromJson(json);

      // Even with an empty list, a truthy backend flag must be respected.
      expect(order.hasExternalWarehouseInvoice, isTrue);
    });

    test('is true when flag is false but list is non-empty (list content takes precedence)', () {
      final json = _baseOrderJson(overrides: {
        'has_external_warehouse_invoice': false,
        'external_warehouse_invoices': [_invoiceJson],
      });
      final order = OrderDetails.fromJson(json);

      // Defensive: if the list has items the flag should reflect that.
      expect(order.hasExternalWarehouseInvoice, isTrue);
      expect(order.externalWarehouseInvoices.length, 1);
    });
  });

  // ── 5. Robustness: mixed list content ────────────────────────────────────
  group('OrderDetails – robustness when list contains non-Map entries', () {
    test('silently skips plain string entries in the invoice list', () {
      final json = _baseOrderJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices': [
          'https://not-an-object.example.com/plain-url.png',
          _invoiceJson, // valid entry
        ],
      });

      final order = OrderDetails.fromJson(json);

      // The plain string must be skipped; only the valid Map is parsed.
      expect(order.externalWarehouseInvoices.length, 1);
      expect(order.externalWarehouseInvoices.first.id, 1198);
    });
  });

  // ── 6. Equatable / props integrity ───────────────────────────────────────
  group('OrderDetails – Equatable props include new fields', () {
    test('two identical orders with same invoices are equal', () {
      final json = _baseOrderJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices': [_invoiceJson],
      });

      final a = OrderDetails.fromJson(json);
      final b = OrderDetails.fromJson(json);
      expect(a, equals(b));
    });

    test('orders differ when invoice lists differ', () {
      final withInvoice = OrderDetails.fromJson(_baseOrderJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices': [_invoiceJson],
      }));

      final withoutInvoice = OrderDetails.fromJson(_baseOrderJson(overrides: {
        'has_external_warehouse_invoice': false,
        'external_warehouse_invoices': <dynamic>[],
      }));

      expect(withInvoice, isNot(equals(withoutInvoice)));
    });
  });

  // ── 7. OrderSummary: external warehouse invoice field parsing ─────────────
  group('OrderSummary – external_warehouse_invoice field parsing', () {
    test('parses has_external_warehouse_invoice: false + count 0 correctly', () {
      final json = _baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': false,
        'external_warehouse_invoices_count': 0,
      });

      final order = OrderSummary.fromJson(json);

      expect(order.hasExternalWarehouseInvoice, isFalse);
      expect(order.externalWarehouseInvoicesCount, 0);
    });

    test('parses has_external_warehouse_invoice: true + count 1 correctly', () {
      final json = _baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices_count': 1,
      });

      final order = OrderSummary.fromJson(json);

      expect(order.hasExternalWarehouseInvoice, isTrue);
      expect(order.externalWarehouseInvoicesCount, 1);
    });

    test('parses has_external_warehouse_invoice: true + count greater than 1 correctly', () {
      final json = _baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices_count': 2,
      });

      final order = OrderSummary.fromJson(json);

      expect(order.hasExternalWarehouseInvoice, isTrue);
      expect(order.externalWarehouseInvoicesCount, 2);

      final json5 = _baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices_count': 5,
      });

      final order5 = OrderSummary.fromJson(json5);

      expect(order5.hasExternalWarehouseInvoice, isTrue);
      expect(order5.externalWarehouseInvoicesCount, 5);
    });
  });

  // ── 8. OrderSummary: backward compatibility and null safety ──────────────
  group('OrderSummary – backward compatibility and null safety', () {
    test('missing invoice keys default to false and 0 without crash', () {
      final json = _baseOrderSummaryJson(); // lacks invoice keys
      final order = OrderSummary.fromJson(json);

      expect(order.hasExternalWarehouseInvoice, isFalse);
      expect(order.externalWarehouseInvoicesCount, 0);
    });

    test('null values for invoice keys default to false and 0 without crash', () {
      final json = _baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': null,
        'external_warehouse_invoices_count': null,
      });
      final order = OrderSummary.fromJson(json);

      expect(order.hasExternalWarehouseInvoice, isFalse);
      expect(order.externalWarehouseInvoicesCount, 0);
    });

    test('string numbers and truthy string values are safely parsed', () {
      final json = _baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': 'true',
        'external_warehouse_invoices_count': '3',
      });
      final order = OrderSummary.fromJson(json);

      expect(order.hasExternalWarehouseInvoice, isTrue);
      expect(order.externalWarehouseInvoicesCount, 3);
    });

    test('numeric flag values (1/0) are safely parsed', () {
      final jsonTrue = _baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': 1,
        'external_warehouse_invoices_count': 4,
      });
      final orderTrue = OrderSummary.fromJson(jsonTrue);
      expect(orderTrue.hasExternalWarehouseInvoice, isTrue);
      expect(orderTrue.externalWarehouseInvoicesCount, 4);

      final jsonFalse = _baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': 0,
        'external_warehouse_invoices_count': 0,
      });
      final orderFalse = OrderSummary.fromJson(jsonFalse);
      expect(orderFalse.hasExternalWarehouseInvoice, isFalse);
      expect(orderFalse.externalWarehouseInvoicesCount, 0);
    });
  });

  // ── 9. OrderSummary: Equatable props ──────────────────────────────────────
  group('OrderSummary – Equatable props include new fields', () {
    test('two identical summaries are equal', () {
      final json = _baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices_count': 2,
      });

      final a = OrderSummary.fromJson(json);
      final b = OrderSummary.fromJson(json);

      expect(a, equals(b));
    });

    test('summaries differ when invoice flag or count differs', () {
      final a = OrderSummary.fromJson(_baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices_count': 2,
      }));
      final b = OrderSummary.fromJson(_baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': false,
        'external_warehouse_invoices_count': 0,
      }));
      final c = OrderSummary.fromJson(_baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices_count': 3,
      }));

      expect(a, isNot(equals(b)));
      expect(a, isNot(equals(c)));
    });
  });

  // ── 10. OrderCard: external warehouse invoice rendering ───────────────────
  group('OrderCard – external warehouse invoice indicator UI', () {
    Widget buildCard(OrderSummary order) {
      return MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: OrderCard(
              order: order,
              onTap: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders uploaded state with checkmark and count', (tester) async {
      final order = OrderSummary.fromJson(_baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices_count': 2,
      }));

      await tester.pumpWidget(buildCard(order));

      // Label and count are visible
      expect(find.textContaining('فاتورة المخزن'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            w.textSpan != null &&
            w.textSpan!.toPlainText().contains('فاتورة المخزن') &&
            w.textSpan!.toPlainText().contains('2')),
        findsOneWidget,
      );

      // Checkmark icon is displayed for the uploaded invoice
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders count 1 with checkmark when 1 invoice exists', (tester) async {
      final order = OrderSummary.fromJson(_baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': true,
        'external_warehouse_invoices_count': 1,
      }));

      await tester.pumpWidget(buildCard(order));

      expect(find.textContaining('فاتورة المخزن'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            w.textSpan != null &&
            w.textSpan!.toPlainText().contains('فاتورة المخزن') &&
            w.textSpan!.toPlainText().contains('1')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders not-uploaded state with cancel icon and count 0', (tester) async {
      final order = OrderSummary.fromJson(_baseOrderSummaryJson(overrides: {
        'has_external_warehouse_invoice': false,
        'external_warehouse_invoices_count': 0,
      }));

      await tester.pumpWidget(buildCard(order));

      expect(find.textContaining('فاتورة المخزن'), findsOneWidget);
      // All 3 photo indicators (shipment, waybill, invoice) show not-uploaded cancel icon
      expect(find.byIcon(Icons.cancel_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });
  });
}
