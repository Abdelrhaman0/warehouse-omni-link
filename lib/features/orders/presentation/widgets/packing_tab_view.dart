import 'package:flutter/material.dart';

import '../../models/order_details.dart';
import 'external_warehouse_invoices_section.dart';
import 'shipping_details_section.dart';

class PackingTabView extends StatelessWidget {
  final OrderDetails order;

  const PackingTabView({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Shipping details & Waybill label
          if (order.shippingDetails != null) ...[
            ShippingDetailsSection(
              shippingDetails: order.shippingDetails!,
            ),
            const SizedBox(height: 16),
          ],

          // 2. External Warehouse Invoices
          if (order.hasExternalWarehouseInvoice ||
              (order.warehouseInvoiceUrl != null &&
                  order.warehouseInvoiceUrl!.trim().isNotEmpty)) ...[
            ExternalWarehouseInvoicesSection(order: order),
            const SizedBox(height: 16),
          ],

          // 3. Packaging Guidelines Banner
          // _buildPackingTipsCard(),
        ],
      ),
    );
  }

  Widget _buildPackingTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB45309),
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'تأكد من تغليف المواد القابلة للكسر بفقاعات الحماية وإلصاق بوليصة الشحن بوضوح على الطرد قبل التقاط الصور.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
