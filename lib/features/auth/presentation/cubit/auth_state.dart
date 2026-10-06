import 'package:equatable/equatable.dart';
import '../../models/admin_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class Authenticated extends AuthState {
  final AdminUser user;
  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class SessionExpired extends AuthState {
  final String message;
  const SessionExpired([this.message = 'انتهت صلاحية جلسة تسجيل الدخول الخاصة بك. يرجى تسجيل الدخول مرة أخرى للمتابعة.']);

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
