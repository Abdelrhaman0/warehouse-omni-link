import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../data/safes_repository.dart';
import 'safes_state.dart';

/// Cubit responsible for safe details and paginated transaction history.
class SafeDetailsCubit extends Cubit<SafeDetailsState> {
  final SafesRepository safesRepository;
  int? _currentSafeId;

  SafeDetailsCubit({required this.safesRepository})
      : super(const SafeDetailsInitial());

  int? get currentSafeId => _currentSafeId;

  Future<void> loadSafeDetails(int safeId) async {
    _currentSafeId = safeId;
    emit(const SafeDetailsLoading());

    try {
      final response = await safesRepository.getSafeDetails(safeId, page: 1);
      if (response.safe == null) {
        emit(const SafeDetailsError('بيانات الخزنة غير موجودة'));
        return;
      }

      emit(SafeDetailsLoaded(
        safe: response.safe!,
        transactions: response.transactions,
        pagination: response.pagination,
      ));
    } on Failure catch (e) {
      emit(SafeDetailsError(e.message));
    } catch (_) {
      emit(const SafeDetailsError('تعذر تحميل تفاصيل الخزنة، يرجى المحاولة لاحقاً.'));
    }
  }

  Future<void> refreshSafeDetails() async {
    final safeId = _currentSafeId;
    if (safeId == null) return;

    try {
      final response = await safesRepository.getSafeDetails(safeId, page: 1);
      if (response.safe != null) {
        emit(SafeDetailsLoaded(
          safe: response.safe!,
          transactions: response.transactions,
          pagination: response.pagination,
        ));
      }
    } on Failure catch (e) {
      if (state is! SafeDetailsLoaded) {
        emit(SafeDetailsError(e.message));
      }
    } catch (_) {
      // Keep loaded state if already loaded
    }
  }

  Future<void> loadMoreTransactions() async {
    final currentState = state;
    if (currentState is! SafeDetailsLoaded) return;
    if (currentState.isLoadingMoreTransactions) return;

    final pagination = currentState.pagination;
    if (pagination == null || !pagination.hasMorePages) return;

    final safeId = _currentSafeId;
    if (safeId == null) return;

    emit(currentState.copyWith(isLoadingMoreTransactions: true, paginationError: null));

    try {
      final nextPage = pagination.currentPage + 1;
      final response = await safesRepository.getSafeDetails(safeId, page: nextPage);

      final updatedTransactions = List.of(currentState.transactions)
        ..addAll(response.transactions);

      emit(SafeDetailsLoaded(
        safe: response.safe ?? currentState.safe,
        transactions: updatedTransactions,
        pagination: response.pagination ?? pagination,
        isLoadingMoreTransactions: false,
      ));
    } on Failure catch (e) {
      emit(currentState.copyWith(
        isLoadingMoreTransactions: false,
        paginationError: e.message,
      ));
    } catch (_) {
      emit(currentState.copyWith(
        isLoadingMoreTransactions: false,
        paginationError: 'تعذر تحميل المزيد من العمليات.',
      ));
    }
  }
}
