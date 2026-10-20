import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/core/constants/app_constants.dart';
import 'package:warehouse_store_keeper/core/error/failures.dart';
import 'package:warehouse_store_keeper/core/storage/media_hash_storage.dart';
import 'package:warehouse_store_keeper/features/orders/data/orders_remote_data_source.dart';
import 'package:warehouse_store_keeper/features/orders/data/orders_repository.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_summary.dart';
import 'package:warehouse_store_keeper/features/orders/models/paginated_orders.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_state.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/dashboard_view.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

class MockOrdersRemoteDataSource extends Mock
    implements OrdersRemoteDataSource {}

class MockMediaHashStorage extends Mock implements MediaHashStorage {}

void main() {
  group('Backend Order Statistics - Total Orders Fallback Priority', () {
    test('Priority 1 & 2: Valid meta.statistics entry with status=total takes precedence over meta.total', () {
      const state = OrdersState(
        metaTotal: 999,
        statistics: [
          OrderStatusStatistic(status: 'total', count: 143),
          OrderStatusStatistic(status: 'delivered', count: 108),
        ],
      );

      expect(
        state.totalOrdersCount,
        143,
        reason:
            'status=total in statistics must take precedence over metaTotal',
      );
    });

    test(
      'Priority 3: Missing status=total in statistics falls back to meta.total',
      () {
        const state = OrdersState(
          metaTotal: 143,
          statistics: [
            OrderStatusStatistic(status: 'delivered', count: 108),
            OrderStatusStatistic(status: 'cancelled', count: 30),
          ],
        );

        expect(
          state.totalOrdersCount,
          143,
          reason: 'When total entry is missing, must fall back to metaTotal',
        );
      },
    );

    test('Priority 3b: Invalid status=total in statistics falls back to meta.total', () {
      const state = OrdersState(
        metaTotal: 143,
        statistics: [
          OrderStatusStatistic(status: 'total', count: 0, isValidCount: false),
          OrderStatusStatistic(status: 'delivered', count: 108),
        ],
      );

      expect(
        state.totalOrdersCount,
        143,
        reason:
            'When total entry is invalid, must safely fall back to metaTotal',
      );
    });

    test('Priority 4: Fallback to loaded orders when neither statistics nor meta.total is available', () {
      const state = OrdersState(
        openOrders: TabOrdersData(
          orders: [
            OrderSummary(
              id: 1,
              orderNumber: 'ORD-1',
              status: OrderStatus.confirmed,
              rawStatus: 'confirmed',
              customerName: 'Customer',
              itemsCount: 1,
              canUploadPhotos: true,
              hasShipmentPhotos: false,
              hasWaybillPhotos: false,
              shipmentPhotosCount: 0,
              waybillPhotosCount: 0,
            ),
          ],
        ),
      );

      expect(
        state.totalOrdersCount,
        1,
        reason: 'When no metadata or statistics exist, safe fallback to loaded count',
      );
    });
  });

  group('Backend Order Statistics - Widget Display & Authoritative Counts', () {
    const List<OrderStatusStatistic> fixtureStats = [
      OrderStatusStatistic(
        status: 'delivered',
        statusText: 'تم التوصيل',
        count: 108,
      ),
      OrderStatusStatistic(status: 'cancelled', statusText: 'ألغيت', count: 30),
      OrderStatusStatistic(
        status: 'refused_delivery',
        statusText: 'رفض الاستلام',
        count: 2,
      ),
      OrderStatusStatistic(
        status: 'pending',
        statusText: 'في الانتظار',
        count: 1,
      ),
      OrderStatusStatistic(
        status: 'confirmed',
        statusText: 'تم التأكيد',
        count: 1,
      ),
      OrderStatusStatistic(
        status: 'processing',
        statusText: 'جاري المعالجة',
        count: 1,
      ),
      OrderStatusStatistic(status: 'total', statusText: 'الاجمالي', count: 143),
    ];

    testWidgets(
      'Widget displays backend counts exactly with 143 total even when only 2 orders are loaded locally',
      (tester) async {
        // Simulate only 2 orders loaded locally in the app
        const twoOrders = [
          OrderSummary(
            id: 101,
            orderNumber: 'ORD-101',
            status: OrderStatus.confirmed,
            rawStatus: 'confirmed',
            customerName: 'Customer 1',
            itemsCount: 1,
            canUploadPhotos: true,
            hasShipmentPhotos: false,
            hasWaybillPhotos: false,
            shipmentPhotosCount: 0,
            waybillPhotosCount: 0,
          ),
          OrderSummary(
            id: 102,
            orderNumber: 'ORD-102',
            status: OrderStatus.processing,
            rawStatus: 'processing',
            customerName: 'Customer 2',
            itemsCount: 2,
            canUploadPhotos: true,
            hasShipmentPhotos: false,
            hasWaybillPhotos: false,
            shipmentPhotosCount: 0,
            waybillPhotosCount: 0,
          ),
        ];

        final mockRepo = MockOrdersRepository();
        final cubit = OrdersCubit(ordersRepository: mockRepo);

        // Seed cubit with the exact fixture response state
        cubit.emit(
          const OrdersState(
            openOrders: TabOrdersData(
              orders: twoOrders,
              currentPage: 1,
              lastPage: 10,
              total: 143,
              hasMore: true,
            ),
            statistics: fixtureStats,
            metaTotal: 143,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: BlocProvider<OrdersCubit>.value(
                  value: cubit,
                  child: DashboardView(
                    onNotificationTap: () {},
                    onNavigateToOrders: (_, {filterStatus}) {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Total count is authoritative (143), NOT loaded count (2)
        expect(
          find.text('143'),
          findsWidgets,
          reason: 'Should display 143 as the total orders count',
        );
        expect(
          find.text('143 طلبًا'),
          findsOneWidget,
          reason: 'Header should show full total count',
        );

        // 2. Individual status counts match authoritative backend counts
        // Delivered: 108
        expect(
          find.text('108'),
          findsWidgets,
          reason: 'Delivered count must be 108 independently of loaded orders',
        );
        // Cancelled: 30
        // Cancelled: 30 + 2 (refused delivery) = 32
        expect(
          find.text('32'),
          findsWidgets,
          reason: 'Cancelled count must include refused delivery (30 + 2 = 32)',
        );
        // Pending: 1, Confirmed: 1, Processing: 1 (displayed as 01)
        expect(
          find.text('01'),
          findsWidgets,
          reason: 'Status counts of 1 must be displayed as 01',
        );

        // 3. Status text labels are present
        expect(find.text('تم التسليم'), findsWidgets);
        expect(find.text('إلغيت'), findsWidgets);
        expect(find.text('رفض الاستلام'), findsNothing);
        expect(find.text('مؤكد'), findsWidgets);
        expect(find.text('قيد الانتظار'), findsWidgets);
      },
    );
  });

  group('Backend Order Statistics - Pagination and Request Behavior', () {
    late MockOrdersRemoteDataSource mockRemoteDataSource;
    late OrdersRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = MockOrdersRemoteDataSource();
      repository = OrdersRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        mediaHashStorage: MockMediaHashStorage(),
      );
    });

    test('Initial request automatically uses data_type=all', () async {
      when(
        () => mockRemoteDataSource.getOrders(
          page: 1,
          tab: any(named: 'tab'),
          perPage: AppConstants.defaultPerPage,
          dataType: 'all',
        ),
      ).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 5,
          perPage: 15,
          total: 143,
          orders: [],
        ),
      );

      final result = await repository.getOpenOrders(page: 1);

      expect(result.total, 143);
      verify(
        () => mockRemoteDataSource.getOrders(
          page: 1,
          tab: 'pending',
          perPage: AppConstants.defaultPerPage,
          dataType: 'all',
        ),
      ).called(1);
    });

    test('Subsequent pagination automatically uses data_type=orders', () async {
      when(
        () => mockRemoteDataSource.getOrders(
          page: 2,
          tab: any(named: 'tab'),
          perPage: AppConstants.defaultPerPage,
          dataType: 'orders',
        ),
      ).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 2,
          lastPage: 5,
          perPage: 15,
          total: 143,
          orders: [],
        ),
      );

      final result = await repository.getOpenOrders(page: 2);

      expect(result.currentPage, 2);
      verify(
        () => mockRemoteDataSource.getOrders(
          page: 2,
          tab: 'pending',
          perPage: AppConstants.defaultPerPage,
          dataType: 'orders',
        ),
      ).called(1);
    });

    test('OrdersCubit: pagination does not overwrite or erase previously loaded statistics', () async {
      final mockRepo = MockOrdersRepository();
      final cubit = OrdersCubit(ordersRepository: mockRepo);

      const initialStats = [
        OrderStatusStatistic(status: 'total', count: 143),
        OrderStatusStatistic(status: 'delivered', count: 108),
        OrderStatusStatistic(status: 'cancelled', count: 30),
      ];

      const order1 = OrderSummary(
        id: 1,
        orderNumber: 'ORD-1',
        status: OrderStatus.confirmed,
        rawStatus: 'confirmed',
        customerName: 'Customer 1',
        itemsCount: 1,
        canUploadPhotos: true,
        hasShipmentPhotos: false,
        hasWaybillPhotos: false,
        shipmentPhotosCount: 0,
        waybillPhotosCount: 0,
      );

      const order2 = OrderSummary(
        id: 2,
        orderNumber: 'ORD-2',
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

      // Page 1 returns initial orders + statistics
      when(
        () => mockRepo.getOpenOrders(
          page: 1,
          tab: any(named: 'tab'),
          dataType: any(named: 'dataType'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 2,
          perPage: 1,
          total: 143,
          orders: [order1],
          statistics: initialStats,
        ),
      );

      // Page 2 returns next page WITHOUT statistics (null)
      when(
        () => mockRepo.getOpenOrders(
          page: 2,
          tab: any(named: 'tab'),
          dataType: any(named: 'dataType'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 2,
          lastPage: 2,
          perPage: 1,
          total: 143,
          orders: [order2],
          statistics: null,
        ),
      );

      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.openOrders.orders.length, 1);
      expect(cubit.state.statistics, initialStats);
      expect(cubit.state.totalOrdersCount, 143);

      // Load page 2
      await cubit.loadNextPage(OrdersTab.open);
      expect(cubit.state.openOrders.orders.length, 2);
      expect(cubit.state.openOrders.currentPage, 2);
      // Crucial: statistics must still be present and unchanged!
      expect(cubit.state.statistics, initialStats);
      expect(cubit.state.totalOrdersCount, 143);
      expect(cubit.state.getStatusCount('delivered'), 108);
      expect(cubit.state.getStatusCount('cancelled'), 30);
    });

    test('OrdersCubit: pagination error preserves existing orders and valid statistics', () async {
      final mockRepo = MockOrdersRepository();
      final cubit = OrdersCubit(ordersRepository: mockRepo);

      const initialStats = [
        OrderStatusStatistic(status: 'total', count: 143),
        OrderStatusStatistic(status: 'delivered', count: 108),
      ];

      const order1 = OrderSummary(
        id: 1,
        orderNumber: 'ORD-1',
        status: OrderStatus.confirmed,
        rawStatus: 'confirmed',
        customerName: 'Customer 1',
        itemsCount: 1,
        canUploadPhotos: true,
        hasShipmentPhotos: false,
        hasWaybillPhotos: false,
        shipmentPhotosCount: 0,
        waybillPhotosCount: 0,
      );

      when(
        () => mockRepo.getOpenOrders(
          page: 1,
          tab: any(named: 'tab'),
          dataType: any(named: 'dataType'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 2,
          perPage: 1,
          total: 143,
          orders: [order1],
          statistics: initialStats,
        ),
      );

      when(
        () => mockRepo.getOpenOrders(
          page: 2,
          tab: any(named: 'tab'),
          dataType: any(named: 'dataType'),
        ),
      ).thenThrow(const ServerFailure('Network error'));

      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.statistics, initialStats);

      await cubit.loadNextPage(OrdersTab.open);
      // Statistics and metadata total are preserved despite pagination failure
      expect(cubit.state.statistics, initialStats);
      expect(cubit.state.totalOrdersCount, 143);
      expect(cubit.state.openOrders.errorMessage, 'Network error');
    });

    test('OrdersCubit: pull-to-refresh updates both orders and statistics with refreshed values', () async {
      final mockRepo = MockOrdersRepository();
      final cubit = OrdersCubit(ordersRepository: mockRepo);

      const initialStats = [
        OrderStatusStatistic(status: 'total', count: 143),
        OrderStatusStatistic(status: 'delivered', count: 108),
      ];

      const refreshedStats = [
        OrderStatusStatistic(status: 'total', count: 150),
        OrderStatusStatistic(status: 'delivered', count: 114),
      ];

      when(
        () => mockRepo.getOpenOrders(
          page: 1,
          tab: any(named: 'tab'),
          dataType: any(named: 'dataType'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 143,
          orders: [],
          statistics: initialStats,
        ),
      );

      await cubit.loadInitial(OrdersTab.open);
      expect(cubit.state.totalOrdersCount, 143);

      // Now stub refreshed response
      when(
        () => mockRepo.getOpenOrders(
          page: 1,
          tab: any(named: 'tab'),
          dataType: any(named: 'dataType'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedOrders(
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 150,
          orders: [],
          statistics: refreshedStats,
        ),
      );

      await cubit.refreshCurrentTab();

      expect(cubit.state.totalOrdersCount, 150);
      expect(cubit.state.getStatusCount('delivered'), 114);
    });
  });
}
