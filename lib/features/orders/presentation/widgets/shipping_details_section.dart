import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/shipping_details.dart';
import '../screens/pdf_viewer_screen.dart';

class ShippingDetailsSection extends StatelessWidget {
  final ShippingDetails shippingDetails;

  const ShippingDetailsSection({super.key, required this.shippingDetails});

  @override
  Widget build(BuildContext context) {
    final hasCompany =
        shippingDetails.shippingCompany != null &&
        shippingDetails.shippingCompany!.trim().isNotEmpty;
    final hasWaybill =
        shippingDetails.waybillNumber != null &&
        shippingDetails.waybillNumber!.trim().isNotEmpty;
    final hasStatus =
        shippingDetails.internalStatusText != null &&
        shippingDetails.internalStatusText!.trim().isNotEmpty;
    final hasCourier =
        shippingDetails.courierStatusCode != null &&
        shippingDetails.courierStatusCode!.trim().isNotEmpty;
    // final hasTracking = shippingDetails.trackingUrl != null &&
    //     shippingDetails.trackingUrl!.trim().isNotEmpty;
    final hasLabel =
        shippingDetails.labelUrl != null &&
        shippingDetails.labelUrl!.trim().isNotEmpty;

    final hasAnyData =
        hasCompany || hasWaybill || hasStatus || hasCourier || hasLabel;

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
            // Header
            Row(
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.sectionShippingDetails,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasStatus) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        shippingDetails.internalStatusText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: 20, color: AppColors.divider),

            if (!hasAnyData)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  AppStrings.noShippingDetails,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              )
            else ...[
              if (hasCompany) ...[
                _buildInfoRow(
                  icon: Icons.local_shipping_outlined,
                  label: AppStrings.shippingCompany,
                  value: shippingDetails.shippingCompany!,
                ),
              ],
              if (hasWaybill) ...[
                if (hasCompany) const SizedBox(height: 10),
                _buildCopyableRow(
                  context: context,
                  icon: Icons.confirmation_number_outlined,
                  label: AppStrings.waybillNumber,
                  value: shippingDetails.waybillNumber!,
                ),
              ],
              if (hasStatus) ...[
                if (hasCompany || hasWaybill) const SizedBox(height: 10),
                _buildInfoRow(
                  icon: Icons.sync_alt_outlined,
                  label: AppStrings.shippingStatus,
                  value: shippingDetails.internalStatusText!,
                ),
              ],
              if (hasCourier) ...[
                if (hasCompany || hasWaybill || hasStatus)
                  const SizedBox(height: 10),
                _buildInfoRow(
                  icon: Icons.business_outlined,
                  label: AppStrings.courierCode,
                  value: shippingDetails.courierStatusCode!,
                ),
              ],
              // if (hasTracking) ...[
              //   if (hasWaybill || hasStatus || hasCourier) const SizedBox(height: 10),
              //   _buildLinkRow(
              //     context: context,
              //     icon: Icons.track_changes_outlined,
              //     label: AppStrings.trackingUrl,
              //     url: shippingDetails.trackingUrl!,
              //   ),
              // ],
              if (hasLabel) ...[
                if (hasCompany || hasWaybill || hasStatus || hasCourier)
                  const SizedBox(height: 14),
                _buildLabelPdfButton(
                  context: context,
                  url: shippingDetails.labelUrl!,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
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
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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

  Widget _buildCopyableRow({
    required BuildContext context,
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
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.copiedToClipboard),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.copy_outlined,
              size: 16,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelPdfButton({
    required BuildContext context,
    required String url,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(
                    title: AppStrings.shippingLabelUrl,
                    url: url,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
            label: const Text(
              AppStrings.viewShippingLabel,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.copiedToClipboard),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder, width: 1.2),
            ),
            child: const Icon(
              Icons.copy_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
