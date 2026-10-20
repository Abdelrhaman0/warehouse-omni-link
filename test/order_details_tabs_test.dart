import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_details.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_item.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/models/shipping_details.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/order_details_step_bar.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/picking_tab_view.dart';

void main() {
  const sampleOrder = OrderDetails(
    id: 10482,
    orderNumber: 'OL-10482',
    status: OrderStatus.confirmed,
    rawStatus: 'مؤكد',
    customerName: 'أحمد الراشد',
    phone: '+966 50 218 6042',
    address: 'حي الياسمين، شارع أنس بن مالك، الرياض',
    canUploadPhotos: true,
    hasShipmentPhotos: false,
    hasWaybillPhotos: false,
    hasExternalWarehouseInvoice: false,
    shipmentPhotos: [],
    waybillPhotos: [],
    externalWarehouseInvoices: [],
    shippingDetails: ShippingDetails(
      shippingCompany: 'سمسا',
      internalStatusText: 'خدمة قياسية',
    ),
    items: [
      OrderItem(
        id: 1,
        productId: 204,
        productName: 'قفازات عمل واقية',
        sku: 'GLV-204',
        quantity: 3,
        location: 'A-03-02',
      ),
      OrderItem(
        id: 2,
        productId: 50,
        productName: 'شريط تغليف شفاف',
        sku: 'TAP-050',
        quantity: 2,
        location: 'B-01-04',
      ),
    ],
    confirmedAt: '2026-10-12 10:02:00',
  );

  group('Order Details Tabbed Flow and Picking View Tests', () {
    testWidgets('OrderDetailsStepBar displays all 4 steps in RTL layout',
        (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: OrderDetailsStepBar(
                currentStep: selected,
                onStepSelected: (index) => selected = index,
              ),
            ),
          ),
        ),
      );

      expect(find.text('العميل'), findsOneWidget);
      expect(find.text('الشحن'), findsOneWidget);
      expect(find.text('الصور'), findsOneWidget);
      expect(find.text('الملخص'), findsOneWidget);

      await tester.tap(find.text('الشحن'));
      expect(selected, 1);
    });

    testWidgets('PickingTabView renders cards and info exactly matching image',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: PickingTabView(
                order: sampleOrder,
              ),
            ),
          ),
        ),
      );

      // Verify Order header card
      expect(find.text('OL-10482'), findsOneWidget);
      expect(find.text('مؤكد'), findsOneWidget);

      // Verify Customer & Shipping card
      expect(find.text('العميل والشحن'), findsOneWidget);
      expect(find.text('أحمد الراشد'), findsOneWidget);
      expect(find.text('+966 50 218 6042'), findsOneWidget);
      expect(find.text('حي الياسمين، شارع أنس بن مالك، الرياض'), findsOneWidget);
      expect(find.text('شركة الشحن'), findsOneWidget);
      expect(find.text('سمسا • خدمة قياسية'), findsOneWidget);

      // Verify Items & locations card
      expect(find.text('الأصناف ومواقعها'), findsOneWidget);
      expect(find.text('صنفان • 5 وحدات'), findsOneWidget);
      expect(find.text('قفازات عمل واقية'), findsOneWidget);
      expect(find.text('GLV-204'), findsOneWidget);
      expect(find.text('A-03-02'), findsOneWidget);
      expect(find.text('3 ×'), findsOneWidget);

      expect(find.text('شريط تغليف شفاف'), findsOneWidget);
      expect(find.text('TAP-050'), findsOneWidget);
      expect(find.text('B-01-04'), findsOneWidget);
      expect(find.text('2 ×'), findsOneWidget);

      // Verify Route banner
      expect(
        find.text('ابدأ من الممر A، ثم انتقل إلى الممر B. تحقّق من رمز كل صنف.'),
        findsOneWidget,
      );
    });

    testWidgets('PickingTabView renders total, remaining_amount, and remaining_type when present',
        (tester) async {
      final orderWithFinancials = OrderDetails(
        id: 10482,
        orderNumber: 'OL-10482',
        status: OrderStatus.confirmed,
        rawStatus: 'مؤكد',
        customerName: 'أحمد الراشد',
        phone: '+966 50 218 6042',
        address: 'حي الياسمين، شارع أنس بن مالك، الرياض',
        total: '350.00 ر.س',
        remainingAmount: '50.00 ر.س',
        remainingType: 'دفع عند الاستلام',
        canUploadPhotos: true,
        hasShipmentPhotos: false,
        hasWaybillPhotos: false,
        hasExternalWarehouseInvoice: false,
        shipmentPhotos: const [],
        waybillPhotos: const [],
        externalWarehouseInvoices: const [],
        items: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: PickingTabView(
                order: orderWithFinancials,
              ),
            ),
          ),
        ),
      );

      expect(find.text('إجمالي الطلب'), findsOneWidget);
      expect(find.text('350.00 ر.س'), findsOneWidget);
      expect(find.text('المبلغ المتبقي'), findsOneWidget);
      expect(find.text('50.00 ر.س'), findsOneWidget);
      expect(find.text('نوع المتبقي'), findsOneWidget);
      expect(find.text('دفع عند الاستلام'), findsOneWidget);
    });
  });
}
