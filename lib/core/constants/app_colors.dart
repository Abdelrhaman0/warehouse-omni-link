import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary logistics brand palette
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy / Indigo
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF172554);
  static const Color accent = Color(0xFFF59E0B); // Industrial Amber / Warning
  static const Color accentDark = Color(0xFFD97706);

  // Surface & Backgrounds
  static const Color background = Color(0xFFF8FAFC); // Clean light slate
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Status colors
  static const Color statusPending = Color(0xFF64748B); // Slate
  static const Color statusConfirmed = Color(0xFF0284C7); // Sky Blue
  static const Color statusProcessing = Color(0xFFD97706); // Amber
  static const Color statusShipped = Color(0xFF7C3AED); // Purple / Indigo
  static const Color statusDelivered = Color(0xFF16A34A); // Emerald Green
  static const Color statusCancelled = Color(0xFFDC2626); // Red

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Utility colors
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFEAB308);
  static const Color info = Color(0xFF2563EB);
  static const Color divider = Color(0xFFE2E8F0);
}
