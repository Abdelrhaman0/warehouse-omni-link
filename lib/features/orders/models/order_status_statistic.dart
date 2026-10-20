import 'package:equatable/equatable.dart';

/// Model representing an individual status count item from backend `meta.statistics`.
class OrderStatusStatistic extends Equatable {
  final String status;
  final String? statusText;
  final int count;
  final bool isValidCount;

  const OrderStatusStatistic({
    required this.status,
    this.statusText,
    required this.count,
    this.isValidCount = true,
  });

  factory OrderStatusStatistic.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? '';
    final statusText = json['status_text']?.toString();
    final dynamic rawCount = json['count'];
    final int? parsedCount;
    if (rawCount is int) {
      parsedCount = rawCount;
    } else if (rawCount is num) {
      parsedCount = rawCount.toInt();
    } else if (rawCount is String) {
      parsedCount = int.tryParse(rawCount);
    } else {
      parsedCount = null;
    }

    final isValid = parsedCount != null && parsedCount >= 0;

    return OrderStatusStatistic(
      status: status,
      statusText: statusText,
      count: isValid ? parsedCount : 0,
      isValidCount: isValid,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    if (statusText != null) 'status_text': statusText,
    'count': count,
  };

  @override
  List<Object?> get props => [status, statusText, count, isValidCount];
}
