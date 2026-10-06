import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/models/admin_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../../../../core/network/authenticated_cache_manager.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.logoutConfirmTitle),
        content: const Text(AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthCubit>().logout();
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      child: BlocProvider(
        create: (context) => ProfileCubit(
          authRepository: context.read<AuthRepository>(),
        )..loadProfile(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.profile),
          ),
          body: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('جارٍ تحميل الملف الشخصي...'),
                    ],
                  ),
                );
              }

              if (state is ProfileFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.read<ProfileCubit>().loadProfile(),
                          icon: const Icon(Icons.refresh),
                          label: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is ProfileLoaded) {
                final user = state.user;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Avatar & Name Card
                      _buildHeaderCard(user),
                      const SizedBox(height: 20),

                      // User Details Card
                      _buildDetailsCard(user),
                      const SizedBox(height: 32),

                      // Logout button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error, width: 1.5),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => _confirmLogout(context),
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text(
                          AppStrings.logout,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(AdminUser user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            // Avatar
            ClipOval(
              child: Container(
                width: 80,
                height: 80,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: user.avatar != null && user.avatar!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: user.avatar!,
                  cacheManager: AuthenticatedCacheManager.instance,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 44,
                        color: AppColors.primary,
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (user.role != null && user.role!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.role!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(AdminUser user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileRow(
              icon: Icons.email_outlined,
              label: AppStrings.workerEmail,
              value: user.email,
            ),
            if (user.phone != null && user.phone!.isNotEmpty) ...[
              const Divider(height: 20, color: AppColors.divider),
              _buildProfileRow(
                icon: Icons.phone_outlined,
                label: AppStrings.workerPhone,
                value: user.phone!,
              ),
            ],
            if (user.status != null && user.status!.isNotEmpty) ...[
              const Divider(height: 20, color: AppColors.divider),
              _buildProfileRow(
                icon: Icons.verified_user_outlined,
                label: AppStrings.workerStatus,
                value: user.status!,
              ),
            ],
            if (user.gender != null && user.gender!.isNotEmpty) ...[
              const Divider(height: 20, color: AppColors.divider),
              _buildProfileRow(
                icon: Icons.people_outline,
                label: AppStrings.workerGender,
                value: user.gender!,
              ),
            ],
            if (user.createdAt != null && user.createdAt!.isNotEmpty) ...[
              const Divider(height: 20, color: AppColors.divider),
              _buildProfileRow(
                icon: Icons.calendar_today_outlined,
                label: AppStrings.workerCreatedAt,
                value: user.createdAt!.split(' ').first,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: AppColors.textMuted),
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
