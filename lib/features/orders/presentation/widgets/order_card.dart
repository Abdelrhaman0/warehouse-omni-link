import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/order_summary.dart';
import 'order_status_badge.dart';

class OrderCard extends StatelessWidget {
  final OrderSummary order;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Order Number and Status Badge
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
                      OrderStatusBadge(status: order.status, compact: true),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.divider),

                  // Customer info row
                  _buildCustomerRow(order.customerName),
                  const SizedBox(height: 10),

                  // Items count & Date (adaptive wrap)
                  _buildItemsAndDateSection(),
                  const SizedBox(height: 10),

                  // Photos row (adaptive wrap)
                  _buildPhotosSection(),
                  const SizedBox(height: 12),

                  // Bottom action row: "عرض التفاصيل"
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
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
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
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

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        itemsWidget,
        dateWidget,
      ],
    );
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
      hasPhotos: order.hasExternalWarehouseInvoice || order.externalWarehouseInvoicesCount > 0,
    );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        shipmentWidget,
        waybillWidget,
        invoiceWidget,
      ],
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
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
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
    final statusIcon = hasPhotos ? Icons.check_circle_rounded : Icons.cancel_rounded;

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
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 3),
              child: Icon(
                statusIcon,
                size: 15,
                color: statusColor,
              ),
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
