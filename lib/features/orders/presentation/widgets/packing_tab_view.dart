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
        ],
      ),
    );
  }
}
