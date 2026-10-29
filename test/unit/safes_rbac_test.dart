import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:warehouse_store_keeper/features/auth/models/admin_user.dart';
import 'package:warehouse_store_keeper/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:warehouse_store_keeper/features/auth/presentation/cubit/auth_state.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_state.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/dashboard_view.dart';
import 'package:warehouse_store_keeper/features/safes/models/safe.dart';
import 'package:warehouse_store_keeper/features/safes/models/safe_responses.dart';
import 'package:warehouse_store_keeper/features/safes/presentation/cubits/safe_operation_cubit.dart';
import 'package:warehouse_store_keeper/features/safes/presentation/cubits/safes_list_cubit.dart';
import 'package:warehouse_store_keeper/features/safes/presentation/screens/safes_list_screen.dart';

import 'safes_cubits_test.dart';

class MockAuthCubit extends Cubit<AuthState> implements AuthCubit {
  MockAuthCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockOrdersCubit extends Cubit<OrdersState> implements OrdersCubit {
  MockOrdersCubit() : super(const OrdersState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockSafesRepository mockSafesRepo;

  setUp(() {
    mockSafesRepo = MockSafesRepository();
  });

  const superAdminUser = AdminUser(
    id: '1',
    name: 'سوبر أدمن',
    email: 'admin@omnilink.com',
    role: 'super_admin',
  );

  const storeKeeperUser = AdminUser(
    id: '2',
    name: 'أمين المستودع',
    email: 'keeper@omnilink.com',
    role: 'store_keeper',
  );

  group('Safes RBAC & Access Control Tests', () {
    test('Super Admin user role identification', () {
      expect(superAdminUser.isSuperAdmin, true);
      expect(superAdminUser.canAccessDashboard, true);

      expect(storeKeeperUser.isSuperAdmin, false);
      expect(storeKeeperUser.canAccessDashboard, false);
    });

    testWidgets('DashboardView shows Safes Management Card for Super Admin', (tester) async {
      final authCubit = MockAuthCubit(const Authenticated(superAdminUser));
      final ordersCubit = MockOrdersCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<OrdersCubit>.value(value: ordersCubit),
            ],
            child: Scaffold(
              body: DashboardView(
                onNotificationTap: () {},
                onNavigateToOrders: (_, {filterStatus}) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('إدارة الخزن المالية'), findsOneWidget);
      expect(find.text('سوبر أدمن فقط'), findsOneWidget);
    });

    testWidgets('SafesListScreen displays unauthorized warning if accessed without Super Admin role', (tester) async {
      final authCubit = MockAuthCubit(const Authenticated(storeKeeperUser));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<SafesListCubit>(
                create: (_) => SafesListCubit(safesRepository: mockSafesRepo),
              ),
              BlocProvider<SafeOperationCubit>(
                create: (_) => SafeOperationCubit(safesRepository: mockSafesRepo),
              ),
            ],
            child: const SafesListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('غير مصرح بالوصول'), findsOneWidget);
      expect(find.text('خاصية إدارة الخزن المالية متاحة فقط للمشرف العام (Super Admin).'), findsOneWidget);
    });

    testWidgets('SafesListScreen renders safes and summary when Super Admin accesses', (tester) async {
      final authCubit = MockAuthCubit(const Authenticated(superAdminUser));
      mockSafesRepo.listResponse = const SafeListResponse(
        status: true,
        message: 'OK',
        safes: [
          Safe(
            id: 1,
            name: 'خزنة كاش رئيسية',
            type: 'cash',
            balance: 25000.0,
            currency: 'EGP',
            isActive: true,
            canBeDeleted: false,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<SafesListCubit>(
                create: (_) => SafesListCubit(safesRepository: mockSafesRepo),
              ),
              BlocProvider<SafeOperationCubit>(
                create: (_) => SafeOperationCubit(safesRepository: mockSafesRepo),
              ),
            ],
            child: const SafesListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('إدارة الخزن المالية'), findsOneWidget);
      expect(find.text('خزنة كاش رئيسية'), findsOneWidget);
      expect(find.text('25,000.00'), findsWidgets);
    });
  });
}
