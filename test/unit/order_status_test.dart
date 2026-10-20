import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status_tab_mapper.dart';
import 'package:warehouse_store_keeper/features/orders/models/orders_tab.dart';

void main() {
  group('OrderStatus Model & Filtering Rules', () {
    // -------------------------------------------------------------------
    // Open Orders: confirmed | processing | shipped
    // -------------------------------------------------------------------
    test('Open Orders statuses include confirmed, processing, and shipped', () {
      expect(OrderStatus.confirmed.isOpen, isTrue);
      expect(OrderStatus.processing.isOpen, isTrue);
      expect(OrderStatus.shipped.isOpen, isTrue);

      expect(OrderStatus.delivered.isOpen, isFalse);
      expect(OrderStatus.pending.isOpen, isFalse);
      expect(OrderStatus.cancelled.isOpen, isFalse);
    });

    // -------------------------------------------------------------------
    // Completed Orders: delivered only
    // -------------------------------------------------------------------
    test('Completed Orders statuses include delivered only', () {
      expect(OrderStatus.delivered.isCompleted, isTrue);

      // shipped now belongs to Open, not Completed
      expect(OrderStatus.shipped.isCompleted, isFalse);
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
      expect(OrderStatus.fromString('refused_delivery'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('refused'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('رفض الاستلام'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('تم رفض الاستلام'), OrderStatus.cancelled);
    });

    test('OrderStatus.fromString gracefully handles unknown or null values without crashing', () {
      expect(OrderStatus.fromString(null), OrderStatus.unknown);
      expect(OrderStatus.fromString(''), OrderStatus.unknown);
      expect(OrderStatus.fromString('some_future_status'), OrderStatus.unknown);
      expect(OrderStatus.unknown.isIgnored, isTrue);
    });

    // -------------------------------------------------------------------
    // State transition: processing → shipped
    //   Order remains in Open section (shipped = Open)
    // -------------------------------------------------------------------
    test('processing → shipped: status stays in Open Orders', () {
      // Before: order is processing (Open)
      expect(OrderStatus.processing.isOpen, isTrue);
      expect(OrderStatus.processing.isCompleted, isFalse);

      // After: order becomes shipped — still Open
      expect(OrderStatus.shipped.isOpen, isTrue);
      expect(OrderStatus.shipped.isCompleted, isFalse);
    });

    // -------------------------------------------------------------------
    // State transition: shipped → delivered
    //   Order moves from Open to Completed
    // -------------------------------------------------------------------
    test('shipped → delivered: order moves from Open to Completed section', () {
      // shipped is Open
      expect(OrderStatus.shipped.isOpen, isTrue);
      expect(OrderStatus.shipped.isCompleted, isFalse);

      // delivered is Completed
      expect(OrderStatus.delivered.isCompleted, isTrue);
      expect(OrderStatus.delivered.isOpen, isFalse);
    });

    // -------------------------------------------------------------------
    // Centralized Status-to-Tab Mapping (Requirement 2 & Scenarios 1-3)
    // -------------------------------------------------------------------
    test('Centralized mapping: cancelled activates completed tab', () {
      expect(OrderStatus.cancelled.targetTab, OrdersTab.completed);
      expect(OrderStatusTabMapper.getTabForStatus(OrderStatus.cancelled), OrdersTab.completed);
      expect(OrderStatusTabMapper.isStatusCompatibleWithTab(OrderStatus.cancelled, OrdersTab.completed), isTrue);
      expect(OrderStatusTabMapper.isStatusCompatibleWithTab(OrderStatus.cancelled, OrdersTab.open), isFalse);
    });

    test('Centralized mapping: pending, confirmed, processing activate open tab', () {
      expect(OrderStatus.pending.targetTab, OrdersTab.open);
      expect(OrderStatus.confirmed.targetTab, OrdersTab.open);
      expect(OrderStatus.processing.targetTab, OrdersTab.open);

      expect(OrderStatusTabMapper.getTabForStatus(OrderStatus.pending), OrdersTab.open);
      expect(OrderStatusTabMapper.getTabForStatus(OrderStatus.confirmed), OrdersTab.open);
      expect(OrderStatusTabMapper.getTabForStatus(OrderStatus.processing), OrdersTab.open);
    });

    test('Centralized mapping: shipped activates open tab; delivered activates completed tab', () {
      expect(OrderStatus.shipped.targetTab, OrdersTab.open);
      expect(OrderStatus.delivered.targetTab, OrdersTab.completed);

      expect(OrderStatusTabMapper.getTabForStatus(OrderStatus.shipped), OrdersTab.open);
      expect(OrderStatusTabMapper.getTabForStatus(OrderStatus.delivered), OrdersTab.completed);
    });
  });
}
