// test/unit/cancellation_reason_test.dart
//
// Tests the cancellation reason feature end-to-end:
//   1. ShippingDetails JSON parsing for cancelled_reason
//   2. CancellationReasonBanner widget visibility rules
//   3. OrderDetailsHeader integration
//   4. HandoverTabView integration (after timeline card)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/core/localization/app_strings.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_details.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/models/shipping_details.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/cancellation_reason_banner.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/handover_tab_view.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/order_details_header.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Wraps a widget in the minimal scaffold required for widget tests.
Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      ),
    );

/// Creates a cancelled [OrderDetails] with the given [cancelledReason] on
/// [ShippingDetails] and wraps it in an RTL scaffold.
OrderDetails _cancelledOrder({String? cancelledReason}) => OrderDetails(
      id: 99,
      orderNumber: 'OL-99',
      status: OrderStatus.cancelled,
      rawStatus: 'إلغيت',
      customerName: 'محمد العمري',
      canUploadPhotos: false,
      hasShipmentPhotos: false,
      hasWaybillPhotos: false,
      hasExternalWarehouseInvoice: false,
      shipmentPhotos: const [],
      waybillPhotos: const [],
      externalWarehouseInvoices: const [],
      items: const [],
      shippingDetails: ShippingDetails(cancelledReason: cancelledReason),
    );

