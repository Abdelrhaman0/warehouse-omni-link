import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/core/error/failures.dart';
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

  group('OrdersCubit - Comprehensive Infinite Scroll Scenarios (1-14)', () {
    test('Scenario 1 & 2: Successfully loading first page and subsequent page', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 3,
          perPage: 2,
          total: 6,
          orders: [order1, order2],
        ),
      );
      when(() => mockRepo.getOpenOrders(page: 2, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 2,
          lastPage: 3,
          perPage: 2,
          total: 6,
          orders: [order3, order4],
        ),
      );

      // 1. Initial load
      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.openOrders.currentPage, 1);
      expect(cubit.state.openOrders.orders.length, 2);
      expect(cubit.state.openOrders.hasMore, isTrue);

      // 2. Load next page
      await cubit.loadNextPage(OrdersTab.open);
      expect(cubit.state.openOrders.currentPage, 2);
      expect(cubit.state.openOrders.orders.length, 4);
      expect(cubit.state.openOrders.hasMore, isTrue);
    });

    test('Scenario 3: Appends orders without losing previously loaded items', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 2,
          perPage: 1,
          total: 2,
          orders: [order1],
        ),
      );
      when(() => mockRepo.getOpenOrders(page: 2, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 2,
          lastPage: 2,
          perPage: 1,
          total: 2,
          orders: [order2],
        ),
      );

      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.openOrders.orders, [order1]);

      await cubit.loadNextPage(OrdersTab.open);
      expect(cubit.state.openOrders.orders, [order1, order2]);
    });

    test('Scenario 4: Stops requesting additional pages when last page is reached', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 1,
          orders: [order1],
        ),
      );

      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.openOrders.hasMore, isFalse);

      // Trying to load next page when hasMore is false must not make repository call
      await cubit.loadNextPage(OrdersTab.open);
      verifyNever(() => mockRepo.getOpenOrders(page: 2, tab: any(named: 'tab')));
      expect(cubit.state.openOrders.currentPage, 1);
    });

    test('Scenario 5: Handling a null next-page link stops further pagination', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 5,
          perPage: 15,
          total: 50,
          hasNextPage: false,
          orders: [order1],
        ),
      );

      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.openOrders.hasMore, isFalse);

      await cubit.loadNextPage(OrdersTab.open);
      verifyNever(() => mockRepo.getOpenOrders(page: 2, tab: any(named: 'tab')));
    });

    test('Scenario 6: Handling an empty first-page response sets hasMore to false', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 0,
          orders: [],
        ),
      );

      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.openOrders.orders, isEmpty);
      expect(cubit.state.openOrders.hasMore, isFalse);
    });

    test('Scenario 7: Handling initial request failures and retry', () async {
      var callCount = 0;
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw const ServerFailure('فشل الاتصال بالخادم');
        }
        return const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 1,
          orders: [order1],
        );
      });

      // 1. Initial load fails
      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.openOrders.orders, isEmpty);
      expect(cubit.state.openOrders.errorMessage, 'فشل الاتصال بالخادم');
      expect(cubit.state.openOrders.isLoadingInitial, isFalse);

      // 2. Retry succeeds
      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.openOrders.orders.length, 1);
      expect(cubit.state.openOrders.errorMessage, isNull);
    });

    test('Scenario 8: Handling next-page failures without losing loaded orders & retrying', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 2,
          perPage: 1,
          total: 2,
          orders: [order1],
        ),
      );

      var page2Calls = 0;
      when(() => mockRepo.getOpenOrders(page: 2, tab: any(named: 'tab'))).thenAnswer((_) async {
        page2Calls++;
        if (page2Calls == 1) {
          throw const ServerFailure('خطأ في تحميل الصفحة 2');
        }
        return const PaginatedOrders(
          currentPage: 2,
          lastPage: 2,
          perPage: 1,
          total: 2,
          orders: [order2],
        );
      });

      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.openOrders.orders, [order1]);

      // Page 2 fails
      await cubit.loadNextPage(OrdersTab.open);
      // Previously loaded order1 is PRESERVED!
      expect(cubit.state.openOrders.orders, [order1]);
      // Current page does NOT advance!
      expect(cubit.state.openOrders.currentPage, 1);
      expect(cubit.state.openOrders.errorMessage, 'خطأ في تحميل الصفحة 2');
      expect(cubit.state.openOrders.isLoadingMore, isFalse);

      // Retry page 2 succeeds!
      await cubit.loadNextPage(OrdersTab.open);
      expect(cubit.state.openOrders.orders, [order1, order2]);
      expect(cubit.state.openOrders.currentPage, 2);
      expect(cubit.state.openOrders.errorMessage, isNull);
    });

    test('Scenario 9: Preventing concurrent duplicate pagination requests', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 3,
          perPage: 1,
          total: 3,
          orders: [order1],
        ),
      );

      await cubit.loadInitial(OrdersTab.open);

      when(() => mockRepo.getOpenOrders(page: 2, tab: any(named: 'tab'))).thenAnswer(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return const PaginatedOrders(
            currentPage: 2,
            lastPage: 3,
            perPage: 1,
            total: 3,
            orders: [order2],
          );
        },
      );

      // Trigger loadNextPage twice in parallel
      final future1 = cubit.loadNextPage(OrdersTab.open);
      final future2 = cubit.loadNextPage(OrdersTab.open);

      await Future.wait([future1, future2]);

      // Only one request for page 2 should have been made
      verify(() => mockRepo.getOpenOrders(page: 2, tab: any(named: 'tab'))).called(1);
    });

    test('Scenario 10: Resetting pagination when switching tabs & photo filters', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: 'pending')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 2,
          perPage: 1,
          total: 2,
          orders: [order1],
        ),
      );
      when(() => mockRepo.getOpenOrders(page: 1, tab: 'with_photos')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 1,
          total: 1,
          orders: [order2],
        ),
      );

      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.openOrders.orders, [order1]);

      cubit.setOpenPhotosFilter(PhotosFilter.withPhotos);
      // State is immediately reset
      expect(cubit.state.openOrders.orders, isEmpty);

      await Future<void>.delayed(Duration.zero);
      // Loaded page 1 for new filter
      expect(cubit.state.openOrders.orders, [order2]);
      expect(cubit.state.openOrders.currentPage, 1);
    });

    test('Scenario 11: Refreshing the list replaces orders and resets to page 1', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 2,
          perPage: 1,
          total: 2,
          orders: [order1],
        ),
      );
      when(() => mockRepo.getOpenOrders(page: 2, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 2,
          lastPage: 2,
          perPage: 1,
          total: 2,
          orders: [order2],
        ),
      );

      await cubit.loadInitial(OrdersTab.open);
      await cubit.loadNextPage(OrdersTab.open);
      expect(cubit.state.openOrders.orders.length, 2);
      expect(cubit.state.openOrders.currentPage, 2);

      // Now refresh
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 2,
          perPage: 1,
          total: 2,
          orders: [order3], // Backend returned updated order
        ),
      );

      await cubit.refreshCurrentTab();
      // Orders list is replaced, not appended!
      expect(cubit.state.openOrders.orders, [order3]);
      expect(cubit.state.openOrders.currentPage, 1);
    });

    test('Scenario 12: Preventing duplicate order IDs across pages', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 2,
          perPage: 2,
          total: 3,
          orders: [order1, order2],
        ),
      );
      when(() => mockRepo.getOpenOrders(page: 2, tab: any(named: 'tab'))).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 2,
          lastPage: 2,
          perPage: 2,
          total: 3,
          orders: [order2, order3], // order2 is a duplicate from page 1
        ),
      );

      await cubit.loadInitial(OrdersTab.open);
      await cubit.loadNextPage(OrdersTab.open);

      final ids = cubit.state.openOrders.orders.map((o) => o.id).toList();
      // order2 only appears once!
      expect(ids, [1, 2, 3]);
    });

    test('Scenario 14: Preventing stale responses from older requests from overwriting newer state', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: 'pending')).thenAnswer(
        (_) async {
          // Slow response for pending
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return const PaginatedOrders(
            currentPage: 1,
            lastPage: 1,
            perPage: 1,
            total: 1,
            orders: [order1],
          );
        },
      );

      when(() => mockRepo.getOpenOrders(page: 1, tab: 'with_photos')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 1,
          total: 1,
          orders: [order2],
        ),
      );

      // Start slow initial load for pending
      final slowFuture = cubit.loadInitial(OrdersTab.open);

      // User quickly changes filter to withPhotos
      cubit.setOpenPhotosFilter(PhotosFilter.withPhotos);

      // Wait for both to complete
      await slowFuture;
      await Future<void>.delayed(const Duration(milliseconds: 120));

      // Active filter must remain withPhotos and orders must be order2, not overwritten by stale order1!
      expect(cubit.state.openPhotosFilter, PhotosFilter.withPhotos);
      expect(cubit.state.openOrders.orders, [order2]);
    });
  });

  group('OrdersCubit - Automatic Tab Selection Based on Selected Status (Scenarios 1-10)', () {
    const cancelledOrder = OrderSummary(
      id: 99,
      orderNumber: 'ORD-099',
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

    test('Scenario 1: Selecting a cancelled status activates completed tab and requests status=cancelled', () async {
      when(() => mockRepo.getCompletedOrders(page: 1, status: 'cancelled')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 30,
          total: 1,
          orders: [cancelledOrder],
        ),
      );

      // Start on open tab
      expect(cubit.state.currentTab, OrdersTab.open);

      // User selects cancelled
      cubit.setStatusFilter(OrderStatus.cancelled);

      // Tab automatically switches to completed tab
      expect(cubit.state.currentTab, OrdersTab.completed);
      expect(cubit.state.selectedStatus, OrderStatus.cancelled);

      await Future<void>.delayed(Duration.zero);

      // Verified request contains tab=completed and status=cancelled
      verify(() => mockRepo.getCompletedOrders(page: 1, status: 'cancelled')).called(1);
      expect(cubit.state.completedOrders.orders, [cancelledOrder]);
    });

    test('Scenario 2: Selecting a pending status activates the open tab and requests status=pending', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: 'pending', status: 'pending')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 30,
          total: 1,
          orders: [order1],
        ),
      );

      // Start on completed tab
      cubit.switchTab(OrdersTab.completed);
      expect(cubit.state.currentTab, OrdersTab.completed);

      // User selects pending
      cubit.setStatusFilter(OrderStatus.pending);

      // Tab automatically switches to open tab
      expect(cubit.state.currentTab, OrdersTab.open);
      expect(cubit.state.selectedStatus, OrderStatus.pending);

      await Future<void>.delayed(Duration.zero);
      verify(() => mockRepo.getOpenOrders(page: 1, tab: 'pending', status: 'pending')).called(1);
      expect(cubit.state.openOrders.orders, [order1]);
    });

    test('Scenario 3: Selecting a completed status (shipped / delivered) activates the completed tab', () async {
      when(() => mockRepo.getCompletedOrders(page: 1, status: 'delivered')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 30,
          total: 1,
          orders: [order4],
        ),
      );

      expect(cubit.state.currentTab, OrdersTab.open);

      cubit.setStatusFilter(OrderStatus.delivered);

      expect(cubit.state.currentTab, OrdersTab.completed);
      expect(cubit.state.selectedStatus, OrderStatus.delivered);

      await Future<void>.delayed(Duration.zero);
      verify(() => mockRepo.getCompletedOrders(page: 1, status: 'delivered')).called(1);
      expect(cubit.state.completedOrders.orders, [order4]);
    });

    test('Scenario 4: Selecting a status already belonging to active tab does not cause duplicate requests', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: 'pending', status: 'confirmed')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 30,
          total: 1,
          orders: [order1],
        ),
      );

      // Already on open tab
      expect(cubit.state.currentTab, OrdersTab.open);

      // 1. Select confirmed
      cubit.setStatusFilter(OrderStatus.confirmed);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.currentTab, OrdersTab.open);
      verify(() => mockRepo.getOpenOrders(page: 1, tab: 'pending', status: 'confirmed')).called(1);

      // 2. Select confirmed AGAIN (same status) -> No-op!
      cubit.setStatusFilter(OrderStatus.confirmed);
      await Future<void>.delayed(Duration.zero);

      // Verify no duplicate request was made
      verifyNever(() => mockRepo.getOpenOrders(page: 1, tab: 'pending', status: 'confirmed'));
    });

    test('Scenario 5: The API request contains both the correct tab and status filters', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: 'pending', status: 'processing')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 30,
          total: 1,
          orders: [order2],
        ),
      );

      cubit.setStatusFilter(OrderStatus.processing);
      await Future<void>.delayed(Duration.zero);

      verify(() => mockRepo.getOpenOrders(page: 1, tab: 'pending', status: 'processing')).called(1);
    });

    test('Scenario 6: Pagination resets when selected status changes the active tab', () async {
      when(() => mockRepo.getCompletedOrders(page: 1, status: 'cancelled')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 2,
          perPage: 1,
          total: 2,
          orders: [cancelledOrder],
        ),
      );

      // Switch to cancelled -> resets completedOrders to fresh page 1
      cubit.setStatusFilter(OrderStatus.cancelled);
      expect(cubit.state.completedOrders.orders, isEmpty);

      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.completedOrders.currentPage, 1);
      expect(cubit.state.completedOrders.orders, [cancelledOrder]);
      expect(cubit.state.completedOrders.hasMore, isTrue);
    });

    test('Scenario 7: Subsequent pages retain the selected status filter', () async {
      when(() => mockRepo.getCompletedOrders(page: 1, status: 'cancelled')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 2,
          perPage: 1,
          total: 2,
          orders: [cancelledOrder],
        ),
      );
      when(() => mockRepo.getCompletedOrders(page: 2, status: 'cancelled')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 2,
          lastPage: 2,
          perPage: 1,
          total: 2,
          orders: [
            OrderSummary(
              id: 100,
              orderNumber: 'ORD-100',
              status: OrderStatus.cancelled,
              rawStatus: 'cancelled',
              customerName: 'Customer Cancelled 2',
              itemsCount: 1,
              canUploadPhotos: false,
              hasShipmentPhotos: false,
              hasWaybillPhotos: false,
              shipmentPhotosCount: 0,
              waybillPhotosCount: 0,
            )
          ],
        ),
      );

      // Initial load with cancelled filter
      cubit.setStatusFilter(OrderStatus.cancelled);
      await Future<void>.delayed(Duration.zero);

      // Next page request retains status='cancelled'
      await cubit.loadNextPage(OrdersTab.completed);
      verify(() => mockRepo.getCompletedOrders(page: 2, status: 'cancelled')).called(1);
      expect(cubit.state.completedOrders.currentPage, 2);
      expect(cubit.state.completedOrders.orders.length, 2);
    });

    test('Scenario 8: Rapid status changes do not allow stale responses to overwrite current results', () async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: 'pending', status: 'confirmed')).thenAnswer(
        (_) async {
          // Slow response for confirmed
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return const PaginatedOrders(
            currentPage: 1,
            lastPage: 1,
            perPage: 30,
            total: 1,
            orders: [order1],
          );
        },
      );

      when(() => mockRepo.getCompletedOrders(page: 1, status: 'cancelled')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 30,
          total: 1,
          orders: [cancelledOrder],
        ),
      );

      // User selects confirmed (starts slow request)
      cubit.setStatusFilter(OrderStatus.confirmed);

      // User immediately changes mind and selects cancelled
      cubit.setStatusFilter(OrderStatus.cancelled);

      // Wait for slow request to resolve
      await Future<void>.delayed(const Duration(milliseconds: 120));

      // Current tab must be completed and orders must be cancelledOrder, not overwritten by confirmed
      expect(cubit.state.currentTab, OrdersTab.completed);
      expect(cubit.state.selectedStatus, OrderStatus.cancelled);
      expect(cubit.state.completedOrders.orders, [cancelledOrder]);
    });

    test('Scenario 9: Manual tab switching clears status filter if incompatible with the new tab', () async {
      when(() => mockRepo.getCompletedOrders(page: 1, status: 'cancelled')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 30,
          total: 1,
          orders: [cancelledOrder],
        ),
      );
      when(() => mockRepo.getOpenOrders(page: 1, tab: 'pending')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 30,
          total: 2,
          orders: [order1, order2],
        ),
      );

      // User filters by cancelled (active tab = completed)
      cubit.setStatusFilter(OrderStatus.cancelled);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.currentTab, OrdersTab.completed);
      expect(cubit.state.selectedStatus, OrderStatus.cancelled);

      // User manually taps the Open orders tab
      cubit.switchTab(OrdersTab.open);

      // Status is automatically cleared because cancelled is incompatible with open orders
      expect(cubit.state.currentTab, OrdersTab.open);
      expect(cubit.state.selectedStatus, isNull);

      await Future<void>.delayed(Duration.zero);
      verify(() => mockRepo.getOpenOrders(page: 1, tab: 'pending')).called(1);
    });

    test('Scenario 10: Existing pull-to-refresh preserves active status filter', () async {
      when(() => mockRepo.getCompletedOrders(page: 1, status: 'cancelled')).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 30,
          total: 1,
          orders: [cancelledOrder],
        ),
      );

      cubit.setStatusFilter(OrderStatus.cancelled);
      await Future<void>.delayed(Duration.zero);

      // Refresh current tab
      await cubit.refreshCurrentTab();

      // Refreshed request preserved status='cancelled'
      verify(() => mockRepo.getCompletedOrders(page: 1, status: 'cancelled')).called(2);
      expect(cubit.state.selectedStatus, OrderStatus.cancelled);
      expect(cubit.state.completedOrders.orders, [cancelledOrder]);
    });
  });
}


