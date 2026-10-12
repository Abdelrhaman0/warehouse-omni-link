import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/core/localization/app_strings.dart';
import 'package:warehouse_store_keeper/features/orders/models/shipping_details.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/shipping_details_section.dart';

void main() {
  group('ShippingDetails Model', () {
    test('parses shipping_company from json correctly', () {
      final json = <String, dynamic>{
        'shipping_company': 'ايرجنت',
        'waybill_number': null,
        'tracking_url': null,
        'label_url': null,
        'has_waybill_photos': false,
        'waybill_photos': <dynamic>[],
        'internal_status': 'order_received',
        'internal_status_text': 'تم استلام الطلب (الشحن الداخلي)',
        'courier_status_code': null,
      };

      final details = ShippingDetails.fromJson(json);

      expect(details.shippingCompany, 'ايرجنت');
      expect(details.internalStatus, 'order_received');
      expect(details.internalStatusText, 'تم استلام الطلب (الشحن الداخلي)');
      expect(details.waybillNumber, isNull);
    });

    test('handles missing or null shipping_company gracefully', () {
      final json = <String, dynamic>{'shipping_company': null};

      final details = ShippingDetails.fromJson(json);

      expect(details.shippingCompany, isNull);
    });

    test('props equality includes shipping_company', () {
      const a = ShippingDetails(shippingCompany: 'ايرجنت');
      const b = ShippingDetails(shippingCompany: 'ايرجنت');
      const c = ShippingDetails(shippingCompany: 'شركة أخرى');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('ShippingDetailsSection UI', () {
    Widget buildSection(ShippingDetails details) {
      return MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: ShippingDetailsSection(shippingDetails: details),
          ),
        ),
      );
    }

    testWidgets('renders shipping company name when present', (tester) async {
      const details = ShippingDetails(
        shippingCompany: 'ايرجنت',
        internalStatusText: 'تم استلام الطلب (الشحن الداخلي)',
      );

      await tester.pumpWidget(buildSection(details));

      expect(find.text('${AppStrings.shippingCompany}: '), findsOneWidget);
      expect(find.text('ايرجنت'), findsOneWidget);
      expect(
        find.byIcon(Icons.local_shipping_outlined),
        findsNWidgets(2),
      ); // header + info row
    });

    testWidgets('does not render shipping company row when null', (
      tester,
    ) async {
      const details = ShippingDetails(
        shippingCompany: null,
        waybillNumber: 'WB-123',
      );

      await tester.pumpWidget(buildSection(details));

      expect(find.text('${AppStrings.shippingCompany}: '), findsNothing);
      expect(find.text('WB-123'), findsOneWidget);
    });

    testWidgets('renders empty state when no data exists', (tester) async {
      const details = ShippingDetails();

      await tester.pumpWidget(buildSection(details));

      expect(find.text(AppStrings.noShippingDetails), findsOneWidget);
      expect(find.text('${AppStrings.shippingCompany}: '), findsNothing);
    });
  });
}
