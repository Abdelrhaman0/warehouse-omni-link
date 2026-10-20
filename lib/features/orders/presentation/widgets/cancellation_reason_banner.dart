import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../models/order_details.dart';
import '../../models/order_status.dart';

/// Displays the cancellation reason for a cancelled order.
///
/// Visibility rules:
/// - Rendered only when [order.status] == [OrderStatus.cancelled].
/// - When a non-empty reason exists in [order.shippingDetails.cancelledReason],
///   it is shown verbatim.
/// - When the reason is null, empty, or whitespace-only, the localized fallback
///   [AppStrings.noCancellationReason] is shown instead.
/// - For any other order status, this widget renders nothing (zero height).
class CancellationReasonBanner extends StatelessWidget {
  final OrderDetails order;

  const CancellationReasonBanner({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.status != OrderStatus.cancelled) return const SizedBox.shrink();

    final rawReason = order.shippingDetails?.cancelledReason?.trim();
    final hasReason = rawReason != null && rawReason.isNotEmpty;
    final displayReason =
        hasReason ? rawReason! : AppStrings.noCancellationReason;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cancel_outlined,
            size: 16,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.cancellationReasonLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayReason,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasReason
                        ? const Color(0xFF7F1D1D)
                        : const Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
