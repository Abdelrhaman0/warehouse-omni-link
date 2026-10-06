import 'package:equatable/equatable.dart';
import '../localization/app_strings.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure([String? message])
      : super(message ?? AppStrings.errorNetwork);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String? message])
      : super(message ?? AppStrings.errorUnauthorized);
}

class SessionExpiredFailure extends UnauthorizedFailure {
  const SessionExpiredFailure([String? message])
      : super(message ?? AppStrings.sessionExpiredMessage);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([String? message])
      : super(message ?? AppStrings.errorGeneric);
}
