import 'package:equatable/equatable.dart';
import '../../models/safe.dart';
import '../../models/safe_summary.dart';
import '../../models/safe_transaction.dart';

/// States for the safes listing screen.
abstract class SafesListState extends Equatable {
  const SafesListState();
  @override
  List<Object?> get props => [];
}

class SafesListInitial extends SafesListState {
  const SafesListInitial();
}

class SafesListLoading extends SafesListState {
  const SafesListLoading();
}

class SafesListLoaded extends SafesListState {
  final List<Safe> safes;
  final SafeSummary? summary;

  const SafesListLoaded({required this.safes, this.summary});

  @override
  List<Object?> get props => [safes, summary];
}

class SafesListError extends SafesListState {
  final String message;
  const SafesListError(this.message);

  @override
  List<Object?> get props => [message];
}

/// States for the safe details screen.
abstract class SafeDetailsState extends Equatable {
  const SafeDetailsState();
  @override
  List<Object?> get props => [];
}

class SafeDetailsInitial extends SafeDetailsState {
  const SafeDetailsInitial();
}

class SafeDetailsLoading extends SafeDetailsState {
  const SafeDetailsLoading();
}

class SafeDetailsLoaded extends SafeDetailsState {
  final Safe safe;
  final List<SafeTransaction> transactions;
  final TransactionPagination? pagination;
  final bool isLoadingMoreTransactions;
  final String? paginationError;

  const SafeDetailsLoaded({
    required this.safe,
    required this.transactions,
    this.pagination,
    this.isLoadingMoreTransactions = false,
    this.paginationError,
  });

  SafeDetailsLoaded copyWith({
    Safe? safe,
    List<SafeTransaction>? transactions,
    TransactionPagination? pagination,
    bool? isLoadingMoreTransactions,
    String? paginationError,
  }) {
    return SafeDetailsLoaded(
      safe: safe ?? this.safe,
      transactions: transactions ?? this.transactions,
      pagination: pagination ?? this.pagination,
      isLoadingMoreTransactions: isLoadingMoreTransactions ?? this.isLoadingMoreTransactions,
      paginationError: paginationError,
    );
  }

  @override
  List<Object?> get props => [safe, transactions, pagination, isLoadingMoreTransactions, paginationError];
}

class SafeDetailsError extends SafeDetailsState {
  final String message;
  const SafeDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// States for financial operations (deposit, withdraw, transfer, create).
abstract class SafeOperationState extends Equatable {
  const SafeOperationState();
  @override
  List<Object?> get props => [];
}

class SafeOperationIdle extends SafeOperationState {
  const SafeOperationIdle();
}

class SafeOperationSubmitting extends SafeOperationState {
  const SafeOperationSubmitting();
}

class SafeOperationSuccess extends SafeOperationState {
  final String message;
  const SafeOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SafeOperationFailure extends SafeOperationState {
  final String message;
  final dynamic errors;
  const SafeOperationFailure(this.message, {this.errors});

  @override
  List<Object?> get props => [message, errors];
}

/// State for ambiguous network outcomes on financial operations.
class SafeOperationAmbiguous extends SafeOperationState {
  final String message;
  const SafeOperationAmbiguous(this.message);

  @override
  List<Object?> get props => [message];
}
