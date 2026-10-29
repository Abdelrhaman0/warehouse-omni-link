import 'safe.dart';
import 'safe_summary.dart';
import 'safe_transaction.dart';

/// Response model for the safes listing endpoint (GET /safes).
class SafeListResponse {
  final bool status;
  final String message;
  final List<Safe> safes;
  final SafeSummary? summary;

  const SafeListResponse({
    required this.status,
    required this.message,
    required this.safes,
    this.summary,
  });

  factory SafeListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<Safe> parsedSafes = [];
    SafeSummary? parsedSummary;

    if (data is Map<String, dynamic>) {
      // data.safes or data.data contain the safes list
      final safesRaw = data['safes'] ?? data['data'];
      if (safesRaw is List) {
        parsedSafes = safesRaw
            .whereType<Map<String, dynamic>>()
            .map(Safe.fromJson)
            .toList();
      }
      // data.summary
      if (data['summary'] is Map<String, dynamic>) {
        parsedSummary = SafeSummary.fromJson(data['summary'] as Map<String, dynamic>);
      }
    } else if (data is List) {
      parsedSafes = data
          .whereType<Map<String, dynamic>>()
          .map(Safe.fromJson)
          .toList();
      if (json['summary'] is Map<String, dynamic>) {
        parsedSummary = SafeSummary.fromJson(json['summary'] as Map<String, dynamic>);
      }
    }

    return SafeListResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      safes: parsedSafes,
      summary: parsedSummary,
    );
  }
}

/// Response model for the safe details endpoint (GET /safes/{id}).
class SafeDetailsResponse {
  final bool status;
  final String message;
  final Safe? safe;
  final List<SafeTransaction> transactions;
  final TransactionPagination? pagination;

  const SafeDetailsResponse({
    required this.status,
    required this.message,
    this.safe,
    required this.transactions,
    this.pagination,
  });

  factory SafeDetailsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    Safe? parsedSafe;
    List<SafeTransaction> parsedTransactions = [];
    TransactionPagination? parsedPagination;

    if (data != null) {
      // The API may return the safe nested under `data.safe` or flatten its
      // fields directly into `data` (older response shape).
      final safeData = data['safe'];
      if (safeData is Map<String, dynamic>) {
        parsedSafe = Safe.fromJson(safeData);
      } else if (data.containsKey('id')) {
        parsedSafe = Safe.fromJson(data);
      }

      // Parse transactions nested under data.transactions.data
      final transactionsWrapper = data['transactions'];
      if (transactionsWrapper is Map<String, dynamic>) {
        final txData = transactionsWrapper['data'];
        if (txData is List) {
          parsedTransactions = txData
              .whereType<Map<String, dynamic>>()
              .map(SafeTransaction.fromJson)
              .toList();
        }

        // Parse pagination from meta and links
        final meta = transactionsWrapper['meta'];
        final links = transactionsWrapper['links'];
        if (meta is Map<String, dynamic>) {
          if (links is Map<String, dynamic>) {
            parsedPagination = TransactionPagination.fromLinks(links, meta);
          } else {
            parsedPagination = TransactionPagination.fromMeta(meta);
          }
        }
      }
    }

    return SafeDetailsResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      safe: parsedSafe,
      transactions: parsedTransactions,
      pagination: parsedPagination,
    );
  }
}

/// Response model for deposit, withdrawal, and create-safe operations.
class SafeOperationResponse {
  final bool status;
  final String message;
  final SafeTransaction? transaction;
  final Safe? safe;
  final dynamic errors;

  const SafeOperationResponse({
    required this.status,
    required this.message,
    this.transaction,
    this.safe,
    this.errors,
  });

  factory SafeOperationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    SafeTransaction? parsedTransaction;
    Safe? parsedSafe;

    if (data != null) {
      if (data['transaction'] is Map<String, dynamic>) {
        parsedTransaction = SafeTransaction.fromJson(
          data['transaction'] as Map<String, dynamic>,
        );
      }
      if (data['safe'] is Map<String, dynamic>) {
        parsedSafe = Safe.fromJson(data['safe'] as Map<String, dynamic>);
      }
      // For create-safe, the safe might be directly in `data`
      if (parsedSafe == null && data.containsKey('id')) {
        parsedSafe = Safe.fromJson(data);
      }
    }

    return SafeOperationResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      transaction: parsedTransaction,
      safe: parsedSafe,
      errors: json['errors'],
    );
  }
}

/// Response model for the transfer endpoint.
class TransferResponse {
  final bool status;
  final String message;
  final int? id;
  final String? transferNumber;
  final Safe? fromSafe;
  final Safe? toSafe;
  final double? amount;
  final double? fee;
  final double? netAmount;
  final String? transferStatus;
  final String? statusLabel;
  final String? notes;
  final SafeCreator? creator;
  final String? createdAt;
  final dynamic errors;

  const TransferResponse({
    required this.status,
    required this.message,
    this.id,
    this.transferNumber,
    this.fromSafe,
    this.toSafe,
    this.amount,
    this.fee,
    this.netAmount,
    this.transferStatus,
    this.statusLabel,
    this.notes,
    this.creator,
    this.createdAt,
    this.errors,
  });

  factory TransferResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    Safe? fromSafe;
    Safe? toSafe;
    SafeCreator? creator;

    if (data != null) {
      if (data['from_safe'] is Map<String, dynamic>) {
        fromSafe = Safe.fromJson(data['from_safe'] as Map<String, dynamic>);
      }
      if (data['to_safe'] is Map<String, dynamic>) {
        toSafe = Safe.fromJson(data['to_safe'] as Map<String, dynamic>);
      }
      if (data['creator'] is Map<String, dynamic>) {
        creator = SafeCreator.fromJson(data['creator'] as Map<String, dynamic>);
      }
    }

    double? parseNullableDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return TransferResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      id: data?['id'] is int ? data!['id'] as int : null,
      transferNumber: data?['transfer_number']?.toString(),
      fromSafe: fromSafe,
      toSafe: toSafe,
      amount: parseNullableDouble(data?['amount']),
      fee: parseNullableDouble(data?['fee']),
      netAmount: parseNullableDouble(data?['net_amount']),
      transferStatus: data?['status']?.toString(),
      statusLabel: data?['status_label']?.toString(),
      notes: data?['notes']?.toString(),
      creator: creator,
      createdAt: data?['created_at']?.toString(),
      errors: json['errors'],
    );
  }
}
