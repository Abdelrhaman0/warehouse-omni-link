import 'package:flutter/material.dart';
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
        return raw;
      }
    }
    return status.localizedLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _displayLabel,
            style: TextStyle(
              color: status.color,
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
