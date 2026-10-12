import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/orders_repository.dart';
import '../../models/order_details.dart';
import '../../models/order_summary.dart';
import '../cubits/order_details_cubit.dart';
import '../cubits/order_details_state.dart';
import 'order_status_badge.dart';
import 'order_status_update_sheet.dart';

/// An order card in the list that supports both navigating to details
/// and updating the order status inline.
///
/// It creates a scoped [OrderDetailsCubit] so status updates from the card
/// reuse the exact same repository/cubit logic as [OrderDetailsScreen].
class OrderCard extends StatelessWidget {
  final OrderSummary order;
  final VoidCallback onTap;
  /// Called after a successful status update so the list can refresh.
  final VoidCallback? onStatusUpdated;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onStatusUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderDetailsCubit>(
      // Scoped cubit — shares the same repository as everywhere else.
      create: (_) => OrderDetailsCubit(
        ordersRepository: context.read<OrdersRepository>(),
      ),
      child: _OrderCardBody(
        order: order,
        onTap: onTap,
        onStatusUpdated: onStatusUpdated,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private body: listens to the scoped cubit for status-update feedback
// ─────────────────────────────────────────────────────────────────────────────
class _OrderCardBody extends StatelessWidget {
  final OrderSummary order;
  final VoidCallback onTap;
  final VoidCallback? onStatusUpdated;

  const _OrderCardBody({
    required this.order,
    required this.onTap,
    this.onStatusUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderDetailsCubit, OrderDetailsState>(
      listenWhen: (prev, cur) =>
          (prev is OrderDetailsStatusUpdating && cur is OrderDetailsLoaded) ||
          cur is OrderDetailsStatusUpdateFailure,
      listener: (context, state) {
        if (state is OrderDetailsLoaded) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(AppStrings.statusUpdateSuccess),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          onStatusUpdated?.call();
        } else if (state is OrderDetailsStatusUpdateFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
        }
      },
      child: BlocBuilder<OrderDetailsCubit, OrderDetailsState>(
        builder: (context, detailsState) {
          final isUpdating = detailsState is OrderDetailsStatusUpdating;

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
            ),
            child: InkWell(
              onTap: isUpdating ? null : onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Order Number, Status Badge, Update button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                order.orderNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OrderStatusBadge(
                              status: order.status,
                              rawStatus: order.rawStatus,
                              compact: true,
                            ),
                            const SizedBox(width: 4),
                            // Update status button
                            _UpdateStatusButton(
                              order: order,
                              isUpdating: isUpdating,
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: AppColors.divider),

                        // Customer info
                        _buildCustomerRow(order.customerName),
                        const SizedBox(height: 10),

                        // Items & Date
                        _buildItemsAndDateSection(),
                        const SizedBox(height: 10),

                        // Photos
                        _buildPhotosSection(),
                        const SizedBox(height: 12),

                        // Bottom action row
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: isUpdating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppStrings.details,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: AppColors.primaryLight,
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerRow(String name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.person_outline, size: 16, color: AppColors.textMuted),
        ),
        const SizedBox(width: 6),
        const Text(
          '${AppStrings.customerName}: ',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsAndDateSection() {
    final itemsWidget = _buildInfoItem(
      icon: Icons.inventory_2_outlined,
      label: AppStrings.itemsCount,
      value: '${order.itemsCount}',
    );

    if (order.createdAt == null) {
      return itemsWidget;
    }

    final dateWidget = _buildInfoItem(
      icon: Icons.calendar_today_outlined,
      label: 'التاريخ',
      value: order.createdAt!.split(' ').first,
    );

    return Wrap(spacing: 16, runSpacing: 8, children: [itemsWidget, dateWidget]);
  }

  Widget _buildPhotosSection() {
    final shipmentWidget = _buildPhotoStatusItem(
      icon: Icons.photo_library_outlined,
      label: 'صور الشحنة',
      count: order.shipmentPhotosCount,
      hasPhotos: order.hasShipmentPhotos || order.shipmentPhotosCount > 0,
    );

    final waybillWidget = _buildPhotoStatusItem(
      icon: Icons.receipt_long_outlined,
      label: 'صور البوليصة',
      count: order.waybillPhotosCount,
      hasPhotos: order.hasWaybillPhotos || order.waybillPhotosCount > 0,
    );

    final invoiceWidget = _buildPhotoStatusItem(
      icon: Icons.warehouse_outlined,
      label: AppStrings.sectionExternalWarehouseInvoice,
      count: order.externalWarehouseInvoicesCount,
      hasPhotos:
          order.hasExternalWarehouseInvoice ||
          order.externalWarehouseInvoicesCount > 0,
    );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [shipmentWidget, waybillWidget, invoiceWidget],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Icon(icon, size: 16, color: AppColors.textMuted),
            ),
          ),
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStatusItem({
    required IconData icon,
    required String label,
    required int count,
    required bool hasPhotos,
  }) {
    final statusColor = hasPhotos ? AppColors.success : AppColors.error;
    final statusIcon =
        hasPhotos ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Icon(icon, size: 16, color: AppColors.textMuted),
            ),
          ),
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 3),
              child: Icon(statusIcon, size: 15, color: statusColor),
            ),
          ),
          TextSpan(
            text: '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small icon button that opens the status sheet using the scoped cubit.
// Must be inside a widget tree that has OrderDetailsCubit in scope.
// ─────────────────────────────────────────────────────────────────────────────
class _UpdateStatusButton extends StatelessWidget {
  final OrderSummary order;
  final bool isUpdating;

  const _UpdateStatusButton({required this.order, required this.isUpdating});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppStrings.updateStatusButton,
      child: InkWell(
        onTap: isUpdating ? null : () => _openSheet(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.swap_horiz_rounded,
            size: 18,
            color: isUpdating ? AppColors.textMuted : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    // We only have an OrderSummary here (no full OrderDetails).
    // Build a minimal OrderDetails from the summary so the sheet can display
    // the current status and call the cubit correctly.
    // The cubit.updateOrderStatus will re-fetch the full details after update.
    final minimalOrder = OrderDetails(
      id: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
      rawStatus: order.rawStatus,
      customerName: order.customerName,
      canUploadPhotos: order.canUploadPhotos,
      hasShipmentPhotos: order.hasShipmentPhotos,
      hasWaybillPhotos: order.hasWaybillPhotos,
      hasExternalWarehouseInvoice: order.hasExternalWarehouseInvoice,
      shipmentPhotos: const [],
      waybillPhotos: const [],
      externalWarehouseInvoices: const [],
      items: const [],
    );

    await showOrderStatusUpdateSheet(context, minimalOrder);
  }
}
