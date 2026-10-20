import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/core/localization/app_strings.dart';
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

  final List<OrderSummary> sampleOrders = [
    const OrderSummary(
      id: 101,
      orderNumber: 'ORD-101',
      status: OrderStatus.confirmed,
      rawStatus: 'confirmed',
      customerName: 'أحمد محمد',
      itemsCount: 3,
      canUploadPhotos: true,
      hasShipmentPhotos: false,
      hasWaybillPhotos: false,
      shipmentPhotosCount: 0,
      waybillPhotosCount: 0,
      createdAt: '2026-10-15',
    ),
    const OrderSummary(
      id: 102,
      orderNumber: 'ORD-102',
      status: OrderStatus.processing,
      rawStatus: 'processing',
      customerName: 'سارة خالد',
      itemsCount: 5,
      canUploadPhotos: true,
      hasShipmentPhotos: false,
      hasWaybillPhotos: false,
      shipmentPhotosCount: 0,
      waybillPhotosCount: 0,
      createdAt: '2026-10-15',
    ),
  ];

  setUp(() {
    mockRepo = MockOrdersRepository();
    when(() => mockRepo.getOpenOrders(
          page: any(named: 'page'),
          tab: any(named: 'tab'),
          status: any(named: 'status'),
        )).thenAnswer(
      (_) async => PaginatedOrders(
        currentPage: 1,
        lastPage: 1,
        perPage: 10,
        total: sampleOrders.length,
        orders: sampleOrders,
      ),
    );

    when(() => mockRepo.getCompletedOrders(
          page: any(named: 'page'),
          status: any(named: 'status'),
        )).thenAnswer(
      (_) async => const PaginatedOrders(
        currentPage: 1,
        lastPage: 1,
        perPage: 10,
        total: 0,
        orders: [],
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
          child: const HomeOrdersScreen(),
        ),
      ),
    );
  }

  testWidgets('Orders Header Redesign: Verification of components and removals',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 1. "اليوم" and "الأولوية" are completely removed
    expect(find.text('اليوم'), findsNothing);
    expect(find.text('الأولوية'), findsNothing);

    // 2. Title row: "الطلبات" and compact outlined status dropdown "كل الحالات"
    // Note: "الطلبات" also appears in the bottom navigation bar label, so we verify both exist and find the header one
    expect(find.text('الطلبات'), findsNWidgets(2));
    final headerTitleFinder = find.byWidgetPredicate(
      (w) => w is Text && w.data == 'الطلبات' && w.style?.fontSize == 21,
    );
    expect(headerTitleFinder, findsOneWidget);
    expect(find.text('كل الحالات'), findsOneWidget);

    // Verify RTL alignment: "الطلبات" is on the right (start), dropdown on left (end)
    final titleRect = tester.getRect(headerTitleFinder);
    final statusRect = tester.getRect(find.text('كل الحالات'));
    expect(titleRect.right > statusRect.right, isTrue,
        reason: 'Title should be to the right of the status dropdown in RTL');

    // 3. Search field: full width with correct placeholder and icon
    expect(find.text('رقم الطلب أو اسم العميل'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);

    // 4. Tabs: "الطلبات المفتوحة" and "الطلبات المكتملة"
    expect(find.text(AppStrings.openOrders), findsOneWidget);
    expect(find.text(AppStrings.completedOrders), findsOneWidget);

    // 5. Photography filters: "الكل", "تحتاج تصوير", "تم تصويرها"
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('تحتاج تصوير'), findsOneWidget);
    expect(find.text('تم تصويرها'), findsOneWidget);

    // "الكل" is selected by default with checkmark icon
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('Status filter dropdown opens sheet and filters order list',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify both orders are initially shown
    expect(find.text('ORD-101'), findsOneWidget);
    expect(find.text('ORD-102'), findsOneWidget);

    // Tap the status dropdown
    await tester.tap(find.text('كل الحالات'));
    await tester.pumpAndSettle();

    // Bottom sheet is open
    expect(find.text('تصفية حسب الحالة'), findsOneWidget);

    // Select "مؤكد" (confirmed) from the bottom sheet ListTile
    final bottomSheetItem = find.descendant(
      of: find.byType(ListTile),
      matching: find.text(OrderStatus.confirmed.localizedLabel),
    );
    await tester.tap(bottomSheetItem);
    await tester.pumpAndSettle();

    // Dropdown now displays "مؤكد"
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.data == OrderStatus.confirmed.localizedLabel &&
            w.style?.fontSize == 13,
      ),
      findsOneWidget,
    );

    // Only ORD-101 is visible, ORD-102 is filtered out
    expect(find.text('ORD-101'), findsOneWidget);
    expect(find.text('ORD-102'), findsNothing);
  });

  testWidgets('Search field filters correctly with English and Arabic numerals',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Search by customer name
    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'سارة');
    await tester.pump();

    expect(find.text('ORD-101'), findsNothing);
    expect(find.text('ORD-102'), findsOneWidget);

    // Search by Eastern Arabic numerals for order ID (١٠١ => 101)
    await tester.enterText(searchField, '١٠١');
    await tester.pump();

    expect(find.text('ORD-101'), findsOneWidget);
    expect(find.text('ORD-102'), findsNothing);
  });

  testWidgets('Photography filter updates active filter and triggers cubit',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap "تحتاج تصوير"
    await tester.tap(find.text('تحتاج تصوير'));
    await tester.pump();

    expect(cubit.state.openPhotosFilter, equals(PhotosFilter.withoutPhotos));
    verify(() => mockRepo.getOpenOrders(
          page: 1,
          tab: PhotosFilter.withoutPhotos.backendTab,
        )).called(1);
  });
}
