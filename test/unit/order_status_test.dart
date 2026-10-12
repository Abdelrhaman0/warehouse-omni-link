import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';

void main() {
  group('OrderStatus Model & Filtering Rules', () {
    // -------------------------------------------------------------------
    // Open Orders: confirmed | processing
    // -------------------------------------------------------------------
    test('Open Orders statuses include ONLY confirmed and processing', () {
      expect(OrderStatus.confirmed.isOpen, isTrue);
      expect(OrderStatus.processing.isOpen, isTrue);

      // shipped now belongs to Completed, not Open
      expect(OrderStatus.shipped.isOpen, isFalse);
      expect(OrderStatus.delivered.isOpen, isFalse);
      expect(OrderStatus.pending.isOpen, isFalse);
      expect(OrderStatus.cancelled.isOpen, isFalse);
    });

    // -------------------------------------------------------------------
    // Completed Orders: shipped | delivered
    // -------------------------------------------------------------------
    test('Completed Orders statuses include shipped and delivered', () {
      expect(OrderStatus.shipped.isCompleted, isTrue);
      expect(OrderStatus.delivered.isCompleted, isTrue);

      // confirmed and processing belong to Open, not Completed
      expect(OrderStatus.confirmed.isCompleted, isFalse);
      expect(OrderStatus.processing.isCompleted, isFalse);
      expect(OrderStatus.pending.isCompleted, isFalse);
      expect(OrderStatus.cancelled.isCompleted, isFalse);
    });

    // -------------------------------------------------------------------
    // Ignored: pending | cancelled | unknown — never shown anywhere
    // -------------------------------------------------------------------
    test('Completely ignored/hidden statuses include pending, cancelled, unknown', () {
      expect(OrderStatus.pending.isIgnored, isTrue);
      expect(OrderStatus.cancelled.isIgnored, isTrue);
      expect(OrderStatus.unknown.isIgnored, isTrue);

      expect(OrderStatus.confirmed.isIgnored, isFalse);
      expect(OrderStatus.processing.isIgnored, isFalse);
      expect(OrderStatus.shipped.isIgnored, isFalse);
      expect(OrderStatus.delivered.isIgnored, isFalse);
    });

    // -------------------------------------------------------------------
    // No status should be in both Open and Completed simultaneously
    // -------------------------------------------------------------------
    test('No status belongs to both Open and Completed', () {
      for (final status in OrderStatus.values) {
        expect(
          status.isOpen && status.isCompleted,
          isFalse,
          reason: 'Status ${status.apiValue} must not be both Open and Completed',
        );
      }
    });

    // -------------------------------------------------------------------
    // Exact backend string parsing
    // -------------------------------------------------------------------
    test('OrderStatus.fromString parses exact backend values (both English and Arabic localized)', () {
      expect(OrderStatus.fromString('pending'), OrderStatus.pending);
      expect(OrderStatus.fromString('confirmed'), OrderStatus.confirmed);
      expect(OrderStatus.fromString('processing'), OrderStatus.processing);
      // The backend value is exactly "shipped", never "shipping"
      expect(OrderStatus.fromString('shipped'), OrderStatus.shipped);
      expect(OrderStatus.fromString('delivered'), OrderStatus.delivered);
      expect(OrderStatus.fromString('cancelled'), OrderStatus.cancelled);

      // Real Arabic status strings returned by the backend in localized API
      expect(OrderStatus.fromString('تم التأكيد'), OrderStatus.confirmed);
      expect(OrderStatus.fromString('جاري المعالجة'), OrderStatus.processing);
      expect(OrderStatus.fromString('تم الشحن'), OrderStatus.shipped);
      expect(OrderStatus.fromString('تم التوصيل'), OrderStatus.delivered);
      expect(OrderStatus.fromString('معلق'), OrderStatus.pending);
      expect(OrderStatus.fromString('ملغي'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('إلغيت'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('ألغيت'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('الغيت'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('canceled'), OrderStatus.cancelled);
    });

    test('OrderStatus.fromString gracefully handles unknown or null values without crashing', () {
      expect(OrderStatus.fromString(null), OrderStatus.unknown);
      expect(OrderStatus.fromString(''), OrderStatus.unknown);
      expect(OrderStatus.fromString('some_future_status'), OrderStatus.unknown);
      expect(OrderStatus.unknown.isIgnored, isTrue);
    });

    // -------------------------------------------------------------------
    // State transition: processing → shipped
    //   Order leaves Open, appears in Completed
    // -------------------------------------------------------------------
    test('processing → shipped: status leaves Open and enters Completed', () {
      // Before: order is processing (Open)
      expect(OrderStatus.processing.isOpen, isTrue);
      expect(OrderStatus.processing.isCompleted, isFalse);

      // After: order becomes shipped (Completed)
      expect(OrderStatus.shipped.isOpen, isFalse);
      expect(OrderStatus.shipped.isCompleted, isTrue);
    });

    // -------------------------------------------------------------------
    // State transition: shipped → delivered
    //   Order remains in Completed (status label updates)
    // -------------------------------------------------------------------
    test('shipped → delivered: order remains in Completed section', () {
      // Both shipped and delivered are Completed
      expect(OrderStatus.shipped.isCompleted, isTrue);
      expect(OrderStatus.delivered.isCompleted, isTrue);

      // Neither is Open
      expect(OrderStatus.shipped.isOpen, isFalse);
      expect(OrderStatus.delivered.isOpen, isFalse);
    });
  });
}
