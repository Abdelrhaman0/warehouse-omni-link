import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_store_keeper/features/orders/data/orders_repository.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_details.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_item.dart';
import 'package:warehouse_store_keeper/features/orders/models/order_status.dart';
import 'package:warehouse_store_keeper/features/orders/models/shipping_details.dart';
import 'package:warehouse_store_keeper/features/orders/presentation/screens/order_details_screen.dart';

class _FakeOrdersRepo implements OrdersRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<OrderDetails> getOrderDetails(int orderId) async {
    return const OrderDetails(
      id: 10482,
      orderNumber: 'OL-10482',
      status: OrderStatus.confirmed,
      rawStatus: 'مؤكد',
      customerName: 'أحمد الراشد',
      phone: '+966 50 218 6042',
      address: ' شبين الكوم  شارع طلعت حرب ',
      canUploadPhotos: true,
      hasShipmentPhotos: false,
      hasWaybillPhotos: false,
      hasExternalWarehouseInvoice: false,
      shipmentPhotos: [],
      waybillPhotos: [],
      externalWarehouseInvoices: [],
      shippingDetails: ShippingDetails(
        shippingCompany: 'البراق',
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
      ],
      confirmedAt: '2026-10-12 10:02:00',
    );
  }
}

void main() {
  testWidgets('OrderDetailsScreen reproduces overflow', (tester) async {
    tester.view.physicalSize = const Size(384, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      RepositoryProvider<OrdersRepository>(
        create: (_) => _FakeOrdersRepo(),
        child: const MaterialApp(
          home: OrderDetailsScreen(orderId: 10482),
        ),
      ),
    );

    await tester.pumpAndSettle();
  });
}
