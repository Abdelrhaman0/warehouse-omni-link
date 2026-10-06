import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_summary.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/order_card.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/order_status_badge.dart';

void main() {
  testWidgets('OrderCard displays order number, customer, status, and triggers callback',
      (WidgetTester tester) async {
    const order = OrderSummary(
      id: 64,
      orderNumber: 'ORD-Wuj3EMXkxE',
      status: OrderStatus.confirmed,
      rawStatus: 'confirmed',
      customerName: 'المهندس حمادة',
      itemsCount: 1,
      canUploadPhotos: true,
      hasShipmentPhotos: false,
      hasWaybillPhotos: false,
      shipmentPhotosCount: 0,
      waybillPhotosCount: 0,
      createdAt: '2026-09-06 14:59:04',
    );

    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: OrderCard(
              order: order,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    // Verify order number is displayed
    expect(find.text('ORD-Wuj3EMXkxE'), findsOneWidget);

    // Verify customer name is displayed
    expect(find.text('المهندس حمادة'), findsOneWidget);

    // Verify status badge
    expect(find.byType(OrderStatusBadge), findsOneWidget);
    expect(find.text(OrderStatus.confirmed.localizedLabel), findsOneWidget);

    // Photos count is 0, so cancel_rounded icons should be shown for shipment, waybill, and external warehouse invoice
    expect(find.byIcon(Icons.cancel_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    // Tap card
    await tester.tap(find.byType(OrderCard));
    expect(tapped, isTrue);
  });

  testWidgets('OrderCard displays check_circle icon when photos are present',
      (WidgetTester tester) async {
    const orderWithPhotos = OrderSummary(
      id: 65,
      orderNumber: 'ORD-WITH-PHOTOS',
      status: OrderStatus.processing,
      rawStatus: 'processing',
      customerName: 'أحمد علي',
      itemsCount: 3,
      canUploadPhotos: true,
      hasShipmentPhotos: true,
      hasWaybillPhotos: false,
      shipmentPhotosCount: 2,
      waybillPhotosCount: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: OrderCard(
              order: orderWithPhotos,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    // 1 checkmark for shipment photos, 2 cancels for waybill photos and external warehouse invoice
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsNWidgets(2));
  });

  testWidgets('OrderCard renders external warehouse invoice uploaded state',
      (WidgetTester tester) async {
    const orderWithInvoice = OrderSummary(
      id: 66,
      orderNumber: 'ORD-WITH-INVOICE',
      status: OrderStatus.confirmed,
      rawStatus: 'confirmed',
      customerName: 'سارة محمد',
      itemsCount: 2,
      canUploadPhotos: false,
      hasShipmentPhotos: false,
      hasWaybillPhotos: false,
      shipmentPhotosCount: 0,
      waybillPhotosCount: 0,
      hasExternalWarehouseInvoice: true,
      externalWarehouseInvoicesCount: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: OrderCard(
              order: orderWithInvoice,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    // Verify invoice label and count
    expect(find.textContaining('فاتورة المخزن'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) =>
          w is Text &&
          w.textSpan != null &&
          w.textSpan!.toPlainText().contains('فاتورة المخزن') &&
          w.textSpan!.toPlainText().contains('2')),
      findsOneWidget,
    );

    // 1 checkmark for external warehouse invoice, 2 cancels for shipment and waybill
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsNWidgets(2));
  });

  testWidgets('OrderCard renders external warehouse invoice not-uploaded state',
      (WidgetTester tester) async {
    const orderWithoutInvoice = OrderSummary(
      id: 67,
      orderNumber: 'ORD-NO-INVOICE',
      status: OrderStatus.confirmed,
      rawStatus: 'confirmed',
      customerName: 'محمود حسن',
      itemsCount: 1,
      canUploadPhotos: true,
      hasShipmentPhotos: false,
      hasWaybillPhotos: false,
      shipmentPhotosCount: 0,
      waybillPhotosCount: 0,
      hasExternalWarehouseInvoice: false,
      externalWarehouseInvoicesCount: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: OrderCard(
              order: orderWithoutInvoice,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    // Verify invoice label is shown with not-uploaded indicator
    expect(find.textContaining('فاتورة المخزن'), findsOneWidget);
    expect(find.textContaining('0'), findsWidgets); // photo indicators show 0
    expect(find.byIcon(Icons.cancel_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });
}
