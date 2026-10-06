import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/orders_repository.dart';
import '../../models/order_details.dart';
import '../cubits/order_details_cubit.dart';
import '../cubits/order_details_state.dart';
import '../cubits/shipment_photos_cubit.dart';
import '../cubits/waybill_photos_cubit.dart';
import '../widgets/customer_info_card.dart';
import '../widgets/shipping_details_section.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/product_item_card.dart';
import '../widgets/shipment_photos_section.dart';
import '../widgets/waybill_photos_section.dart';
import '../widgets/external_warehouse_invoices_section.dart';

class OrderDetailsScreen extends StatelessWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderDetailsCubit(
        ordersRepository: context.read<OrdersRepository>(),
      )..loadOrderDetails(orderId),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${AppStrings.details} #$orderId'),
          actions: [
            Builder(
              builder: (ctx) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'تحديث',
                  onPressed: () => ctx.read<OrderDetailsCubit>().refreshOrderDetails(),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<OrderDetailsCubit, OrderDetailsState>(
          builder: (context, state) {
            if (state is OrderDetailsLoading) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'جارٍ تحميل تفاصيل الطلب...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            if (state is OrderDetailsFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.read<OrderDetailsCubit>().loadOrderDetails(orderId),
                        icon: const Icon(Icons.refresh),
                        label: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is OrderDetailsLoaded) {
              final order = state.order;
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (context) => ShipmentPhotosCubit(
                      ordersRepository: context.read<OrdersRepository>(),
                      orderId: order.id,
                      existingPhotosCount: order.shipmentPhotos.length,
                    ),
                  ),
                  BlocProvider(
                    create: (context) => WaybillPhotosCubit(
                      ordersRepository: context.read<OrdersRepository>(),
                      orderId: order.id,
                      existingPhotosCount: order.waybillPhotos.length,
                    ),
                  ),
                ],
                child: RefreshIndicator(
                  onRefresh: () => context.read<OrderDetailsCubit>().refreshOrderDetails(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Header Card
                        _buildOrderHeaderCard(order),
                        const SizedBox(height: 16),

                        // Customer Information
                        CustomerInfoCard(order: order),
                        const SizedBox(height: 16),

                        // Shipping Details (تفاصيل الشحن)
                        if (order.shippingDetails != null) ...[
                          ShippingDetailsSection(shippingDetails: order.shippingDetails!),
                          const SizedBox(height: 16),
                        ],
                        // External Warehouse Invoice (فاتورة المخزن)
                        // Shown only when the backend reports one or more invoices.
                        if (order.hasExternalWarehouseInvoice) ...[
                          ExternalWarehouseInvoicesSection(order: order),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 16,),
                        // Products
                        _buildProductsSection(order),
                        const SizedBox(height: 16),

                        // Shipment / Product Photos
                        ShipmentPhotosSection(order: order),
                        const SizedBox(height: 16),

                        // Waybill Photos
                        WaybillPhotosSection(order: order),
                        const SizedBox(height: 8),

                      ],
                    ),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildOrderHeaderCard(OrderDetails order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const Divider(height: 20, color: AppColors.divider),
            if (order.createdAt != null) ...[
              _buildTimestampRow(AppStrings.createdAt, order.createdAt!),
              const SizedBox(height: 6),
            ],
            if (order.confirmedAt != null) ...[
              _buildTimestampRow(AppStrings.confirmedAt, order.confirmedAt!),
              const SizedBox(height: 6),
            ],
            if (order.shippedAt != null) ...[
              _buildTimestampRow(AppStrings.shippedAt, order.shippedAt!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.schedule, size: 15, color: AppColors.textMuted),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection(OrderDetails order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${AppStrings.sectionItems} (${order.items.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.divider),
            if (order.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'لا توجد منتجات مسجلة لهذا الطلب',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return ProductItemCard(item: order.items[index]);
                },
              ),
          ],
        ),
      ),
    );
  }
}
