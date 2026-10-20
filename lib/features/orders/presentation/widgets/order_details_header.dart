import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/order_details.dart';
import '../../models/order_status.dart';
import 'cancellation_reason_banner.dart';

/// A compact sticky card always visible above the tab bar.
/// Shows: order number (copyable) · customer name · status badge.
class OrderDetailsHeader extends StatelessWidget {
  final OrderDetails order;

  const OrderDetailsHeader({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Order number + customer name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Order number — tap to copy
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: order.orderNumber),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ رقم الطلب'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              order.orderNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Customer name + address snippet
                    Text(
                      _buildSubtitle(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Status badge
              _StatusBadge(status: order.status, rawStatus: order.rawStatus),
            ],
          ),

          // Cancellation reason — shown only for cancelled orders
          if (order.status == OrderStatus.cancelled) ...[
            const SizedBox(height: 8),
            CancellationReasonBanner(order: order),
          ],
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final name = order.customerName.trim();
    final address = order.address?.trim() ?? '';
    if (name.isNotEmpty && address.isNotEmpty) {
      // Show city only (last meaningful part)
      final city = address.split('،').last.trim();
      return '$name • $city';
    }
    if (name.isNotEmpty) return name;
    return 'عميل غير محدد';
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final String rawStatus;

  const _StatusBadge({required this.status, required this.rawStatus});

  @override
  Widget build(BuildContext context) {
    final norm = rawStatus.toLowerCase();
    final label = (norm.contains('refused') || norm.contains('رفض'))
        ? status.localizedLabel
        : (rawStatus.isNotEmpty ? rawStatus : status.localizedLabel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: status.color,
        ),
      ),
    );
  }
}
