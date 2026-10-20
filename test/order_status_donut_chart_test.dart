import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_state.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/order_status_donut_chart.dart';

void main() {
  group('OrderStatusDonutChart Widget Tests', () {
    final sampleItems = [
      const StatusStatItem(
        label: 'قيد الانتظار',
        count: 12,
        color: Color(0xFF64748B),
        filterKey: 'pending',
        targetTab: OrdersTab.open,
      ),
      const StatusStatItem(
        label: 'قيد المعالجة',
        count: 8,
        color: Color(0xFFD97706),
        filterKey: 'processing',
        targetTab: OrdersTab.open,
      ),
      const StatusStatItem(
        label: 'مكتملة',
        count: 4,
        color: Color(0xFF16A34A),
        filterKey: 'shipped',
        targetTab: OrdersTab.completed,
      ),
      const StatusStatItem(
        label: 'ملغاة',
        count: 2,
        color: Color(0xFF2563EB),
        filterKey: 'cancelled',
        targetTab: OrdersTab.open,
      ),
    ];

    testWidgets('renders title, subtitle, total orders count and label',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: OrderStatusDonutChart(
                items: sampleItems,
                totalOrders: 26,
                onStatusSelected: (_, {filterStatus}) {},
                onTotalSelected: () {},
              ),
            ),
          ),
        ),
      );

      // Verify title and subtitle
      expect(find.text('إحصائيات حالات الطلبات'), findsOneWidget);
      expect(find.text('توزيع جميع الطلبات'), findsOneWidget);

      // Verify center total and label
      expect(find.text('26'), findsOneWidget);
      expect(find.text('إجمالي الطلبات'), findsOneWidget);

      // Verify status legend labels
      expect(find.text('قيد الانتظار'), findsOneWidget);
      expect(find.text('قيد المعالجة'), findsOneWidget);
      expect(find.text('مكتملة'), findsOneWidget);
      expect(find.text('ملغاة'), findsOneWidget);

      // Verify counts formatted with leading zeros
      expect(find.text('12'), findsOneWidget);
      expect(find.text('08'), findsOneWidget);
      expect(find.text('04'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);

      // Verify calculated percentages: 12/26 = 46.2%, 8/26 = 30.8%, 4/26 = 15.4%, 2/26 = 7.7%
      expect(find.text('46.2%'), findsOneWidget);
      expect(find.text('30.8%'), findsOneWidget);
      expect(find.text('15.4%'), findsOneWidget);
      expect(find.text('7.7%'), findsOneWidget);
    });

    testWidgets('handles zero total orders gracefully without errors',
        (tester) async {
      final emptyItems = [
        const StatusStatItem(
          label: 'قيد الانتظار',
          count: 0,
          color: Color(0xFF64748B),
          targetTab: OrdersTab.open,
        ),
        const StatusStatItem(
          label: 'قيد المعالجة',
          count: 0,
          color: Color(0xFFD97706),
          targetTab: OrdersTab.open,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: OrderStatusDonutChart(
                items: emptyItems,
                totalOrders: 0,
                onStatusSelected: (_, {filterStatus}) {},
                onTotalSelected: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('لا توجد طلبات مسجلة حالياً'), findsOneWidget);
    });

    testWidgets('tapping status row triggers onStatusSelected callback',
        (tester) async {
      String? selectedFilter;
      OrdersTab? selectedTab;

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: OrderStatusDonutChart(
                items: sampleItems,
                totalOrders: 26,
                onStatusSelected: (tab, {filterStatus}) {
                  selectedTab = tab;
                  selectedFilter = filterStatus;
                },
                onTotalSelected: () {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('قيد المعالجة'));
      expect(selectedTab, OrdersTab.open);
      expect(selectedFilter, 'processing');

      await tester.tap(find.text('مكتملة'));
      expect(selectedTab, OrdersTab.completed);
      expect(selectedFilter, 'shipped');
    });

    testWidgets('tapping center total triggers onTotalSelected callback',
        (tester) async {
      bool totalTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: OrderStatusDonutChart(
                items: sampleItems,
                totalOrders: 26,
                onStatusSelected: (_, {filterStatus}) {},
                onTotalSelected: () {
                  totalTapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('إجمالي الطلبات'));
      expect(totalTapped, isTrue);
    });
  });
}
