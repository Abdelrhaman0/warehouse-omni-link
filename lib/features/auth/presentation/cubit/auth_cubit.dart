import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  StreamSubscription<void>? _sessionExpiredSubscription;

  AuthCubit({required this.authRepository})
      : super(const AuthInitial()) {
    _sessionExpiredSubscription = authRepository.sessionExpiredStream.listen((_) {
      handleUnauthorized();
    });
  }

  @override
  Future<void> close() {
    _sessionExpiredSubscription?.cancel();
    return super.close();
  }

  /// Check active session on app startup
  Future<void> checkAuthStatus() async {
    try {
      final user = await authRepository.checkAuthStatus();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  /// Login store keeper
  Future<void> login({
    required String login,
    required String password,
  }) async {
    if (login.trim().isEmpty || password.trim().isEmpty) {
      emit(const AuthFailure(AppStrings.fieldRequired));
      return;
    }

    emit(const AuthLoading(message: AppStrings.loggingIn));
    try {
      final user = await authRepository.login(login.trim(), password);
      emit(Authenticated(user));
    } on Failure catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(const AuthFailure(AppStrings.errorGeneric));
    }
  }

  /// Logout store keeper safely
  Future<void> logout() async {
    emit(const AuthLoading(message: AppStrings.loggingOut));
    try {
      await authRepository.logout();
    } finally {
      emit(const Unauthenticated());
    }
  }

  /// Triggered automatically when a 401 is intercepted on authenticated requests
  void handleUnauthorized() {
    if (state is SessionExpired) {
      return;
    }
    emit(const SessionExpired());
  }
}
