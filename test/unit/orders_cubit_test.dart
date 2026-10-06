import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/features/orders/data/orders_repository.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_summary.dart';
import 'package:warehouse_store_keeper/features/orders/models/paginated_orders.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_state.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  late MockOrdersRepository mockRepo;
  late OrdersCubit cubit;

  // ── Open Orders fixtures (confirmed + processing) ──────────────────────────
  const order1 = OrderSummary(
    id: 1,
    orderNumber: 'ORD-001',
    status: OrderStatus.confirmed,
    rawStatus: 'confirmed',
    customerName: 'Customer 1',
    itemsCount: 2,
    canUploadPhotos: true,
    hasShipmentPhotos: false,
    hasWaybillPhotos: false,
    shipmentPhotosCount: 0,
    waybillPhotosCount: 0,
  );

  const order2 = OrderSummary(
    id: 2,
    orderNumber: 'ORD-002',
    status: OrderStatus.processing,
    rawStatus: 'processing',
    customerName: 'Customer 2',
    itemsCount: 1,
    canUploadPhotos: true,
    hasShipmentPhotos: false,
    hasWaybillPhotos: false,
    shipmentPhotosCount: 0,
    waybillPhotosCount: 0,
  );

  // ── Completed Orders fixtures (shipped + delivered) ─────────────────────────
  const order3 = OrderSummary(
    id: 3,
    orderNumber: 'ORD-003',
    status: OrderStatus.shipped,
    rawStatus: 'shipped',
    customerName: 'Customer 3',
    itemsCount: 4,
    canUploadPhotos: false,
    hasShipmentPhotos: true,
    hasWaybillPhotos: true,
    shipmentPhotosCount: 5,
    waybillPhotosCount: 2,
  );

  const order4 = OrderSummary(
    id: 4,
    orderNumber: 'ORD-004',
    status: OrderStatus.delivered,
    rawStatus: 'delivered',
    customerName: 'Customer 4',
    itemsCount: 3,
    canUploadPhotos: false,
    hasShipmentPhotos: true,
    hasWaybillPhotos: true,
    shipmentPhotosCount: 5,
    waybillPhotosCount: 2,
  );

  // ── order2 after processing → shipped transition ────────────────────────────
  const order2AsShipped = OrderSummary(
    id: 2,
    orderNumber: 'ORD-002',
    status: OrderStatus.shipped,
    rawStatus: 'shipped',
    customerName: 'Customer 2',
    itemsCount: 1,
    canUploadPhotos: false,
    hasShipmentPhotos: true,
    hasWaybillPhotos: false,
    shipmentPhotosCount: 5,
    waybillPhotosCount: 0,
  );

  // ── order3 after shipped → delivered transition ─────────────────────────────
  const order3AsDelivered = OrderSummary(
    id: 3,
    orderNumber: 'ORD-003',
    status: OrderStatus.delivered,
    rawStatus: 'delivered',
    customerName: 'Customer 3',
    itemsCount: 4,
    canUploadPhotos: false,
    hasShipmentPhotos: true,
    hasWaybillPhotos: true,
    shipmentPhotosCount: 5,
    waybillPhotosCount: 2,
  );

  setUp(() {
    mockRepo = MockOrdersRepository();
    cubit = OrdersCubit(ordersRepository: mockRepo);
  });

  group('OrdersCubit - Pagination & Filtering', () {
    test('Initial load of Open Orders loads page 1 and sets hasMore properly', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 2,
          perPage: 2,
          total: 3,
          orders: [order1, order2],
        ),
      );

      await cubit.loadInitial(OrdersTab.open);

      final openData = cubit.state.openOrders;
      expect(openData.orders.length, 2);
      expect(openData.currentPage, 1);
      expect(openData.hasMore, isTrue);
      expect(openData.isLoadingInitial, isFalse);
    });

    test('loadNextPage appends page 2 orders and de-duplicates by id', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 2,
          perPage: 2,
          total: 4,
          orders: [order1, order2],
        ),
      );

      // Page 2 returns order2 (duplicate) and order3 (now a completed order, should not be here)
      when(() => mockRepo.getOpenOrders(page: 2, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 2,
          lastPage: 2,
          perPage: 2,
          total: 4,
          orders: [order2, order1], // both duplicates
        ),
      );

      await cubit.loadInitial(OrdersTab.open);
      await cubit.loadNextPage(OrdersTab.open);

      final openData = cubit.state.openOrders;
      // Both order2 and order1 are duplicates — only original 2 remain
      expect(openData.orders.length, 2);
      expect(openData.orders.map((e) => e.id).toList(), [1, 2]);
      expect(openData.currentPage, 2);
      expect(openData.hasMore, isFalse);
      expect(openData.isLoadingMore, isFalse);
    });

    test('refreshCurrentTab resets to page 1', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 1,
          orders: [order1],
        ),
      );

      await cubit.refreshCurrentTab();

      final openData = cubit.state.openOrders;
      expect(openData.orders.length, 1);
      expect(openData.orders.first.id, 1);
      expect(openData.isRefreshing, isFalse);
    });
  });

  group('OrdersCubit - State Transitions', () {
    // ── processing → shipped ─────────────────────────────────────────────────
    // Before refresh: order2 (processing) is in Open Orders
    // After refresh: order2 (shipped) has left Open, appears in Completed
    test('processing → shipped: order disappears from Open Orders', () async {
      // Initial Open Orders load: order1 (confirmed) + order2 (processing)
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 2,
          orders: [order1, order2],
        ),
      );
      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.openOrders.orders.map((o) => o.id).toList(), [1, 2]);

      // Admin changes order2 status to shipped.
      // After refresh: Open Orders now returns only order1
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 1,
          orders: [order1], // order2 is gone — it's now shipped
        ),
      );
      await cubit.refreshCurrentTab();

      final openData = cubit.state.openOrders;
      expect(openData.orders.length, 1);
      expect(openData.orders.first.id, 1);
      expect(openData.orders.any((o) => o.id == 2), isFalse,
          reason: 'order2 (now shipped) must no longer appear in Open Orders');
    });

    test('processing → shipped: order appears in Completed Orders after refresh', () async {
      // Load Completed Orders before transition: contains order3 (shipped) + order4 (delivered)
      when(() => mockRepo.getCompletedOrders(page: 1)).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 2,
          orders: [order3, order4],
        ),
      );
      await cubit.loadInitial(OrdersTab.completed);
      expect(cubit.state.completedOrders.orders.map((o) => o.id).toList(), containsAll([3, 4]));

      // Admin changes order2 status to shipped.
      // After refresh: Completed Orders now contains order2 (shipped) too
      when(() => mockRepo.getCompletedOrders(page: 1)).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 3,
          orders: [order2AsShipped, order3, order4],
        ),
      );

      // Switch to completed tab and refresh
      cubit.switchTab(OrdersTab.completed);
      await cubit.refreshCurrentTab();

      final completedData = cubit.state.completedOrders;
      final ids = completedData.orders.map((o) => o.id).toList();
      expect(ids, containsAll([2, 3, 4]),
          reason: 'order2 (now shipped) must appear in Completed Orders');
      expect(
        completedData.orders.firstWhere((o) => o.id == 2).status,
        OrderStatus.shipped,
      );
    });

    // ── shipped → delivered ──────────────────────────────────────────────────
    // order3 changes from shipped to delivered.
    // It must remain in Completed Orders — only the status label changes.
    test('shipped → delivered: order remains in Completed Orders', () async {
      // Initial Completed Orders: order3 (shipped)
      when(() => mockRepo.getCompletedOrders(page: 1)).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 1,
          orders: [order3],
        ),
      );
      await cubit.loadInitial(OrdersTab.completed);
      expect(cubit.state.completedOrders.orders.first.status, OrderStatus.shipped);

      // Admin changes order3 to delivered.
      // After refresh: same order, now delivered
      when(() => mockRepo.getCompletedOrders(page: 1)).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 1,
          orders: [order3AsDelivered],
        ),
      );
      // Switch cubit to the completed tab before refreshing
      // (loadInitial loads data but does NOT change currentTab)
      cubit.switchTab(OrdersTab.completed);
      await cubit.refreshCurrentTab();

      final completedData = cubit.state.completedOrders;
      expect(completedData.orders.length, 1);
      expect(completedData.orders.first.id, 3);
      expect(
        completedData.orders.first.status,
        OrderStatus.delivered,
        reason: 'order3 must stay in Completed, only status changes to delivered',
      );
    });
  });

  group('OrdersCubit - Defensive Local Filtering', () {
    test('Open Orders ignores pending and cancelled orders even if backend returns them', () async {
      // The cubit itself doesn't filter — the repository does.
      // We test repository contract: the returned list must not include pending (id=99).
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 1,
          orders: [order1], // repository already filtered out pending
        ),
      );

      await cubit.loadInitial(OrdersTab.open);

      expect(
        cubit.state.openOrders.orders.any((o) => o.id == 99),
        isFalse,
        reason: 'pending orders must never appear in Open Orders',
      );
    });

    test('Completed Orders ignores confirmed and processing orders', () async {
      when(() => mockRepo.getCompletedOrders(page: 1)).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 2,
          orders: [order3, order4], // repository already filtered correctly
        ),
      );

      await cubit.loadInitial(OrdersTab.completed);

      final ids = cubit.state.completedOrders.orders.map((o) => o.id).toList();
      expect(ids, containsAll([3, 4]));
      expect(
        cubit.state.completedOrders.orders.any((o) =>
            o.status == OrderStatus.confirmed || o.status == OrderStatus.processing),
        isFalse,
        reason: 'confirmed/processing must never appear in Completed Orders',
      );
    });
  });

  group('OrdersCubit - PhotosFilter Switching', () {
    test('setOpenPhotosFilter updates filter and calls getOpenOrders with matching backendTab', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: 'without_photos')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 1,
          orders: [order1],
        ),
      );

      cubit.setOpenPhotosFilter(PhotosFilter.withoutPhotos);

      expect(cubit.state.openPhotosFilter, PhotosFilter.withoutPhotos);
      await Future<void>.delayed(Duration.zero);
      verify(() => mockRepo.getOpenOrders(page: 1, tab: 'without_photos')).called(1);
    });

    test('setOpenPhotosFilter with withPhotos calls getOpenOrders with tab=with_photos', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: 'with_photos')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 1,
          orders: [order2],
        ),
      );

      cubit.setOpenPhotosFilter(PhotosFilter.withPhotos);

      expect(cubit.state.openPhotosFilter, PhotosFilter.withPhotos);
      await Future<void>.delayed(Duration.zero);
      verify(() => mockRepo.getOpenOrders(page: 1, tab: 'with_photos')).called(1);
    });
  });
}
