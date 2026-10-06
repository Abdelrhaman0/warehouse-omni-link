import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';

/// Modal dialog shown when the authenticated session expires (HTTP 401).
/// Un-dismissible to prevent accessing protected screens until the user logs in again.
class SessionExpiredDialog extends StatelessWidget {
  final VoidCallback onLoginPressed;

  const SessionExpiredDialog({
    super.key,
    required this.onLoginPressed,
  });

  static bool _isShowing = false;
  static bool get isShowing => _isShowing;

  /// Safely shows the session expired dialog if not already visible.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onLoginPressed,
  }) async {
    if (_isShowing) return;
    _isShowing = true;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: SessionExpiredDialog(
            onLoginPressed: () {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              onLoginPressed();
            },
          ),
        ),
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_off_outlined,
              size: 48,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            AppStrings.sessionExpiredTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            AppStrings.sessionExpiredMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onLoginPressed,
              child: const Text(
                AppStrings.sessionExpiredButton,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
