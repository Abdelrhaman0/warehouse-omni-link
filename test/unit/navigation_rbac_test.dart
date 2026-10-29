import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/app/router/app_router.dart';
import 'package:warehouse_store_keeper/core/localization/app_strings.dart';
import 'package:warehouse_store_keeper/features/auth/data/auth_repository.dart';
import 'package:warehouse_store_keeper/features/auth/models/admin_user.dart';
import 'package:warehouse_store_keeper/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:warehouse_store_keeper/features/auth/presentation/cubit/auth_state.dart';
import 'package:warehouse_store_keeper/features/orders/data/orders_repository.dart';
import 'package:warehouse_store_keeper/features/orders/models/paginated_orders.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/screens/home_orders_screen.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/dashboard_view.dart';

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
    permissions: ['dashboard.view', 'orders.read'],
  );

  const superAdmin = AdminUser(
    id: '1',
    name: 'Super Admin User',
    email: 'super@omni-link.net',
    role: 'super_admin',
    permissions: ['dashboard.view'],
  );

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockOrdersRepo = MockOrdersRepository();

    when(() => mockAuthRepo.sessionExpiredStream)
        .thenAnswer((_) => const Stream.empty());

    const emptyPaginated = PaginatedOrders(
      currentPage: 1,
      lastPage: 1,
      perPage: 15,
      total: 0,
      orders: [],
    );

    when(
      () => mockOrdersRepo.getOpenOrders(
        page: any(named: 'page'),
        tab: any(named: 'tab'),
        status: any(named: 'status'),
        dataType: any(named: 'dataType'),
      ),
    ).thenAnswer((_) async => emptyPaginated);

    when(
      () => mockOrdersRepo.getCompletedOrders(
        page: any(named: 'page'),
        status: any(named: 'status'),
        dataType: any(named: 'dataType'),
      ),
    ).thenAnswer((_) async => emptyPaginated);

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
        child: MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: child,
        ),
      ),
    );
  }

  group('Navigation and Dashboard Protection Tests (Section 8 & 13)', () {
    testWidgets(
      'Store keeper: Dashboard tab is HIDDEN and only 2 tabs exist (Orders, Profile)',
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

        // Dashboard tab ('الرئيسية') should NOT be present in bottom navigation
        expect(find.text('الرئيسية'), findsNothing);
        expect(find.byIcon(Icons.grid_view_outlined), findsNothing);

        // Operational tabs MUST be present
        expect(find.text('الطلبات'), findsWidgets);
        expect(find.text('حسابي'), findsOneWidget);

        // BottomNavigationBar must have exactly 2 items
        final bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNav.items.length, 2);
        expect(bottomNav.items[0].label, 'الطلبات');
        expect(bottomNav.items[1].label, 'حسابي');

        // DashboardView must NOT exist in the widget tree for store keepers
        expect(find.byType(DashboardView), findsNothing);
      },
    );

    testWidgets(
      'Store keeper: Direct initialNavIndex: 0 request is DENIED and safely defaults to Orders',
      (tester) async {
        authCubit.emit(const Authenticated(storeKeeper));

        // Attempting to bypass navigation by passing initialNavIndex: 0 (Dashboard index)
        await tester.pumpWidget(
          buildTestApp(
            child: const HomeOrdersScreen(initialNavIndex: 0),
            authCubit: authCubit,
            ordersCubit: ordersCubit,
          ),
        );
        await tester.pumpAndSettle();

        // DashboardView must still NOT be present
        expect(find.byType(DashboardView), findsNothing);
        expect(find.text('الرئيسية'), findsNothing);

        // Screen must safely show orders tab
        expect(find.text('الطلبات'), findsWidgets);
      },
    );

    testWidgets(
      'Super admin: Dashboard tab is VISIBLE and all 3 tabs are accessible',
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

        // Dashboard tab ('الرئيسية') MUST be visible
        expect(find.text('الرئيسية'), findsOneWidget);
        expect(
          find.byIcon(Icons.grid_view_outlined),
          findsNothing,
        ); // Active icon is displayed when selected
        expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

        // BottomNavigationBar must have 3 items
        final bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNav.items.length, 3);
        expect(bottomNav.items[0].label, 'الرئيسية');
        expect(bottomNav.items[1].label, 'الطلبات');
        expect(bottomNav.items[2].label, 'حسابي');

        // DashboardView MUST be present for super admin
        expect(find.byType(DashboardView), findsOneWidget);
      },
    );

    testWidgets(
      'AppRouter /dashboard route guard redirects store keeper to /home without loop',
      (tester) async {
        authCubit.emit(const Authenticated(storeKeeper));

        late BuildContext testContext;
        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (ctx) {
                testContext = ctx;
                return const Scaffold(body: Text('Root'));
              },
            ),
            authCubit: authCubit,
            ordersCubit: ordersCubit,
          ),
        );
        await tester.pumpAndSettle();

        // Attempt direct navigation to /dashboard as store_keeper
        Navigator.of(testContext).pushNamed(AppRouter.dashboard);
        await tester.pumpAndSettle();

        // Store keeper must be redirected to orders (no infinite loop)
        expect(find.byType(HomeOrdersScreen), findsOneWidget);
        expect(find.byType(DashboardView), findsNothing);
        expect(find.text('الرئيسية'), findsNothing);
      },
    );

    testWidgets(
      'AppRouter /dashboard route guard allows super admin to view dashboard',
      (tester) async {
        authCubit.emit(const Authenticated(superAdmin));

        late BuildContext testContext;
        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (ctx) {
                testContext = ctx;
                return const Scaffold(body: Text('Root'));
              },
            ),
            authCubit: authCubit,
            ordersCubit: ordersCubit,
          ),
        );
        await tester.pumpAndSettle();

        Navigator.of(testContext).pushNamed(AppRouter.dashboard);
        await tester.pumpAndSettle();

        // Super admin lands on DashboardView
        expect(find.byType(DashboardView), findsOneWidget);
      },
    );

    testWidgets(
      'AppRouter /dashboard route guard redirects unauthenticated user to /login',
      (tester) async {
        authCubit.emit(const Unauthenticated());

        late BuildContext testContext;
        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (ctx) {
                testContext = ctx;
                return const Scaffold(body: Text('Root'));
              },
            ),
            authCubit: authCubit,
            ordersCubit: ordersCubit,
          ),
        );
        await tester.pumpAndSettle();

        Navigator.of(testContext).pushNamed(AppRouter.dashboard);
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.loginTitle), findsOneWidget);
        expect(find.byType(DashboardView), findsNothing);
      },
    );

    testWidgets(
      'DashboardView direct boundary defense: displays unauthorized text for store keeper',
      (tester) async {
        authCubit.emit(const Authenticated(storeKeeper));

        await tester.pumpWidget(
          buildTestApp(
            child: Scaffold(
              body: DashboardView(
                onNotificationTap: () {},
                onNavigateToOrders: (_, {filterStatus}) {},
              ),
            ),
            authCubit: authCubit,
            ordersCubit: ordersCubit,
          ),
        );
        await tester.pumpAndSettle();

        // Boundary defense triggers
        expect(
          find.text(AppStrings.unauthorizedDashboardAccess),
          findsOneWidget,
        );
      },
    );
  });
}
