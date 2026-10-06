import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';

enum OrderStatus {
  pending('pending', AppStrings.statusPending),
  confirmed('confirmed', AppStrings.statusConfirmed),
  processing('processing', AppStrings.statusProcessing),
  shipped('shipped', AppStrings.statusShipped),
  delivered('delivered', AppStrings.statusDelivered),
  cancelled('cancelled', AppStrings.statusCancelled),
  unknown('unknown', AppStrings.statusUnknown);

  final String apiValue;
  final String localizedLabel;

  const OrderStatus(this.apiValue, this.localizedLabel);

  /// Parse backend status string into enum.
  /// Handles both English status keys and Arabic localized labels returned by API.
  /// Gracefully falls back to unknown without crashing.
  static OrderStatus fromString(String? value) {
    if (value == null) return OrderStatus.unknown;
    final trimmed = value.trim();
    final normalized = trimmed.toLowerCase();

    // 1. Direct match with apiValue or localizedLabel
    for (final status in OrderStatus.values) {
      if (status.apiValue == normalized || status.localizedLabel == trimmed) {
        return status;
      }
    }

    // 2. Arabic & English keyword matching
    if (normalized.contains('تأكيد') || normalized == 'confirmed') {
      return OrderStatus.confirmed;
    }
    if (normalized.contains('معالج') || normalized == 'processing') {
      return OrderStatus.processing;
    }
    if (normalized.contains('شحن') || normalized == 'shipped' || normalized == 'shipping') {
      return OrderStatus.shipped;
    }
    if (normalized.contains('توصيل') || normalized.contains('تسليم') || normalized == 'delivered') {
      return OrderStatus.delivered;
    }
    if (normalized.contains('معلق') || normalized.contains('انتظار') || normalized == 'pending') {
      return OrderStatus.pending;
    }
    if (normalized.contains('ملغ') || normalized == 'cancelled' || normalized == 'canceled') {
      return OrderStatus.cancelled;
    }

    return OrderStatus.unknown;
  }

  /// Whether status belongs to the Open Orders section.
  /// Open = confirmed | processing
  bool get isOpen =>
      this == OrderStatus.confirmed ||
      this == OrderStatus.processing;

  /// Whether status belongs to the Completed Orders section.
  /// Completed = shipped | delivered
  bool get isCompleted =>
      this == OrderStatus.shipped ||
      this == OrderStatus.delivered;

  /// Whether this order must be completely ignored/filtered out
  bool get isIgnored =>
      this == OrderStatus.pending ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.unknown;

  /// Visual theme color
  Color get color {
    switch (this) {
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      case OrderStatus.processing:
        return AppColors.statusProcessing;
      case OrderStatus.shipped:
        return AppColors.statusShipped;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
      case OrderStatus.pending:
      case OrderStatus.unknown:
        return AppColors.statusPending;
    }
  }

  /// Visual chip background color
  Color get backgroundColor => color.withValues(alpha: 0.12);
}
