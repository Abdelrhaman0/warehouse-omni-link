import 'package:equatable/equatable.dart';

/// Summary statistics for all safes returned by the listing endpoint.
class SafeSummary extends Equatable {
  final int totalSafes;
  final int activeSafes;
  final double totalBalance;

  const SafeSummary({
    required this.totalSafes,
    required this.activeSafes,
    required this.totalBalance,
  });

  factory SafeSummary.fromJson(Map<String, dynamic> json) {
    return SafeSummary(
      totalSafes: _parseInt(json['total_safes']),
      activeSafes: _parseInt(json['active_safes']),
      totalBalance: _parseDouble(json['total_balance']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  List<Object?> get props => [totalSafes, activeSafes, totalBalance];
}
