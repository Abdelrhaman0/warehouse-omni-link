import 'package:equatable/equatable.dart';
import '../../../auth/models/admin_user.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final AdminUser user;
  const ProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfileFailure extends ProfileState {
  final String message;
  const ProfileFailure(this.message);

  @override
  List<Object?> get props => [message];
}
