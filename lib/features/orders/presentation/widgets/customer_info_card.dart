import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/order_details.dart';

class CustomerInfoCard extends StatelessWidget {
  final OrderDetails order;

  const CustomerInfoCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
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
              children: const [
                Icon(Icons.person_pin, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  AppStrings.sectionCustomerInfo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.divider),
            _buildDetailItem(
              icon: Icons.person_outline,
              label: AppStrings.customerName,
              value: order.customerName,
            ),
            if (order.phone != null && order.phone!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailItem(
                icon: Icons.phone_outlined,
                label: AppStrings.customerPhone,
                value: order.phone!,
              ),
            ],
            if (order.whatsapp != null && order.whatsapp!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailItem(
                icon: Icons.chat_outlined,
                label: AppStrings.customerWhatsApp,
                value: order.whatsapp!,
              ),
            ],
            if (order.address != null && order.address!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailItem(
                icon: Icons.location_on_outlined,
                label: AppStrings.customerAddress,
                value: order.address!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
