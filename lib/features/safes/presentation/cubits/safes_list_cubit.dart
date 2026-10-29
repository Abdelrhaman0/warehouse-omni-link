import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../data/safes_repository.dart';
import 'safes_state.dart';

/// Cubit responsible for fetching and refreshing the list of safes and their summary.
class SafesListCubit extends Cubit<SafesListState> {
  final SafesRepository safesRepository;

  SafesListCubit({required this.safesRepository})
      : super(const SafesListInitial());

  Future<void> loadSafes({bool isRefresh = false}) async {
    if (!isRefresh && state is! SafesListLoaded) {
      emit(const SafesListLoading());
    }

    try {
      final response = await safesRepository.getSafes();
      emit(SafesListLoaded(
        safes: response.safes,
        summary: response.summary,
      ));
    } on Failure catch (e) {
      if (!isRefresh || state is! SafesListLoaded) {
        emit(SafesListError(e.message));
      }
    } catch (_) {
      if (!isRefresh || state is! SafesListLoaded) {
        emit(const SafesListError('تعذر تحميل بيانات الخزن، يرجى المحاولة مرة أخرى.'));
      }
    }
  }

  Future<void> refreshSafes() async {
    await loadSafes(isRefresh: true);
  }
}
