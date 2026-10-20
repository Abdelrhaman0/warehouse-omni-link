import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/order_details.dart';

class CustomerInfoCard extends StatelessWidget {
  final OrderDetails order;

  const CustomerInfoCard({super.key, required this.order});

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final trimmed = phoneNumber.trim();

    if (trimmed.isEmpty) return;

    final Uri phoneUri = Uri(scheme: 'tel', path: trimmed);

    try {
      final launched = await launchUrl(phoneUri);

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.couldNotLaunchUrl),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.couldNotLaunchUrl),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

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
              // icon: Icons.person_outline,
              label: AppStrings.customerName,
              value: order.customerName,
            ),

            if (order.phone != null && order.phone!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailItem(
                // icon: Icons.phone_outlined,
                label: AppStrings.customerPhone,
                value: order.phone!,
                textColor: Colors.blue,
                onTap: () => _makePhoneCall(context, order.phone!),
              ),
            ],

            if (order.whatsapp != null && order.whatsapp!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailItem(
                // icon: Icons.chat_outlined,
                label: AppStrings.customerWhatsApp,
                value: order.whatsapp!,
              ),
            ],

            if (order.address != null && order.address!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailItem(
                // icon: Icons.location_on_outlined,
                label: AppStrings.customerAddress,
                value: order.address!,
              ),
            ],

            if (order.total != null && order.total!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailItem(
                icon: Icons.payments_outlined,
                label: AppStrings.orderTotal,
                value: order.total!.trim(),
              ),
            ],

            if (order.remainingAmount != null &&
                order.remainingAmount!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailItem(
                icon: Icons.account_balance_wallet_outlined,
                label: AppStrings.remainingAmount,
                value: order.remainingAmount!.trim(),
              ),
            ],

            if (order.remainingType != null &&
                order.remainingType!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailItem(
                icon: Icons.category_outlined,
                label: AppStrings.remainingType,
                value: order.remainingType!.trim(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    IconData? icon,
    required String label,
    required String value,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 6),
        ] else
          const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: content,
      );
    }

    return content;
  }
}
