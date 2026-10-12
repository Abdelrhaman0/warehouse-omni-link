import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/order_status_badge.dart';

void main() {
  group('OrderStatusBadge display tests', () {
    testWidgets('shows exact response string when cancelled with "إلغيت"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderStatusBadge(
              status: OrderStatus.cancelled,
              rawStatus: 'إلغيت',
            ),
          ),
        ),
      );

      expect(find.text('إلغيت'), findsOneWidget);
    });

    testWidgets('shows exact response string when cancelled with "cancelled"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderStatusBadge(
              status: OrderStatus.cancelled,
              rawStatus: 'cancelled',
            ),
          ),
        ),
      );

      expect(find.text('cancelled'), findsOneWidget);
    });

    testWidgets('shows exact response string when cancelled with "ألغيت"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderStatusBadge(
              status: OrderStatus.cancelled,
              rawStatus: 'ألغيت',
            ),
          ),
        ),
      );

      expect(find.text('ألغيت'), findsOneWidget);
    });

    testWidgets('falls back to localizedLabel when rawStatus is null or empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderStatusBadge(
              status: OrderStatus.cancelled,
            ),
          ),
        ),
      );

      expect(find.text(OrderStatus.cancelled.localizedLabel), findsOneWidget);
    });

    testWidgets('shows rawStatus for unknown status instead of fallback text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderStatusBadge(
              status: OrderStatus.unknown,
              rawStatus: 'custom_status',
            ),
          ),
        ),
      );

      expect(find.text('custom_status'), findsOneWidget);
    });
  });
}
