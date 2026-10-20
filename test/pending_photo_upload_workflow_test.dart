import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warehouse_store_keeper/core/error/failures.dart';
import 'package:warehouse_store_keeper/core/localization/app_strings.dart';
import 'package:warehouse_store_keeper/core/storage/pending_photos_storage.dart';
import 'package:warehouse_store_keeper/features/orders/data/orders_repository.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_details.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_media.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/models/shipping_details.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/shipment_photos_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/shipment_photos_state.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/waybill_photos_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/waybill_photos_state.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/screens/order_details_screen.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/widgets/photos_tab_view.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SharedPreferences prefs;
  late PendingPhotosStorage storage;
  late MockOrdersRepository mockRepo;

  const int testOrderId = 10482;

  const sampleOrder = OrderDetails(
    id: testOrderId,
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tempDir = await Directory.systemTemp.createTemp('pending_photos_test_');
    storage = PendingPhotosStorage(
      prefs,
      baseDirectoryResolver: () async => tempDir,
    );

    mockRepo = MockOrdersRepository();
    when(() => mockRepo.getUploadedHashes(any())).thenReturn(<String>{});
    when(() => mockRepo.getOrderDetails(any()))
        .thenAnswer((_) async => sampleOrder);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildPhotosTestWidget({
    required ShipmentPhotosCubit shipmentCubit,
    required WaybillPhotosCubit waybillCubit,
    OrderDetails order = sampleOrder,
  }) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<OrdersRepository>.value(value: mockRepo),
              RepositoryProvider<PendingPhotosStorage>.value(value: storage),
            ],
            child: MultiBlocProvider(
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

  group('Pending Photo Upload Workflow & Persistence - 11 Scenarios', () {
    test('1. Selecting shipment photos saves them locally without making an upload request', () async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );

      final photos = List.generate(
        3,
        (i) => (
          path: '/temp_camera/photo_$i.jpg',
          name: 'photo_$i.jpg',
          bytes: createDummyPng(i + 1),
        ),
      );

      await shipmentCubit.addRawImages(photos);

      // Verify no network upload was made
      verifyNever(() => mockRepo.uploadShipmentPhotos(
            orderId: any(named: 'orderId'),
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          ));

      // Verify photos were persisted locally in storage
      final persisted = await storage.loadPendingPhotos(
        orderId: testOrderId,
        category: 'shipment',
      );
      expect(persisted.length, 3);

      // Verify files physically exist on disk in the application storage folder
      for (final item in persisted) {
        expect(File(item.path).existsSync(), isTrue);
      }

      await shipmentCubit.close();
    });

    test('2. Selecting waybill photos preserves previously selected shipment photos', () async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );
      final waybillCubit = WaybillPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );

      // 1. Add shipment photos
      await shipmentCubit.addRawImages(List.generate(
        5,
        (i) => (
          path: '/shipment_$i.jpg',
          name: 'shipment_$i.jpg',
          bytes: createDummyPng(i + 1),
        ),
      ));

      expect(shipmentCubit.state.selectedImages.length, 5);

      // 2. Add waybill photos
      await waybillCubit.addRawImages([
        (
          path: '/waybill_1.jpg',
          name: 'waybill_1.jpg',
          bytes: createDummyPng(99),
        ),
      ]);

      // Shipment photos must NOT be replaced or cleared
      expect(shipmentCubit.state.selectedImages.length, 5);
      expect(waybillCubit.state.selectedImages.length, 1);

      final persistedShipment = await storage.loadPendingPhotos(
        orderId: testOrderId,
        category: 'shipment',
      );
      final persistedWaybill = await storage.loadPendingPhotos(
        orderId: testOrderId,
        category: 'waybill',
      );
      expect(persistedShipment.length, 5);
      expect(persistedWaybill.length, 1);

      await shipmentCubit.close();
      await waybillCubit.close();
    });

    testWidgets('3. When both required photo groups are ready, the upload workflow is triggered', (tester) async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );
      final waybillCubit = WaybillPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );

      await tester.pumpWidget(buildPhotosTestWidget(
        shipmentCubit: shipmentCubit,
        waybillCubit: waybillCubit,
      ));

      // Add 5 shipment photos and 1 waybill photo
      await shipmentCubit.addRawImages(List.generate(
        5,
        (i) => (
          path: '/shipment_$i.jpg',
          name: 'shipment_$i.jpg',
          bytes: createDummyPng(i + 1),
        ),
      ));
      await waybillCubit.addRawImages([
        (path: '/waybill.jpg', name: 'waybill.jpg', bytes: createDummyPng(99)),
      ]);
      await tester.pump();

      when(() => mockRepo.uploadShipmentPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((_) async => sampleOrder);

      when(() => mockRepo.uploadWaybillPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((_) async => sampleOrder);

      // Upload button must now be enabled
      final uploadButtonFinder = find.widgetWithText(ElevatedButton, 'رفع الصور (٦)');
      expect(uploadButtonFinder, findsOneWidget);

      await tester.tap(uploadButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify both upload endpoints were called
      verify(() => mockRepo.uploadShipmentPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).called(1);
      verify(() => mockRepo.uploadWaybillPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).called(1);

      await shipmentCubit.close();
      await waybillCubit.close();
    });

    test('4. Upload success clears pending local state only after confirmation', () async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );

      await shipmentCubit.addRawImages(List.generate(
        5,
        (i) => (
          path: '/shipment_$i.jpg',
          name: 'shipment_$i.jpg',
          bytes: createDummyPng(i + 1),
        ),
      ));

      // Photos are currently persisted locally
      expect((await storage.loadPendingPhotos(orderId: testOrderId, category: 'shipment')).length, 5);

      when(() => mockRepo.uploadShipmentPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((_) async => sampleOrder);

      await shipmentCubit.uploadPhotos();

      expect(shipmentCubit.state, isA<ShipmentPhotosSuccess>());

      // After confirmation, pending files and metadata must be cleared
      final persistedAfter = await storage.loadPendingPhotos(
        orderId: testOrderId,
        category: 'shipment',
      );
      expect(persistedAfter, isEmpty);

      await shipmentCubit.close();
    });

    test('5. Upload failure preserves all local files and supports retry', () async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );

      await shipmentCubit.addRawImages(List.generate(
        5,
        (i) => (
          path: '/shipment_$i.jpg',
          name: 'shipment_$i.jpg',
          bytes: createDummyPng(i + 1),
        ),
      ));

      when(() => mockRepo.uploadShipmentPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenThrow(const NetworkFailure('Network connection failed'));

      await shipmentCubit.uploadPhotos();

      expect(shipmentCubit.state, isA<ShipmentPhotosFailure>());

      // All local files must remain completely intact
      final persisted = await storage.loadPendingPhotos(
        orderId: testOrderId,
        category: 'shipment',
      );
      expect(persisted.length, 5);
      for (final item in persisted) {
        expect(File(item.path).existsSync(), isTrue);
      }
      expect(shipmentCubit.state.selectedImages.length, 5);

      // Retry: network succeeds now
      when(() => mockRepo.uploadShipmentPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((_) async => sampleOrder);

      await shipmentCubit.uploadPhotos();
      expect(shipmentCubit.state, isA<ShipmentPhotosSuccess>());

      // Cleared after successful retry
      expect((await storage.loadPendingPhotos(orderId: testOrderId, category: 'shipment')), isEmpty);

      await shipmentCubit.close();
    });

    testWidgets('6. Navigating away from and returning to Photos tab preserves pending photos', (tester) async {
      when(() => mockRepo.getOrderDetails(testOrderId))
          .thenAnswer((_) async => sampleOrder);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<OrdersRepository>.value(value: mockRepo),
              RepositoryProvider<PendingPhotosStorage>.value(value: storage),
            ],
            child: const OrderDetailsScreen(orderId: testOrderId, initialTab: 2),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final shipmentCubit = tester.element(find.byType(PhotosTabView)).read<ShipmentPhotosCubit>();

      await shipmentCubit.addRawImages(List.generate(
        2,
        (i) => (
          path: '/img_$i.jpg',
          name: 'img_$i.jpg',
          bytes: createDummyPng(i + 1),
        ),
      ));
      await tester.pump();

      // Verify photos are visible
      expect(find.text(AppStrings.pendingUploadBadge), findsNWidgets(2));

      // Switch to Tab 0 (Picking)
      await tester.tap(find.text('العميل'));
      await tester.pump();

      // Switch back to Tab 2 (Photos)
      await tester.tap(find.text('الصور'));
      await tester.pump();

      // Verify photos remain visible
      expect(find.text(AppStrings.pendingUploadBadge), findsNWidgets(2));
    });

    test('7. Pending photos are restored after an app restart from local storage', () async {
      // Session 1: User adds photos
      final cubitSession1 = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );
      await cubitSession1.addRawImages([
        (path: '/cam1.jpg', name: 'cam1.jpg', bytes: createDummyPng(10)),
        (path: '/cam2.jpg', name: 'cam2.jpg', bytes: createDummyPng(20)),
      ]);
      await cubitSession1.close();

      // Session 2: User restarts app and reopens the order
      final cubitSession2 = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
        autoLoad: false,
      );
      expect(cubitSession2.state.selectedImages, isEmpty);

      // Trigger restore
      await cubitSession2.loadPendingPhotos();

      expect(cubitSession2.state.selectedImages.length, 2);
      expect(cubitSession2.state.selectedImages[0].name, 'cam1.jpg');
      expect(cubitSession2.state.selectedImages[1].name, 'cam2.jpg');
      expect(cubitSession2.state.selectedImages[0].bytes, createDummyPng(10));

      await cubitSession2.close();
    });

    test('8. Pending photos belonging to one order never appear in another order', () async {
      const orderA = 1001;
      const orderB = 2002;

      // Add photos for Order A
      final cubitA = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: orderA,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );
      await cubitA.addRawImages([
        (path: '/orderA.jpg', name: 'orderA.jpg', bytes: createDummyPng(1)),
      ]);
      await cubitA.close();

      // Open Order B
      final cubitB = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: orderB,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );
      await cubitB.loadPendingPhotos();

      // Order B must NOT see Order A's photos
      expect(cubitB.state.selectedImages, isEmpty);

      final persistedB = await storage.loadPendingPhotos(orderId: orderB, category: 'shipment');
      expect(persistedB, isEmpty);

      final persistedA = await storage.loadPendingPhotos(orderId: orderA, category: 'shipment');
      expect(persistedA.length, 1);
      expect(persistedA.first.name, 'orderA.jpg');

      await cubitB.close();
    });

    test('9. Repeated events do not trigger duplicate concurrent uploads', () async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );

      await shipmentCubit.addRawImages(List.generate(
        5,
        (i) => (path: '/p$i.jpg', name: 'p$i.jpg', bytes: createDummyPng(i + 1)),
      ));

      final completer = Completer<OrderDetails>();
      when(() => mockRepo.uploadShipmentPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((_) => completer.future);

      // Trigger first upload
      final firstUpload = shipmentCubit.uploadPhotos();
      expect(shipmentCubit.state, isA<ShipmentPhotosUploading>());

      // Trigger second upload while first is in-flight
      final secondUpload = shipmentCubit.uploadPhotos();

      // Complete the in-flight request
      completer.complete(sampleOrder);
      await firstUpload;
      await secondUpload;

      // Ensure mockRepo.uploadShipmentPhotos was called only once!
      verify(() => mockRepo.uploadShipmentPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).called(1);

      await shipmentCubit.close();
    });

    testWidgets('10. Existing server-backed photos continue to display correctly with pending photos', (tester) async {
      const existingOrder = OrderDetails(
        id: testOrderId,
        orderNumber: 'OL-10482',
        status: OrderStatus.processing,
        rawStatus: 'قيد التجهيز',
        customerName: 'أحمد الراشد',
        canUploadPhotos: true,
        hasShipmentPhotos: true,
        hasWaybillPhotos: true,
        hasExternalWarehouseInvoice: false,
        shippingDetails: ShippingDetails(
          shippingCompany: 'سمسا',
          internalStatusText: 'خدمة قياسية',
        ),
        shipmentPhotos: [
          OrderMedia(
            id: 1,
            fileName: 'remote_shipment.jpg',
            mimeType: 'image/jpeg',
            size: 2048,
            url: 'https://cdn.example.com/remote_shipment.jpg',
          ),
        ],
        waybillPhotos: [
          OrderMedia(
            id: 2,
            fileName: 'remote_waybill.jpg',
            mimeType: 'image/jpeg',
            size: 4096,
            url: 'https://cdn.example.com/remote_waybill.jpg',
          ),
        ],
        externalWarehouseInvoices: [],
        items: [],
      );

      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 1,
        pendingPhotosStorage: storage,
      );
      final waybillCubit = WaybillPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 1,
        pendingPhotosStorage: storage,
      );

      await tester.pumpWidget(buildPhotosTestWidget(
        shipmentCubit: shipmentCubit,
        waybillCubit: waybillCubit,
        order: existingOrder,
      ));

      // Add a new local shipment photo
      await shipmentCubit.addRawImages([
        (path: '/local_shipment.jpg', name: 'local_shipment.jpg', bytes: createDummyPng(5)),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Server-backed waybill title is visible
      expect(find.text(AppStrings.uploadedWaybillTitle), findsOneWidget);

      // Pending upload badge is shown on the locally added photo
      expect(find.text(AppStrings.pendingUploadBadge), findsOneWidget);

      await shipmentCubit.close();
      await waybillCubit.close();
    });

    testWidgets('11. Partial failures are handled safely when backend requires multiple upload requests', (tester) async {
      final shipmentCubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );
      final waybillCubit = WaybillPhotosCubit(
        ordersRepository: mockRepo,
        orderId: testOrderId,
        existingPhotosCount: 0,
        pendingPhotosStorage: storage,
      );

      await tester.pumpWidget(buildPhotosTestWidget(
        shipmentCubit: shipmentCubit,
        waybillCubit: waybillCubit,
      ));

      await shipmentCubit.addRawImages(List.generate(
        5,
        (i) => (path: '/s$i.jpg', name: 's$i.jpg', bytes: createDummyPng(i + 1)),
      ));
      await waybillCubit.addRawImages([
        (path: '/wb.jpg', name: 'wb.jpg', bytes: createDummyPng(88)),
      ]);
      await tester.pump();

      // Shipment upload succeeds, but waybill fails!
      when(() => mockRepo.uploadShipmentPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((_) async => sampleOrder);

      when(() => mockRepo.uploadWaybillPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenThrow(const ServerFailure('Waybill server failed'));

      final uploadButton = find.widgetWithText(ElevatedButton, 'رفع الصور (٦)');
      await tester.tap(uploadButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Shipment succeeded -> cleared from pending storage
      expect((await storage.loadPendingPhotos(orderId: testOrderId, category: 'shipment')), isEmpty);

      // Waybill failed -> KEPT in pending storage for retry!
      final remainingWaybill = await storage.loadPendingPhotos(orderId: testOrderId, category: 'waybill');
      expect(remainingWaybill.length, 1);
      expect(waybillCubit.state, isA<WaybillPhotosFailure>());

      // Retry: Now waybill server succeeds
      when(() => mockRepo.uploadWaybillPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((_) async => sampleOrder);

      // When retrying, shipment photos are already cleared and NOT re-uploaded!
      clearInteractions(mockRepo);
      when(() => mockRepo.uploadWaybillPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((_) async => sampleOrder);

      await waybillCubit.uploadPhotos();
      expect(waybillCubit.state, isA<WaybillPhotosSuccess>());

      // Verify shipment upload was NEVER called again during waybill retry
      verifyNever(() => mockRepo.uploadShipmentPhotos(
            orderId: any(named: 'orderId'),
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          ));
      verify(() => mockRepo.uploadWaybillPhotos(
            orderId: testOrderId,
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).called(1);

      // Waybill is now cleared after success
      expect((await storage.loadPendingPhotos(orderId: testOrderId, category: 'waybill')), isEmpty);

      await shipmentCubit.close();
      await waybillCubit.close();
    });
  });
}