/// Creates a non-cancelled [OrderDetails] (confirmed status).
OrderDetails _confirmedOrder() => const OrderDetails(
      id: 42,
      orderNumber: 'OL-42',
      status: OrderStatus.confirmed,
      rawStatus: 'مؤكد',
      customerName: 'سارة الزهراني',
      canUploadPhotos: true,
      hasShipmentPhotos: false,
      hasWaybillPhotos: false,
      hasExternalWarehouseInvoice: false,
      shipmentPhotos: [],
      waybillPhotos: [],
      externalWarehouseInvoices: [],
      items: [],
    );

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // 1. ShippingDetails JSON parsing
  // ══════════════════════════════════════════════════════════════════════════

  group('ShippingDetails JSON parsing — cancelled_reason', () {
    test('parses cancelled_reason when present', () {
      final json = <String, dynamic>{
        'cancelled_reason': 'العميل طلب الإلغاء',
      };
      final details = ShippingDetails.fromJson(json);
      expect(details.cancelledReason, 'العميل طلب الإلغاء');
    });

    test('parses cancelled_reason as null when key is absent', () {
      final json = <String, dynamic>{};
      final details = ShippingDetails.fromJson(json);
      expect(details.cancelledReason, isNull);
    });

    test('parses cancelled_reason as null when value is null', () {
      final json = <String, dynamic>{'cancelled_reason': null};
      final details = ShippingDetails.fromJson(json);
      expect(details.cancelledReason, isNull);
    });

    test('parses cancelled_reason as empty string when value is empty', () {
      final json = <String, dynamic>{'cancelled_reason': ''};
      final details = ShippingDetails.fromJson(json);
      // fromJson casts via toString — empty string is preserved
      expect(details.cancelledReason, '');
    });

    test('cancelledReason is included in props for equality', () {
      const a = ShippingDetails(cancelledReason: 'سبب ما');
      const b = ShippingDetails(cancelledReason: 'سبب ما');
      const c = ShippingDetails(cancelledReason: null);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 2. CancellationReasonBanner — isolated widget tests
  // ══════════════════════════════════════════════════════════════════════════

  group('CancellationReasonBanner', () {
    testWidgets('shows label and reason text for cancelled order with reason',
        (tester) async {
      final order = _cancelledOrder(cancelledReason: 'العميل طلب الإلغاء');
      await tester.pumpWidget(_wrap(CancellationReasonBanner(order: order)));

      expect(find.text(AppStrings.cancellationReasonLabel), findsOneWidget);
      expect(find.text('العميل طلب الإلغاء'), findsOneWidget);
      // Fallback message must NOT appear
      expect(find.text(AppStrings.noCancellationReason), findsNothing);
    });

    testWidgets(
        'shows fallback message for cancelled order with null reason',
        (tester) async {
      final order = _cancelledOrder(cancelledReason: null);
      await tester.pumpWidget(_wrap(CancellationReasonBanner(order: order)));

      expect(find.text(AppStrings.cancellationReasonLabel), findsOneWidget);
      expect(find.text(AppStrings.noCancellationReason), findsOneWidget);
    });

    testWidgets(
        'shows fallback message for cancelled order with empty reason',
        (tester) async {
      final order = _cancelledOrder(cancelledReason: '');
      await tester.pumpWidget(_wrap(CancellationReasonBanner(order: order)));

      expect(find.text(AppStrings.cancellationReasonLabel), findsOneWidget);
      expect(find.text(AppStrings.noCancellationReason), findsOneWidget);
    });

    testWidgets(
        'shows fallback message for cancelled order with whitespace-only reason',
        (tester) async {
      final order = _cancelledOrder(cancelledReason: '   ');
      await tester.pumpWidget(_wrap(CancellationReasonBanner(order: order)));

      expect(find.text(AppStrings.cancellationReasonLabel), findsOneWidget);
      expect(find.text(AppStrings.noCancellationReason), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink() for a non-cancelled order',
        (tester) async {
      final order = _confirmedOrder();
      await tester.pumpWidget(_wrap(CancellationReasonBanner(order: order)));

      expect(find.text(AppStrings.cancellationReasonLabel), findsNothing);
      expect(find.text(AppStrings.noCancellationReason), findsNothing);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 3. OrderDetailsHeader integration
  // ══════════════════════════════════════════════════════════════════════════

  group('OrderDetailsHeader — cancellation reason', () {
    testWidgets(
        'shows reason in header for cancelled order with valid reason',
        (tester) async {
      final order =
          _cancelledOrder(cancelledReason: 'المخزن لا يملك المنتج');
      await tester.pumpWidget(_wrap(OrderDetailsHeader(order: order)));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.cancellationReasonLabel), findsOneWidget);
      expect(find.text('المخزن لا يملك المنتج'), findsOneWidget);
      expect(find.text(AppStrings.noCancellationReason), findsNothing);
    });

    testWidgets(
        'shows fallback in header for cancelled order with null reason',
        (tester) async {
      final order = _cancelledOrder(cancelledReason: null);
      await tester.pumpWidget(_wrap(OrderDetailsHeader(order: order)));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.cancellationReasonLabel), findsOneWidget);
      expect(find.text(AppStrings.noCancellationReason), findsOneWidget);
    });

    testWidgets(
        'does NOT show reason field in header for non-cancelled order',
        (tester) async {
      final order = _confirmedOrder();
      await tester.pumpWidget(_wrap(OrderDetailsHeader(order: order)));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.cancellationReasonLabel), findsNothing);
      expect(find.text(AppStrings.noCancellationReason), findsNothing);
    });

    testWidgets('header still shows order number and customer name',
        (tester) async {
      final order = _cancelledOrder(cancelledReason: 'سبب ما');
      await tester.pumpWidget(_wrap(OrderDetailsHeader(order: order)));
      await tester.pumpAndSettle();

      expect(find.text('OL-99'), findsOneWidget);
      expect(find.text('محمد العمري'), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 4. HandoverTabView integration — after timeline card
  // ══════════════════════════════════════════════════════════════════════════

  group('HandoverTabView — cancellation reason after timeline', () {
    Widget buildHandover(OrderDetails order) => _wrap(
          HandoverTabView(
            order: order,
            onUpdateStatus: () {},
          ),
        );

    testWidgets(
        'shows reason after timeline card for cancelled order with valid reason',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final order = _cancelledOrder(cancelledReason: 'العميل غير متاح');
      await tester.pumpWidget(buildHandover(order));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.cancellationReasonLabel), findsWidgets);
      expect(find.text('العميل غير متاح'), findsOneWidget);
      expect(find.text(AppStrings.noCancellationReason), findsNothing);
    });

    testWidgets(
        'shows fallback after timeline card for cancelled order with null reason',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final order = _cancelledOrder(cancelledReason: null);
      await tester.pumpWidget(buildHandover(order));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.cancellationReasonLabel), findsWidgets);
      expect(find.text(AppStrings.noCancellationReason), findsWidgets);
    });

    testWidgets(
        'does NOT show reason field in handover for non-cancelled order',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final order = _confirmedOrder();
      await tester.pumpWidget(buildHandover(order));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.cancellationReasonLabel), findsNothing);
      expect(find.text(AppStrings.noCancellationReason), findsNothing);
    });

    testWidgets('timeline card still appears for cancelled order', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final order = _cancelledOrder(cancelledReason: 'تجربة');
      await tester.pumpWidget(buildHandover(order));
      await tester.pumpAndSettle();

      // Timeline section title must still be present
      expect(find.text('التسلسل التشغيلي'), findsOneWidget);
    });
  });
}
