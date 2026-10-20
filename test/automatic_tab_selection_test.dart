import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/features/orders/data/orders_repository.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_summary.dart';
import 'package:warehouse_store_keeper/features/orders/models/paginated_orders.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_state.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/screens/home_orders_screen.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  late MockOrdersRepository mockRepo;
  late OrdersCubit cubit;

  const sampleOpenOrder = OrderSummary(
    id: 101,
    orderNumber: 'ORD-101',
    status: OrderStatus.confirmed,
    rawStatus: 'confirmed',
    customerName: 'Customer Confirmed',
    itemsCount: 2,
    canUploadPhotos: true,
    hasShipmentPhotos: false,
    hasWaybillPhotos: false,
    shipmentPhotosCount: 0,
    waybillPhotosCount: 0,
  );

  const sampleCancelledOrder = OrderSummary(
    id: 102,
    orderNumber: 'ORD-102',
    status: OrderStatus.cancelled,
    rawStatus: 'cancelled',
    customerName: 'Customer Cancelled',
    itemsCount: 1,
    canUploadPhotos: false,
    hasShipmentPhotos: false,
    hasWaybillPhotos: false,
    shipmentPhotosCount: 0,
    waybillPhotosCount: 0,
  );

  setUp(() {
    mockRepo = MockOrdersRepository();

    when(() => mockRepo.getOpenOrders(
          page: any(named: 'page'),
          tab: any(named: 'tab'),
          status: any(named: 'status'),
        )).thenAnswer(
      (_) async => const PaginatedOrders(
        currentPage: 1,
        lastPage: 1,
        perPage: 30,
        total: 1,
        orders: [sampleOpenOrder],
      ),
    );

    when(() => mockRepo.getCompletedOrders(
          page: any(named: 'page'),
          status: any(named: 'status'),
        )).thenAnswer(
      (_) async => const PaginatedOrders(
        currentPage: 1,
        lastPage: 1,
        perPage: 30,
        total: 1,
        orders: [sampleCancelledOrder],
      ),
    );

    cubit = OrdersCubit(ordersRepository: mockRepo);
  });

  tearDown(() {
    cubit.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider<OrdersCubit>.value(
          value: cubit,
          child: const HomeOrdersScreen(initialNavIndex: 1),
        ),
      ),
    );
  }

  group('HomeOrdersScreen - Automatic Tab Selection on Status Filter', () {
    testWidgets('Selecting Cancelled status automatically activates Completed Orders tab', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initial tab is Open orders (index 0)
      expect(cubit.state.currentTab, OrdersTab.open);
      expect(find.text('ORD-101'), findsOneWidget);

      // Open status filter dropdown sheet
      await tester.tap(find.text('كل الحالات'));
      await tester.pumpAndSettle();

      // Tap on "إلغيت" (Cancelled)
      final cancelledTile = find.descendant(
        of: find.byType(ListTile),
        matching: find.text(OrderStatus.cancelled.localizedLabel),
      );
      expect(cancelledTile, findsOneWidget);
      await tester.tap(cancelledTile);
      await tester.pumpAndSettle();

      // Verified: Cubit state currentTab is now OrdersTab.completed
      expect(cubit.state.currentTab, OrdersTab.completed);
      expect(cubit.state.selectedStatus, OrderStatus.cancelled);

      // Verified: Dropdown button displays "إلغيت"
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.data == OrderStatus.cancelled.localizedLabel &&
              w.style?.fontSize == 13,
        ),
        findsOneWidget,
      );

      // Verified: Request was made to getCompletedOrders with status=cancelled
      verify(() => mockRepo.getCompletedOrders(page: 1, status: 'cancelled')).called(1);

      // Cancelled order is displayed in the completed tab
      expect(find.text('ORD-102'), findsOneWidget);
    });

    testWidgets('Selecting Confirmed status activates Open Orders tab', (tester) async {
      // Start in completed tab
      cubit.switchTab(OrdersTab.completed);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cubit.state.currentTab, OrdersTab.completed);

      // Open status filter dropdown sheet
      await tester.tap(find.text('كل الحالات'));
      await tester.pumpAndSettle();

      // Tap on "مؤكد" (Confirmed)
      final confirmedTile = find.descendant(
        of: find.byType(ListTile),
        matching: find.text(OrderStatus.confirmed.localizedLabel),
      );
      await tester.tap(confirmedTile);
      await tester.pumpAndSettle();

      // Verified: Tab automatically switched to Open orders
      expect(cubit.state.currentTab, OrdersTab.open);
      expect(cubit.state.selectedStatus, OrderStatus.confirmed);

      // Dropdown button shows "مؤكد"
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.data == OrderStatus.confirmed.localizedLabel &&
              w.style?.fontSize == 13,
        ),
        findsOneWidget,
      );

      verify(() => mockRepo.getOpenOrders(page: 1, tab: 'pending', status: 'confirmed')).called(1);
    });
  });
}
