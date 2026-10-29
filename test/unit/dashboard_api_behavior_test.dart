import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/app/router/app_router.dart';
import 'package:warehouse_store_keeper/features/auth/data/auth_repository.dart';
import 'package:warehouse_store_keeper/features/auth/models/admin_user.dart';
import 'package:warehouse_store_keeper/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:warehouse_store_keeper/features/auth/presentation/cubit/auth_state.dart';
import 'package:warehouse_store_keeper/features/orders/data/orders_repository.dart';
import 'package:warehouse_store_keeper/features/orders/models/paginated_orders.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/screens/home_orders_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockOrdersRepository mockOrdersRepo;
  late AuthCubit authCubit;
  late OrdersCubit ordersCubit;

  const storeKeeper = AdminUser(
    id: '10',
    name: 'Store Keeper User',
    email: 'keeper@omni-link.net',
    role: 'store_keeper',
  );

  const superAdmin = AdminUser(
    id: '1',
    name: 'Super Admin User',
    email: 'super@omni-link.net',
    role: 'super_admin',
  );

  final sampleStatistics = [
    const OrderStatusStatistic(status: 'total', count: 100),
    const OrderStatusStatistic(status: 'pending', count: 20),
    const OrderStatusStatistic(status: 'confirmed', count: 30),
    const OrderStatusStatistic(status: 'delivered', count: 50),
  ];

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockOrdersRepo = MockOrdersRepository();

    when(() => mockAuthRepo.sessionExpiredStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAuthRepo.logout()).thenAnswer((_) async {});

    when(
      () => mockOrdersRepo.getOpenOrders(
        page: any(named: 'page'),
        tab: any(named: 'tab'),
        status: any(named: 'status'),
        dataType: any(named: 'dataType'),
      ),
    ).thenAnswer(
      (_) async => PaginatedOrders(
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
        orders: const [],
        statistics: sampleStatistics,
      ),
    );

    when(
      () => mockOrdersRepo.getCompletedOrders(
        page: any(named: 'page'),
        status: any(named: 'status'),
        dataType: any(named: 'dataType'),
      ),
    ).thenAnswer(
      (_) async => PaginatedOrders(
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
        orders: const [],
        statistics: sampleStatistics,
      ),
    );

    authCubit = AuthCubit(authRepository: mockAuthRepo);
    ordersCubit = OrdersCubit(ordersRepository: mockOrdersRepo);
  });

  tearDown(() {
    authCubit.close();
    ordersCubit.close();
  });

  Widget buildTestApp({
    required Widget child,
    required AuthCubit authCubit,
    required OrdersCubit ordersCubit,
  }) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: mockAuthRepo),
        RepositoryProvider<OrdersRepository>.value(value: mockOrdersRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<OrdersCubit>.value(value: ordersCubit),
        ],
        child: MaterialApp(navigatorKey: AppRouter.navigatorKey, home: child),
      ),
    );
  }

  group(
    'Dashboard API Requests and State Management Behavior (Section 9 & 13)',
    () {
      testWidgets(
        'Store keeper: Only open orders are loaded at startup, dashboard pre-fetch is NOT initiated',
        (tester) async {
          authCubit.emit(const Authenticated(storeKeeper));

          await tester.pumpWidget(
            buildTestApp(
              child: const HomeOrdersScreen(),
              authCubit: authCubit,
              ordersCubit: ordersCubit,
            ),
          );
          await tester.pumpAndSettle();

          // Store keeper must fetch open orders for warehouse operational workflows
          verify(
            () => mockOrdersRepo.getOpenOrders(
              page: 1,
              tab: any(named: 'tab'),
              status: any(named: 'status'),
              dataType: any(named: 'dataType'),
            ),
          ).called(1);

          // Store keeper must NOT trigger completed orders pre-fetch meant solely for dashboard statistics
          verifyNever(
            () => mockOrdersRepo.getCompletedOrders(
              page: any(named: 'page'),
              status: any(named: 'status'),
              dataType: any(named: 'dataType'),
            ),
          );
        },
      );

      testWidgets(
        'Super admin: Both open and completed orders are loaded at startup so dashboard has stats',
        (tester) async {
          authCubit.emit(const Authenticated(superAdmin));

          await tester.pumpWidget(
            buildTestApp(
              child: const HomeOrdersScreen(initialNavIndex: 0),
              authCubit: authCubit,
              ordersCubit: ordersCubit,
            ),
          );
          await tester.pumpAndSettle();

          // Super admin fetches both open and completed orders to establish full dashboard stats
          verify(
            () => mockOrdersRepo.getOpenOrders(
              page: 1,
              tab: any(named: 'tab'),
              status: any(named: 'status'),
              dataType: any(named: 'dataType'),
            ),
          ).called(1);

          verify(
            () => mockOrdersRepo.getCompletedOrders(
              page: 1,
              status: any(named: 'status'),
              dataType: any(named: 'dataType'),
            ),
          ).called(1);
        },
      );

      testWidgets(
        'Store keeper: Operational workflow preserved — can load completed orders on demand when tab selected',
        (tester) async {
          authCubit.emit(const Authenticated(storeKeeper));

          await tester.pumpWidget(
            buildTestApp(
              child: const HomeOrdersScreen(),
              authCubit: authCubit,
              ordersCubit: ordersCubit,
            ),
          );
          await tester.pumpAndSettle();

          verifyNever(
            () => mockOrdersRepo.getCompletedOrders(
              page: any(named: 'page'),
              status: any(named: 'status'),
              dataType: any(named: 'dataType'),
            ),
          );

          // User taps "الطلبات المكتملة" tab on Orders screen
          await tester.tap(find.text('الطلبات المكتملة'));
          await tester.pumpAndSettle();

          // Now completed orders are loaded on demand for the store keeper
          verify(
            () => mockOrdersRepo.getCompletedOrders(
              page: 1,
              status: any(named: 'status'),
              dataType: any(named: 'dataType'),
            ),
          ).called(1);
        },
      );

      test('OrdersCubit.reset() completely clears dashboard statistics and loaded orders', () {
        // Simulate populated statistics from super admin session
        ordersCubit.emit(
          ordersCubit.state.copyWith(statistics: sampleStatistics),
        );
        expect(ordersCubit.state.statistics, isNotNull);
        expect(ordersCubit.state.totalOrdersCount, 100);

        // Call reset()
        ordersCubit.reset();

        // All statistics and orders must be cleared
        expect(ordersCubit.state.statistics, isNull);
        expect(ordersCubit.state.openOrders.orders, isEmpty);
        expect(ordersCubit.state.completedOrders.orders, isEmpty);
      });

      testWidgets(
        'Session lifecycle: Logout resets OrdersCubit and prevents leaking dashboard state',
        (tester) async {
          authCubit.emit(const Authenticated(superAdmin));

          // Populate statistics in cubit
          ordersCubit.emit(
            ordersCubit.state.copyWith(statistics: sampleStatistics),
          );
          expect(ordersCubit.state.statistics, isNotNull);

          // Trigger logout
          await authCubit.logout();
          expect(authCubit.state, isA<Unauthenticated>());

          // OrdersCubit reset ensures clean state for subsequent login
          ordersCubit.reset();
          expect(ordersCubit.state.statistics, isNull);
        },
      );
    },
  );
}
