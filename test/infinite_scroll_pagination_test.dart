import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/core/error/failures.dart';
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

  const sampleOrder1 = OrderSummary(
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

  const sampleOrder2 = OrderSummary(
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

  setUp(() {
    mockRepo = MockOrdersRepository();
  });

  Widget buildTestScreen(OrdersCubit cubit) {
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

  group('HomeOrdersScreen - Infinite Scroll & Pagination Footer Widget Tests', () {
    testWidgets('Displays compact loading indicator when isLoadingMore is true', (tester) async {
      when(() => mockRepo.getOpenOrders(page: any(named: 'page'), tab: any(named: 'tab')))
          .thenAnswer((_) async => const PaginatedOrders(
                currentPage: 1,
                lastPage: 2,
                perPage: 1,
                total: 2,
                orders: [sampleOrder1],
              ));
      when(() => mockRepo.getCompletedOrders(page: any(named: 'page')))
          .thenAnswer((_) async => const PaginatedOrders(
                currentPage: 1,
                lastPage: 1,
                perPage: 15,
                total: 0,
                orders: [],
              ));

      final cubit = OrdersCubit(ordersRepository: mockRepo);

      await tester.pumpWidget(buildTestScreen(cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Set loading more on the loaded data
      cubit.emit(cubit.state.copyWith(
        openOrders: cubit.state.openOrders.copyWith(
          isLoadingMore: true,
          hasMore: true,
        ),
      ));
      await tester.pump();

      expect(find.text(AppStrings.loadingMore), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Displays retry button when pagination fails with an error', (tester) async {
      when(() => mockRepo.getOpenOrders(page: 1, tab: any(named: 'tab')))
          .thenAnswer((_) async => const PaginatedOrders(
                currentPage: 1,
                lastPage: 2,
                perPage: 1,
                total: 2,
                orders: [sampleOrder1],
              ));
      when(() => mockRepo.getCompletedOrders(page: any(named: 'page')))
          .thenAnswer((_) async => const PaginatedOrders(
                currentPage: 1,
                lastPage: 1,
                perPage: 15,
                total: 0,
                orders: [],
              ));
      when(() => mockRepo.getOpenOrders(page: 2, tab: any(named: 'tab')))
          .thenThrow(const ServerFailure('انقطع الاتصال بالإنترنت'));

      final cubit = OrdersCubit(ordersRepository: mockRepo);

      await tester.pumpWidget(buildTestScreen(cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Order 1 is displayed
      expect(find.text('ORD-001'), findsOneWidget);

      // Trigger loadNextPage which throws ServerFailure
      await cubit.loadNextPage(OrdersTab.open);
      await tester.pump();

      // Retry button is shown with error
      expect(find.textContaining(AppStrings.retry), findsOneWidget);
      expect(find.textContaining('انقطع الاتصال بالإنترنت'), findsOneWidget);

      // Setup success for retry
      when(() => mockRepo.getOpenOrders(page: 2, tab: any(named: 'tab')))
          .thenAnswer((_) async => const PaginatedOrders(
                currentPage: 2,
                lastPage: 2,
                perPage: 1,
                total: 2,
                orders: [sampleOrder2],
              ));

      await tester.tap(find.textContaining(AppStrings.retry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // After retry succeeds, both orders exist and error is gone
      expect(find.text('ORD-001'), findsOneWidget);
      expect(find.text('ORD-002'), findsOneWidget);
      expect(find.textContaining('انقطع الاتصال بالإنترنت'), findsNothing);
    });

    testWidgets('Displays end-of-list indicator when hasMore is false and orders are loaded', (tester) async {
      when(() => mockRepo.getOpenOrders(page: any(named: 'page'), tab: any(named: 'tab')))
          .thenAnswer((_) async => const PaginatedOrders(
                currentPage: 1,
                lastPage: 1,
                perPage: 15,
                total: 1,
                orders: [sampleOrder1],
              ));
      when(() => mockRepo.getCompletedOrders(page: any(named: 'page')))
          .thenAnswer((_) async => const PaginatedOrders(
                currentPage: 1,
                lastPage: 1,
                perPage: 15,
                total: 0,
                orders: [],
              ));

      final cubit = OrdersCubit(ordersRepository: mockRepo);

      await tester.pumpWidget(buildTestScreen(cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('ORD-001'), findsOneWidget);
      expect(find.text(AppStrings.noMoreOrders), findsOneWidget);
    });
  });
}
