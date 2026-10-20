import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/order_status.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final String? rawStatus;
  final bool compact;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.rawStatus,
    this.compact = false,
  });

  String get _displayLabel {
    final raw = rawStatus?.trim();
    if (raw != null && raw.isNotEmpty) {
      if (status == OrderStatus.cancelled || status == OrderStatus.unknown) {
        final normalized = raw.toLowerCase();
        if (normalized.contains('refused') || normalized.contains('رفض')) {
          return status.localizedLabel;
        }
        return raw;
      }
    }
    return status.localizedLabel;
  }

  Color get _badgeBg {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPendingBg;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmedBg;
      case OrderStatus.processing:
        return AppColors.statusProcessingBg;
      case OrderStatus.shipped:
        return AppColors.statusShippedBg;
      case OrderStatus.delivered:
        return AppColors.statusDeliveredBg;
      case OrderStatus.cancelled:
        return AppColors.statusCancelledBg;
      case OrderStatus.unknown:
        return AppColors.statusPendingBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _badgeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _displayLabel,
        style: TextStyle(
          color: status.color,
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
