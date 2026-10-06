import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warehouse_store_keeper/core/error/failures.dart';
import 'package:warehouse_store_keeper/features/orders/data/orders_repository.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_details.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_media.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/shipment_photos_cubit.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/cubits/shipment_photos_state.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  late MockOrdersRepository mockRepo;

  setUp(() {
    mockRepo = MockOrdersRepository();
    when(() => mockRepo.getUploadedHashes(any())).thenReturn(<String>{});
  });

  group('ShipmentPhotosCubit - Minimum 5 Photos Rule & Upload Robustness', () {
    test('4 total photos (0 existing + 4 new) blocks upload', () async {
      final cubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: 101,
        existingPhotosCount: 0,
      );

      final items = List.generate(
        4,
        (i) => (
          path: '/pic_$i.jpg',
          name: 'pic_$i.jpg',
          bytes: Uint8List.fromList([i, i + 1, i + 2]),
        ),
      );

      await cubit.addRawImages(items);

      expect(cubit.state.selectedImages.length, 4);
      expect(cubit.state.totalCount, 4);
      expect(cubit.state.canUpload, isFalse);
      expect(cubit.state.remainingForMinimum, 1);

      await cubit.uploadPhotos();
      expect(cubit.state, isA<ShipmentPhotosFailure>());
    });

    test('5 total photos (0 existing + 5 new) allows upload', () async {
      final cubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: 101,
        existingPhotosCount: 0,
      );

      final items = List.generate(
        5,
        (i) => (
          path: '/pic_$i.jpg',
          name: 'pic_$i.jpg',
          bytes: Uint8List.fromList([i, i + 10, i + 20]),
        ),
      );

      await cubit.addRawImages(items);

      expect(cubit.state.selectedImages.length, 5);
      expect(cubit.state.totalCount, 5);
      expect(cubit.state.canUpload, isTrue);
      expect(cubit.state.remainingForMinimum, 0);
    });

    test('append behavior: 3 existing + 2 new (total 5) allows upload', () async {
      final cubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: 101,
        existingPhotosCount: 3, // Already 3 uploaded photos
      );

      final items = [
        (path: '/new1.jpg', name: 'new1.jpg', bytes: Uint8List.fromList([1, 2])),
        (path: '/new2.jpg', name: 'new2.jpg', bytes: Uint8List.fromList([3, 4])),
      ];

      await cubit.addRawImages(items);

      expect(cubit.state.existingCount, 3);
      expect(cubit.state.selectedImages.length, 2);
      expect(cubit.state.totalCount, 5);
      expect(cubit.state.canUpload, isTrue);
      expect(cubit.state.remainingForMinimum, 0);
    });

    test('upload failure retains selected images for retry without data loss', () async {
      final cubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: 101,
        existingPhotosCount: 5,
      );

      final items = [
        (path: '/retry_test.jpg', name: 'retry_test.jpg', bytes: Uint8List.fromList([7, 8, 9])),
      ];

      await cubit.addRawImages(items);
      expect(cubit.state.canUpload, isTrue);

      when(() => mockRepo.uploadShipmentPhotos(
            orderId: any(named: 'orderId'),
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenThrow(const NetworkFailure('Network connection lost'));

      await cubit.uploadPhotos();

      expect(cubit.state, isA<ShipmentPhotosFailure>());
      final failureState = cubit.state as ShipmentPhotosFailure;
      expect(failureState.message, 'Network connection lost');
      // Crucial: Images must NOT be lost!
      expect(failureState.selectedImages.length, 1);
      expect(failureState.selectedImages.first.name, 'retry_test.jpg');
    });

    test('upload success clears temporary selection and updates count', () async {
      final cubit = ShipmentPhotosCubit(
        ordersRepository: mockRepo,
        orderId: 101,
        existingPhotosCount: 5,
      );

      final items = [
        (path: '/ok.jpg', name: 'ok.jpg', bytes: Uint8List.fromList([11, 22])),
      ];
      await cubit.addRawImages(items);

      const refreshedOrder = OrderDetails(
        id: 101,
        orderNumber: 'ORD-101',
        status: OrderStatus.confirmed,
        rawStatus: 'confirmed',
        customerName: 'Test Customer',
        canUploadPhotos: true,
        hasShipmentPhotos: true,
        hasWaybillPhotos: false,
        shipmentPhotos: [
          OrderMedia(id: 1, fileName: 'p1.jpg', mimeType: 'image/jpeg', size: 100, url: 'https://cdn.example.com/p1.jpg'),
          OrderMedia(id: 2, fileName: 'p2.jpg', mimeType: 'image/jpeg', size: 100, url: 'https://cdn.example.com/p2.jpg'),
          OrderMedia(id: 3, fileName: 'p3.jpg', mimeType: 'image/jpeg', size: 100, url: 'https://cdn.example.com/p3.jpg'),
          OrderMedia(id: 4, fileName: 'p4.jpg', mimeType: 'image/jpeg', size: 100, url: 'https://cdn.example.com/p4.jpg'),
          OrderMedia(id: 5, fileName: 'p5.jpg', mimeType: 'image/jpeg', size: 100, url: 'https://cdn.example.com/p5.jpg'),
          OrderMedia(id: 6, fileName: 'p6.jpg', mimeType: 'image/jpeg', size: 100, url: 'https://cdn.example.com/p6.jpg'),
        ],
        waybillPhotos: [],
        hasExternalWarehouseInvoice: false,
        externalWarehouseInvoices: [],
        items: [],
      );

      when(() => mockRepo.uploadShipmentPhotos(
            orderId: any(named: 'orderId'),
            photos: any(named: 'photos'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((_) async => refreshedOrder);

      await cubit.uploadPhotos();

      expect(cubit.state, isA<ShipmentPhotosSuccess>());
      final success = cubit.state as ShipmentPhotosSuccess;
      expect(success.selectedImages, isEmpty);
      expect(success.existingCount, 6);
      expect(success.refreshedOrder.id, 101);
    });
  });
}
