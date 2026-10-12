// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:warehouse_store_keeper/core/localization/app_strings.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_details.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/customer_info_card.dart';

class MockUrlLauncherPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

Map<String, dynamic> _baseOrderJson({Map<String, dynamic>? overrides}) {
  final base = <String, dynamic>{
    'id': 101,
    'order_number': 'ORD-101',
    'status': 'confirmed',
    'customer_name': 'محمد أحمد',
    'phone': '+201012345678',
    'whatsapp': null,
    'address': 'القاهرة، مصر',
    'can_upload_photos': true,
    'has_shipment_photos': false,
    'has_waybill_photos': false,
    'shipment_photos': <dynamic>[],
    'waybill_photos': <dynamic>[],
    'items': <dynamic>[],
    'timestamps': {
      'created_at': '2026-10-01T10:00:00+00:00',
      'confirmed_at': null,
      'shipped_at': null,
    },
  };
  if (overrides != null) base.addAll(overrides);
  return base;
}

Widget _wrapWithApp(
  Widget child, {
  TextDirection textDirection = TextDirection.rtl,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUrlLauncherPlatform mockUrlLauncher;

  setUpAll(() {
    registerFallbackValue(const LaunchOptions());
  });

  setUp(() {
    mockUrlLauncher = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockUrlLauncher;
  });

  group('CustomerInfoCard - Customer phone interaction', () {
    testWidgets('renders phone number and makes it tappable via InkWell', (
      tester,
    ) async {
      final order = OrderDetails.fromJson(_baseOrderJson());

      await tester.pumpWidget(_wrapWithApp(CustomerInfoCard(order: order)));

      // Check phone number is rendered
      expect(find.text('${AppStrings.customerPhone}: '), findsOneWidget);
      expect(find.text('+201012345678'), findsOneWidget);

      // Verify InkWell exists
      final inkWellFinder = find.byType(InkWell);
      expect(inkWellFinder, findsOneWidget);
    });

    testWidgets('tapping phone number row calls launchUrl with tel: URI', (
      tester,
    ) async {
      final order = OrderDetails.fromJson(
        _baseOrderJson(overrides: {'phone': '01012345678'}),
      );

      when(() => mockUrlLauncher.launchUrl('tel:01012345678', any()))
          .thenAnswer((_) async => true);

      await tester.pumpWidget(_wrapWithApp(CustomerInfoCard(order: order)));

      final phoneFinder = find.text('01012345678');
      expect(phoneFinder, findsOneWidget);

      await tester.tap(phoneFinder);
      await tester.pumpAndSettle();

      verify(() => mockUrlLauncher.launchUrl('tel:01012345678', any()))
          .called(1);
    });

    testWidgets('shows snackbar when launch fails', (tester) async {
      final order = OrderDetails.fromJson(
        _baseOrderJson(overrides: {'phone': '01012345678'}),
      );

      when(() => mockUrlLauncher.launchUrl('tel:01012345678', any()))
          .thenAnswer((_) async => false);

      await tester.pumpWidget(_wrapWithApp(CustomerInfoCard(order: order)));

      final phoneFinder = find.text('01012345678');
      await tester.tap(phoneFinder);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.couldNotLaunchUrl), findsOneWidget);
    });

    testWidgets('does not render phone row or crash when phone is null', (
      tester,
    ) async {
      final order = OrderDetails.fromJson(
        _baseOrderJson(overrides: {'phone': null}),
      );

      await tester.pumpWidget(_wrapWithApp(CustomerInfoCard(order: order)));

      expect(find.text('${AppStrings.customerPhone}: '), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets(
      'does not render phone row or crash when phone is empty string',
      (tester) async {
        final order = OrderDetails.fromJson(
          _baseOrderJson(overrides: {'phone': ''}),
        );

        await tester.pumpWidget(_wrapWithApp(CustomerInfoCard(order: order)));

        expect(find.text('${AppStrings.customerPhone}: '), findsNothing);
        expect(find.byType(InkWell), findsNothing);
      },
    );

    testWidgets('renders total price when total is present', (tester) async {
      final order = OrderDetails.fromJson(
        _baseOrderJson(overrides: {'total': '250.00 ر.س'}),
      );

      await tester.pumpWidget(_wrapWithApp(CustomerInfoCard(order: order)));

      expect(find.text('${AppStrings.orderTotal}: '), findsOneWidget);
      expect(find.text('250.00 ر.س'), findsOneWidget);
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
    });

    testWidgets('does not render total price when total is null or empty', (
      tester,
    ) async {
      final orderWithNull = OrderDetails.fromJson(
        _baseOrderJson(overrides: {'total': null}),
      );
      await tester.pumpWidget(
        _wrapWithApp(CustomerInfoCard(order: orderWithNull)),
      );
      expect(find.text('${AppStrings.orderTotal}: '), findsNothing);

      final orderWithEmpty = OrderDetails.fromJson(
        _baseOrderJson(overrides: {'total': ''}),
      );
      await tester.pumpWidget(
        _wrapWithApp(CustomerInfoCard(order: orderWithEmpty)),
      );
      expect(find.text('${AppStrings.orderTotal}: '), findsNothing);
    });

    testWidgets('renders remaining_amount and remaining_type when present', (
      tester,
    ) async {
      final order = OrderDetails.fromJson(
        _baseOrderJson(
          overrides: {
            'remaining_amount': 'EGP 12,000.00',
            'remaining_type': 'مقابل مالي',
          },
        ),
      );

      await tester.pumpWidget(_wrapWithApp(CustomerInfoCard(order: order)));

      expect(find.text('${AppStrings.remainingAmount}: '), findsOneWidget);
      expect(find.text('EGP 12,000.00'), findsOneWidget);
      expect(
        find.byIcon(Icons.account_balance_wallet_outlined),
        findsOneWidget,
      );

      expect(find.text('${AppStrings.remainingType}: '), findsOneWidget);
      expect(find.text('مقابل مالي'), findsOneWidget);
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    });

    testWidgets(
      'does not render remaining_amount and remaining_type when null or empty',
      (tester) async {
        final orderNull = OrderDetails.fromJson(
          _baseOrderJson(
            overrides: {'remaining_amount': null, 'remaining_type': null},
          ),
        );
        await tester.pumpWidget(
          _wrapWithApp(CustomerInfoCard(order: orderNull)),
        );
        expect(find.text('${AppStrings.remainingAmount}: '), findsNothing);
        expect(find.text('${AppStrings.remainingType}: '), findsNothing);

        final orderEmpty = OrderDetails.fromJson(
          _baseOrderJson(
            overrides: {'remaining_amount': '', 'remaining_type': ''},
          ),
        );
        await tester.pumpWidget(
          _wrapWithApp(CustomerInfoCard(order: orderEmpty)),
        );
        expect(find.text('${AppStrings.remainingAmount}: '), findsNothing);
        expect(find.text('${AppStrings.remainingType}: '), findsNothing);
      },
    );

    testWidgets('preserves RTL layout when text direction is RTL', (
      tester,
    ) async {
      final order = OrderDetails.fromJson(_baseOrderJson());

      await tester.pumpWidget(
        _wrapWithApp(
          CustomerInfoCard(order: order),
          textDirection: TextDirection.rtl,
        ),
      );

      final directionality = tester.widget<Directionality>(
        find
            .ancestor(
              of: find.byType(CustomerInfoCard),
              matching: find.byType(Directionality),
            )
            .first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });
  });
}
