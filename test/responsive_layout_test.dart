import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/core/localization/app_strings.dart';
import 'package:warehouse_store_keeper/features/orders/data/orders_repository.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_details.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_item.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_summary.dart';
import 'package:warehouse_store_keeper/features/orders/models/paginated_orders.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/orders_state.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/shipment_photos_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/screens/home_orders_screen.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/order_card.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/order_status_badge.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/product_item_card.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/shipment_photos_section.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  const widths = [320.0, 360.0, 375.0, 390.0, 412.0];

  group('Responsive OrderCard across multiple device widths in RTL', () {
    const sampleOrder = OrderSummary(
      id: 99,
      orderNumber: 'ORD-ougI7bRa43',
      status: OrderStatus.confirmed,
      rawStatus: 'confirmed',
      customerName: 'المهندس حمادة عبد الرحمن الشريف',
      itemsCount: 4,
      canUploadPhotos: true,
      hasShipmentPhotos: true,
      hasWaybillPhotos: false,
      shipmentPhotosCount: 5,
      waybillPhotosCount: 0,
      createdAt: '2026-09-17 14:03:00',
    );

    for (final width in widths) {
      testWidgets('OrderCard renders without overflow at width ${width}px (RTL)',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    OrderCard(
                      order: sampleOrder,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Verify no RenderFlex or layout exceptions occurred
        expect(tester.takeException(), isNull);

        // Verify order number is present and visible
        expect(find.text('ORD-ougI7bRa43'), findsOneWidget);

        // Verify customer name is present and visible
        expect(find.text('المهندس حمادة عبد الرحمن الشريف'), findsOneWidget);

        // Verify status badge
        expect(find.byType(OrderStatusBadge), findsOneWidget);

        // Verify date is present and not chopped off
        expect(find.textContaining('2026-09-17'), findsOneWidget);
        expect(find.textContaining('التاريخ'), findsOneWidget);

        // Verify items count
        expect(find.textContaining('عدد المنتجات: 4'), findsOneWidget);

        // Verify photo status items
        expect(find.textContaining('صور الشحنة'), findsOneWidget);
        expect(find.textContaining('صور البوليصة'), findsOneWidget);
        expect(find.textContaining('فاتورة المخزن'), findsOneWidget);
      });
    }
  });

  group('Responsive Main Tabs and Filter Chips on HomeOrdersScreen in RTL', () {
    for (final width in widths) {
      testWidgets('HomeOrdersScreen tabs & filter chips render cleanly at ${width}px (RTL)',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockOrdersRepository();
        when(() => mockRepo.getOpenOrders(
              page: any(named: 'page'),
              tab: any(named: 'tab'),
            )).thenAnswer(
          (_) async => const PaginatedOrders(
            currentPage: 1,
            lastPage: 1,
            perPage: 10,
            total: 0,
            orders: [],
          ),
        );

        final cubit = OrdersCubit(ordersRepository: mockRepo);

        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: BlocProvider<OrdersCubit>.value(
                value: cubit,
                child: const HomeOrdersScreen(),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.openOrders), findsOneWidget);
        expect(find.text(AppStrings.completedOrders), findsOneWidget);

        expect(find.text(PhotosFilter.all.label), findsOneWidget);
        expect(find.text(PhotosFilter.withoutPhotos.label), findsOneWidget);
        expect(find.text(PhotosFilter.withPhotos.label), findsOneWidget);

        cubit.close();
      });
    }
  });

  group('Responsive ProductItemCard across multiple widths in RTL', () {
    const item = OrderItem(
      id: 1,
      productId: 10,
      productName: 'كرسي مكتبي دوار مريح شبكي أسود عالي الجودة',
      sku: 'SKU-EXTRA-LONG-CODE-998877665544',
      quantity: 12,
    );

    for (final width in widths) {
      testWidgets('ProductItemCard adapts at width ${width}px (RTL)',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: const ProductItemCard(item: item),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text(item.productName), findsOneWidget);
        expect(find.text('12'), findsOneWidget);
      });
    }
  });

  group('Responsive ShipmentPhotosSection action buttons in RTL', () {
    const orderDetails = OrderDetails(
      id: 10,
      orderNumber: 'ORD-12345',
      status: OrderStatus.processing,
      rawStatus: 'processing',
      customerName: 'عميل تجريبي',
      canUploadPhotos: true,
      hasShipmentPhotos: false,
      hasWaybillPhotos: false,
      items: [],
      shipmentPhotos: [],
      waybillPhotos: [],
      hasExternalWarehouseInvoice: false,
      externalWarehouseInvoices: [],
    );

    for (final width in widths) {
      testWidgets('ShipmentPhotosSection adapts buttons at width ${width}px (RTL)',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockOrdersRepository();
        final cubit = ShipmentPhotosCubit(
          ordersRepository: mockRepo,
          orderId: orderDetails.id,
          existingPhotosCount: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: BlocProvider<ShipmentPhotosCubit>.value(
                  value: cubit,
                  child: const ShipmentPhotosSection(order: orderDetails),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.takePhoto), findsOneWidget);
        expect(find.text(AppStrings.chooseFromGallery), findsOneWidget);

        cubit.close();
      });
    }
  });
}
