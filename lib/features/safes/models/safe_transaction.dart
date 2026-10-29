import 'package:equatable/equatable.dart';
import 'safe.dart';

/// Represents a single financial transaction on a safe.
class SafeTransaction extends Equatable {
  final int id;
  final int safeId;
  final String type;
  final String? typeLabel;
  final bool isIncome;
  final double amount;
  final double fee;
  final double netAmount;
  final double balanceBefore;
  final double balanceAfter;
  final String? referenceType;
  final int? referenceId;
  final String? referenceNumber;
  final dynamic referenceSnapshot;
  final String? notes;
  final SafeCreator? performer;
  final String? createdAt;

  const SafeTransaction({
    required this.id,
    required this.safeId,
    required this.type,
    this.typeLabel,
    required this.isIncome,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.referenceNumber,
    this.referenceSnapshot,
    this.notes,
    this.performer,
    this.createdAt,
  });

  factory SafeTransaction.fromJson(Map<String, dynamic> json) {
    return SafeTransaction(
      id: _parseInt(json['id']),
      safeId: _parseInt(json['safe_id']),
      type: json['type']?.toString() ?? '',
      typeLabel: json['type_label']?.toString(),
      isIncome: json['is_income'] == true || json['is_income'] == 1,
      amount: _parseDouble(json['amount']),
      fee: _parseDouble(json['fee']),
      netAmount: _parseDouble(json['net_amount']),
      balanceBefore: _parseDouble(json['balance_before']),
      balanceAfter: _parseDouble(json['balance_after']),
      referenceType: json['reference_type']?.toString(),
      referenceId: json['reference_id'] is int
          ? json['reference_id'] as int
          : int.tryParse(json['reference_id']?.toString() ?? ''),
      referenceNumber: json['reference_number']?.toString(),
      referenceSnapshot: json['reference_snapshot'],
      notes: json['notes']?.toString(),
      performer: json['performer'] is Map<String, dynamic>
          ? SafeCreator.fromJson(json['performer'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at']?.toString(),
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
  List<Object?> get props => [id, safeId, type, amount, createdAt];
}

/// Pagination metadata for transaction listings.
class TransactionPagination extends Equatable {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final String? nextPageUrl;

  const TransactionPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.nextPageUrl,
  });

  bool get hasMorePages => currentPage < lastPage;

  factory TransactionPagination.fromMeta(Map<String, dynamic> meta) {
    return TransactionPagination(
      currentPage: meta['current_page'] is int ? meta['current_page'] as int : 1,
      lastPage: meta['last_page'] is int ? meta['last_page'] as int : 1,
      perPage: meta['per_page'] is int ? meta['per_page'] as int : 15,
      total: meta['total'] is int ? meta['total'] as int : 0,
      nextPageUrl: null,
    );
  }

  factory TransactionPagination.fromLinks(Map<String, dynamic> links, Map<String, dynamic> meta) {
    return TransactionPagination(
      currentPage: meta['current_page'] is int ? meta['current_page'] as int : 1,
      lastPage: meta['last_page'] is int ? meta['last_page'] as int : 1,
      perPage: meta['per_page'] is int ? meta['per_page'] as int : 15,
      total: meta['total'] is int ? meta['total'] as int : 0,
      nextPageUrl: links['next']?.toString(),
    );
  }

  @override
  List<Object?> get props => [currentPage, lastPage, perPage, total, nextPageUrl];
}
