import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../data/safes_repository.dart';
import 'safes_state.dart';

/// Cubit responsible for performing financial mutations (create, deposit, withdraw, transfer).
/// Includes double-submission protection and network ambiguity handling.
class SafeOperationCubit extends Cubit<SafeOperationState> {
  final SafesRepository safesRepository;
  bool _isSubmitting = false;

  SafeOperationCubit({required this.safesRepository})
      : super(const SafeOperationIdle());

  void reset() {
    _isSubmitting = false;
    emit(const SafeOperationIdle());
  }

  Future<bool> createSafe({
    required String name,
    String? nameAr,
    String? nameEn,
    required String type,
    String? accountNumber,
    double? initialBalance,
    String? notes,
  }) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    emit(const SafeOperationSubmitting());

    try {
      final body = <String, dynamic>{
        'name': name.trim(),
        'type': type,
      };
      if (nameAr != null && nameAr.trim().isNotEmpty) {
        body['name_ar'] = nameAr.trim();
      }
      if (nameEn != null && nameEn.trim().isNotEmpty) {
        body['name_en'] = nameEn.trim();
      }
      if (accountNumber != null && accountNumber.trim().isNotEmpty) {
        body['account_number'] = accountNumber.trim();
      }
      if (initialBalance != null && initialBalance > 0) {
        body['initial_balance'] = initialBalance;
      }
      if (notes != null && notes.trim().isNotEmpty) {
        body['notes'] = notes.trim();
      }

      final response = await safesRepository.createSafe(body);
      emit(SafeOperationSuccess(response.message.isNotEmpty
          ? response.message
          : 'تم إنشاء الخزنة بنجاح'));
      return true;
    } on NetworkFailure catch (e) {
      emit(SafeOperationAmbiguous(
        'انقطع الاتصال بالشبكة أثناء إنشاء الخزنة. يرجى مراجعة قائمة الخزن للتأكد قبل إعادة المحاولة. (${e.message})',
      ));
      return false;
    } on Failure catch (e) {
      emit(SafeOperationFailure(e.message));
      return false;
    } catch (_) {
      emit(const SafeOperationFailure('حدث خطأ غير متوقع أثناء إنشاء الخزنة.'));
      return false;
    } finally {
      _isSubmitting = false;
    }
  }

  Future<bool> deposit({
    required int safeId,
    required double amount,
    String? notes,
    String? referenceNumber,
  }) async {
    if (_isSubmitting) return false;
    if (amount <= 0) {
      emit(const SafeOperationFailure('يجب أن يكون مبلغ الإيداع أكبر من صفر.'));
      return false;
    }

    _isSubmitting = true;
    emit(const SafeOperationSubmitting());

    try {
      final body = <String, dynamic>{
        'amount': amount,
      };
      if (notes != null && notes.trim().isNotEmpty) {
        body['notes'] = notes.trim();
      }
      if (referenceNumber != null && referenceNumber.trim().isNotEmpty) {
        body['reference_number'] = referenceNumber.trim();
      }

      final response = await safesRepository.deposit(safeId, body);
      emit(SafeOperationSuccess(response.message.isNotEmpty
          ? response.message
          : 'تم إيداع المبلغ بنجاح'));
      return true;
    } on NetworkFailure catch (e) {
      emit(SafeOperationAmbiguous(
        'حدث انقطاع بالشبكة أثناء عملية الإيداع. يرجى التحقق من رصيد وسجل الخزنة قبل إعادة المحاولة تجنباً للتكرار. (${e.message})',
      ));
      return false;
    } on Failure catch (e) {
      emit(SafeOperationFailure(e.message));
      return false;
    } catch (_) {
      emit(const SafeOperationFailure('حدث خطأ غير متوقع أثناء عملية الإيداع.'));
      return false;
    } finally {
      _isSubmitting = false;
    }
  }

  Future<bool> withdraw({
    required int safeId,
    required double amount,
    String? notes,
    String? referenceNumber,
  }) async {
    if (_isSubmitting) return false;
    if (amount <= 0) {
      emit(const SafeOperationFailure('يجب أن يكون مبلغ السحب أكبر من صفر.'));
      return false;
    }

    _isSubmitting = true;
    emit(const SafeOperationSubmitting());

    try {
      final body = <String, dynamic>{
        'amount': amount,
      };
      if (notes != null && notes.trim().isNotEmpty) {
        body['notes'] = notes.trim();
      }
      if (referenceNumber != null && referenceNumber.trim().isNotEmpty) {
        body['reference_number'] = referenceNumber.trim();
      }

      final response = await safesRepository.withdraw(safeId, body);
      emit(SafeOperationSuccess(response.message.isNotEmpty
          ? response.message
          : 'تم سحب المبلغ بنجاح'));
      return true;
    } on NetworkFailure catch (e) {
      emit(SafeOperationAmbiguous(
        'حدث انقطاع بالشبكة أثناء عملية السحب. يرجى مراجعة الرصيد وسجل العمليات قبل إعادة المحاولة تجنباً للتكرار. (${e.message})',
      ));
      return false;
    } on Failure catch (e) {
      emit(SafeOperationFailure(e.message));
      return false;
    } catch (_) {
      emit(const SafeOperationFailure('حدث خطأ غير متوقع أثناء عملية السحب.'));
      return false;
    } finally {
      _isSubmitting = false;
    }
  }

  Future<bool> transfer({
    required int fromSafeId,
    required int toSafeId,
    required double amount,
    String? notes,
  }) async {
    if (_isSubmitting) return false;
    if (fromSafeId == toSafeId) {
      emit(const SafeOperationFailure('لا يمكن التحويل إلى نفس الخزنة.'));
      return false;
    }
    if (amount <= 0) {
      emit(const SafeOperationFailure('يجب أن يكون مبلغ التحويل أكبر من صفر.'));
      return false;
    }

    _isSubmitting = true;
    emit(const SafeOperationSubmitting());

    try {
      final body = <String, dynamic>{
        'from_safe_id': fromSafeId,
        'to_safe_id': toSafeId,
        'amount': amount,
      };
      if (notes != null && notes.trim().isNotEmpty) {
        body['notes'] = notes.trim();
      }

      final response = await safesRepository.transfer(body);
      emit(SafeOperationSuccess(response.message.isNotEmpty
          ? response.message
          : 'تم التحويل بنجاح'));
      return true;
    } on NetworkFailure catch (e) {
      emit(SafeOperationAmbiguous(
        'حدث انقطاع بالاتصال أثناء التحويل. يرجى فحص أرصدة الخزنتين قبل إعادة المحاولة للتأكد من عدم تكرار الخصم. (${e.message})',
      ));
      return false;
    } on Failure catch (e) {
      emit(SafeOperationFailure(e.message));
      return false;
    } catch (_) {
      emit(const SafeOperationFailure('حدث خطأ غير متوقع أثناء عملية التحويل.'));
      return false;
    } finally {
      _isSubmitting = false;
    }
  }
}
