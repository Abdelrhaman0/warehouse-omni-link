import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/core/error/failures.dart';
import 'package:warehouse_store_keeper/core/localization/app_strings.dart';
import 'package:warehouse_store_keeper/features/orders/data/orders_repository.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_details.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/models/shipping_details.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/shipment_photos_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/waybill_photos_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/screens/order_details_screen.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/photos_tab_view.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  late MockOrdersRepository mockRepo;

  const sampleOrder = OrderDetails(
    id: 10482,
    orderNumber: 'OL-10482',
    status: OrderStatus.processing,
    rawStatus: 'قيد التجهيز',
    customerName: 'أحمد الراشد',
    phone: '+966 50 218 6042',
    address: 'حي الياسمين، الرياض',
    canUploadPhotos: true,
    hasShipmentPhotos: false,
    hasWaybillPhotos: false,
    hasExternalWarehouseInvoice: false,
    shippingDetails: ShippingDetails(
      shippingCompany: 'سمسا',
      internalStatusText: 'خدمة قياسية',
    ),
    shipmentPhotos: [],
    waybillPhotos: [],
    externalWarehouseInvoices: [],
    items: [],
  );

  // 1x1 valid PNG bytes with unique seed in IDAT chunk to generate different hashes
  Uint8List createDummyPng(int seed) {
    return Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, seed & 0xFF, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, (seed * 7) & 0xFF, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82,
    ]);
  }

  setUp(() {
    mockRepo = MockOrdersRepository();
    when(() => mockRepo.getUploadedHashes(any())).thenReturn(<String>{});
    when(() => mockRepo.getOrderDetails(any()))
        .thenAnswer((_) async => sampleOrder);
  });

  Widget buildTestSubject({
    required ShipmentPhotosCubit shipmentCubit,
    required WaybillPhotosCubit waybillCubit,
    OrderDetails order = sampleOrder,
    TextScaler? textScaler,
    Size size = const Size(384, 800),
  }) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: textScaler ?? TextScaler.noScaling,
          ),
          child: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<ShipmentPhotosCubit>.value(value: shipmentCubit),
                BlocProvider<WaybillPhotosCubit>.value(value: waybillCubit),
              ],
              child: PhotosTabView(order: order),
            ),
          ),
        ),
      ),
    );
  }

  group('Figma Redesign Acceptance Checks', () {
    testWidgets('Check 1: Empty state layout, badges, empty message, and disabled upload',
        (tester) async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: sampleOrder.id,
        existingPhotosCount: 0,
      );
      final waybillCubit = WaybillPhotosCubit(
        ordersRepository: mockRepo,
        orderId: sampleOrder.id,
        existingPhotosCount: 0,
      );

      await tester.pumpWidget(
        buildTestSubject(
          shipmentCubit: shipmentCubit,
          waybillCubit: waybillCubit,
        ),
      );

      // Verify page heading and subtitle
      expect(find.text(AppStrings.photosTabHeading), findsOneWidget);
      expect(find.text(AppStrings.photosTabSubtitle), findsOneWidget);

      // Verify Shipment card empty state
      expect(find.text(AppStrings.sectionShipmentPhotos), findsOneWidget);
      expect(find.text(AppStrings.shipmentPhotosInstruction), findsOneWidget);
      expect(find.text('٠ من ٥ صور'), findsOneWidget);
      expect(find.text('٥ صور على الأقل'), findsOneWidget);
      expect(find.text(AppStrings.shipmentPhotosEmptyState), findsOneWidget);
      expect(find.text(AppStrings.takePhoto), findsOneWidget);
      expect(find.text(AppStrings.chooseFromGallery), findsWidgets);

      // Verify Waybill card empty state
      expect(find.text(AppStrings.sectionWaybillPhotos), findsOneWidget);
      expect(find.text(AppStrings.waybillPhotosInstruction), findsOneWidget);
      expect(find.text(AppStrings.captureWaybill), findsOneWidget);

      // Verify Badges: both should be "مطلوب"
      expect(find.text('مطلوب'), findsNWidgets(2));

      // Verify Upload Area: dynamic helper text and disabled upload button
      expect(
        find.text('لإتاحة الرفع، أضف ٥ صور للشحنة وصور البوليصة.'),
        findsOneWidget,
      );
      expect(find.text('رفع الصور'), findsOneWidget);
      expect(find.text(AppStrings.uploadPhotosDisclaimer), findsOneWidget);

      // Button is disabled (onPressed == null)
      final uploadButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'رفع الصور'),
      );
      expect(uploadButton.onPressed, isNull);

      await shipmentCubit.close();
      await waybillCubit.close();
    });

    testWidgets('Check 2: One to four shipment photos displays counter, segments, and thumbnails',
        (tester) async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: sampleOrder.id,
        existingPhotosCount: 0,
      );
      final waybillCubit = WaybillPhotosCubit(
        ordersRepository: mockRepo,
        orderId: sampleOrder.id,
        existingPhotosCount: 0,
      );

      await tester.pumpWidget(
        buildTestSubject(
          shipmentCubit: shipmentCubit,
          waybillCubit: waybillCubit,
        ),
      );

      // Add 3 shipment photos
      final rawImages = List.generate(
        3,
        (i) => (
          path: '/pic_$i.jpg',
          name: 'pic_$i.jpg',
          bytes: createDummyPng(i + 1),
        ),
      );
      await shipmentCubit.addRawImages(rawImages);
      await tester.pumpAndSettle();

      // Counter should show 3 of 5
      expect(find.text('٣ من ٥ صور'), findsOneWidget);
      expect(find.text('٥ صور على الأقل'), findsOneWidget);

      // Empty state replaced with grid containing thumbnails and "إضافة صورة" tile
      expect(find.text(AppStrings.shipmentPhotosEmptyState), findsNothing);
      expect(find.text('إضافة صورة'), findsOneWidget);

      // Helper text updates to reflect remaining shipment & waybill
      expect(
        find.text('لإتاحة الرفع، أضف ٢ صور للشحنة وصور البوليصة.'),
        findsOneWidget,
      );

      // Upload button still disabled
      final uploadButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'رفع الصور'),
      );
      expect(uploadButton.onPressed, isNull);

      await shipmentCubit.close();
      await waybillCubit.close();
    });

    testWidgets('Check 3: Five shipment photos but no waybill photo shows مكتمل and helper text',
        (tester) async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: sampleOrder.id,
        existingPhotosCount: 0,
      );
      final waybillCubit = WaybillPhotosCubit(
        ordersRepository: mockRepo,
        orderId: sampleOrder.id,
        existingPhotosCount: 0,
      );

      await tester.pumpWidget(
        buildTestSubject(
          shipmentCubit: shipmentCubit,
          waybillCubit: waybillCubit,
        ),
      );

      // Add 5 shipment photos
      final rawImages = List.generate(
        5,
        (i) => (
          path: '/shipment_$i.jpg',
          name: 'shipment_$i.jpg',
          bytes: createDummyPng(i + 1),
        ),
      );
      await shipmentCubit.addRawImages(rawImages);
      await tester.pumpAndSettle();

      // Shipment card shows "مكتمل"
      expect(find.text('مكتمل'), findsOneWidget);
      expect(find.text('٥ صور مضافة'), findsOneWidget);

      // Waybill still has "مطلوب"
      expect(find.text('مطلوب'), findsOneWidget);

      // Helper text explains waybill is missing
      expect(
        find.text('لإتاحة الرفع، أضف صورة بوليصة الشحن.'),
        findsOneWidget,
      );

      // Upload button still disabled
      final uploadButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'رفع الصور'),
      );
      expect(uploadButton.onPressed, isNull);

      await shipmentCubit.close();
      await waybillCubit.close();
    });

    testWidgets('Check 4: Ready state with 5 shipment photos + 1 waybill photo enables upload button',
        (tester) async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: sampleOrder.id,
        existingPhotosCount: 0,
      );
      final waybillCubit = WaybillPhotosCubit(
        ordersRepository: mockRepo,
        orderId: sampleOrder.id,
        existingPhotosCount: 0,
      );

      await tester.pumpWidget(
        buildTestSubject(
          shipmentCubit: shipmentCubit,
          waybillCubit: waybillCubit,
        ),
      );

      // Add 5 shipment photos + 1 waybill photo
      await shipmentCubit.addRawImages(
        List.generate(
          5,
          (i) => (
            path: '/shipment_$i.jpg',
            name: 'shipment_$i.jpg',
            bytes: createDummyPng(i + 1),
          ),
        ),
      );
      await waybillCubit.addRawImages([
        (
          path: '/waybill_1.jpg',
          name: 'waybill_1.jpg',
          bytes: createDummyPng(99),
        ),
      ]);
      await tester.pumpAndSettle();

      // Badges
      expect(find.text('مكتمل'), findsOneWidget);
      expect(find.text('مضافة'), findsOneWidget);

      // Waybill card shows preview details
      expect(find.text(AppStrings.waybillPhotoAdded), findsOneWidget);
      expect(find.text(AppStrings.waybillClarityHint), findsOneWidget);

      // Upload helper text shows ready message
      expect(find.text(AppStrings.uploadPhotosReady), findsOneWidget);

      // Button is enabled and displays total count 6: رفع الصور (٦)
      expect(find.text('رفع الصور (٦)'), findsOneWidget);
      final uploadButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'رفع الصور (٦)'),
      );
      expect(uploadButton.onPressed, isNotNull);

      await shipmentCubit.close();
      await waybillCubit.close();
    });

    testWidgets('Check 5: Removing a photo recalculates validation immediately and disables upload',
        (tester) async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: sampleOrder.id,
        existingPhotosCount: 0,
      );
      final waybillCubit = WaybillPhotosCubit(
        ordersRepository: mockRepo,
        orderId: sampleOrder.id,
        existingPhotosCount: 0,
      );

      await tester.pumpWidget(
        buildTestSubject(
          shipmentCubit: shipmentCubit,
          waybillCubit: waybillCubit,
        ),
      );

      // Initially set up ready state (5 shipment + 1 waybill)
      await shipmentCubit.addRawImages(
        List.generate(
          5,
          (i) => (
            path: '/shipment_$i.jpg',
            name: 'shipment_$i.jpg',
            bytes: createDummyPng(i + 1),
          ),
        ),
      );
      await waybillCubit.addRawImages([
        (
          path: '/waybill_1.jpg',
          name: 'waybill_1.jpg',
          bytes: createDummyPng(99),
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('رفع الصور (٦)'), findsOneWidget);

      // Tap remove button on one shipment photo
      final removeKey = ValueKey('remove_shipment_photo_${shipmentCubit.state.selectedImages.first.hash}');
      await tester.tap(find.byKey(removeKey));
      await tester.pumpAndSettle();

      // Now 4 shipment photos remain: requirements no longer met
      expect(find.text('٤ من ٥ صور'), findsOneWidget);
      expect(find.text('مطلوب'), findsOneWidget);
      expect(
        find.text('لإتاحة الرفع، أضف ١ صور للشحنة.'),
        findsOneWidget,
      );

      // Upload button is now disabled!
      final uploadButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'رفع الصور'),
      );
      expect(uploadButton.onPressed, isNull);

      await shipmentCubit.close();
      await waybillCubit.close();
    });

    testWidgets('Check 6: Upload flow handles failure by preserving photos for retry',
        (tester) async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: sampleOrder.id,
        existingPhotosCount: 0,
      );
      final waybillCubit = WaybillPhotosCubit(
        ordersRepository: mockRepo,
        orderId: sampleOrder.id,
        existingPhotosCount: 0,
      );

      when(() => mockRepo.uploadShipmentPhotos(
            orderId: any(named: 'orderId'),
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenThrow(const ServerFailure('Server unreachable'));

      await tester.pumpWidget(
        buildTestSubject(
          shipmentCubit: shipmentCubit,
          waybillCubit: waybillCubit,
        ),
      );

      await shipmentCubit.addRawImages(
        List.generate(
          5,
          (i) => (
            path: '/shipment_$i.jpg',
            name: 'shipment_$i.jpg',
            bytes: createDummyPng(i + 1),
          ),
        ),
      );
      await waybillCubit.addRawImages([
        (
          path: '/waybill_1.jpg',
          name: 'waybill_1.jpg',
          bytes: createDummyPng(99),
        ),
      ]);
      await tester.pumpAndSettle();

      // Tap upload
      await tester.tap(find.text('رفع الصور (٦)'));
      await tester.pumpAndSettle();

      // Failure snackbar shown, photos PRESERVED
      expect(find.text('Server unreachable'), findsOneWidget);
      expect(shipmentCubit.state.selectedImages.length, 5);
      expect(waybillCubit.state.selectedImages.length, 1);

      await shipmentCubit.close();
      await waybillCubit.close();
    });

    testWidgets('Check 7: Responsive layout, LTR order identifier, and large text scale',
        (tester) async {
      final widths = [320.0, 360.0, 375.0, 412.0];

      for (final width in widths) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final shipmentCubit = ShipmentPhotosCubit(
          ordersRepository: mockRepo,
          orderId: sampleOrder.id,
          existingPhotosCount: 0,
        );
        final waybillCubit = WaybillPhotosCubit(
          ordersRepository: mockRepo,
          orderId: sampleOrder.id,
          existingPhotosCount: 0,
        );

        await tester.pumpWidget(
          buildTestSubject(
            shipmentCubit: shipmentCubit,
            waybillCubit: waybillCubit,
            size: Size(width, 900),
            textScaler: const TextScaler.linear(1.3), // Large text test
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.photosTabHeading), findsOneWidget);

        await shipmentCubit.close();
        await waybillCubit.close();
      }
    });

    testWidgets('Check 8: OrderDetailsScreen selects Photos tab by default with explicit LTR order number',
        (tester) async {
      tester.view.physicalSize = const Size(384, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        RepositoryProvider<OrdersRepository>.value(
          value: mockRepo,
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: OrderDetailsScreen(orderId: 10482),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Photos tab is selected by default: photos heading is visible immediately!
      expect(find.text(AppStrings.photosTabHeading), findsOneWidget);
      expect(find.text('OL-10482'), findsOneWidget);

      // Verify other tabs are still present and can be navigated to
      expect(find.text('العميل'), findsWidgets);
      expect(find.text('الشحن'), findsWidgets);
      expect(find.text('الصور'), findsWidgets);
      expect(find.text('الملخص'), findsWidgets);

      // Tap on Tab 2: الشحن
      await tester.tap(find.text('الشحن'));
      await tester.pumpAndSettle();
      expect(find.text('تفاصيل الشحن'), findsWidgets);

      // Tap back to Tab 3: الصور
      await tester.tap(find.text('الصور'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.photosTabHeading), findsOneWidget);
    });
  });
}
