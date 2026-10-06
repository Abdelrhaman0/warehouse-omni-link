import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../auth/data/auth_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final AuthRepository authRepository;

  ProfileCubit({required this.authRepository})
      : super(const ProfileInitial());

  Future<void> loadProfile() async {
    emit(const ProfileLoading());
    try {
      final user = await authRepository.getProfile();
      emit(ProfileLoaded(user));
    } on Failure catch (e) {
      emit(ProfileFailure(e.message));
    } catch (_) {
      emit(const ProfileFailure(AppStrings.errorProfileLoad));
    }
  }
}
