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
  static const Color statusPendingBg = Color(0xFFF1F5F9);
  static const Color statusConfirmed = Color(0xFF0284C7); // Sky Blue
  static const Color statusConfirmedBg = Color(0xFFE0F2FE);
  static const Color statusProcessing = Color(0xFFD97706); // Amber
  static const Color statusProcessingBg = Color(0xFFFEF3C7);
  static const Color statusShipped = Color(0xFF7C3AED); // Purple / Indigo
  static const Color statusShippedBg = Color(0xFFF3E8FF);
  static const Color statusDelivered = Color(0xFF16A34A); // Emerald Green
  static const Color statusDeliveredBg = Color(0xFFDCFCE7);
  static const Color statusCancelled = Color(0xFFDC2626); // Red
  static const Color statusCancelledBg = Color(0xFFFEE2E2);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Utility & Component colors
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFEAB308);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFF92400E);
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color cardSelectedBorder = Color(0xFF3B82F6);

  // Figma Redesign Palette for Photos Screen
  static const Color redesignBackground = Color(0xFFF5F7FA);
  static const Color redesignPrimaryBlue = Color(0xFF2858C6);
  static const Color redesignMainText = Color(0xFF172438);
  static const Color redesignSecondaryText = Color(0xFF68768A);
  static const Color redesignSuccessGreen = Color(0xFF23785B);
  static const Color redesignCardBorder = Color(0xFFE5E9F0);
  static const Color redesignSegmentUnfilled = Color(0xFFE2E8F0);
  static const Color redesignBadgeBlueBg = Color(0xFFEDF3FC);
  static const Color redesignBadgeGreenBg = Color(0xFFEAF5EF);
  static const Color redesignEmptyBg = Color(0xFFF4F6FA);
  static const Color redesignAddTileBg = Color(0xFFEEF4FC);
  static const Color redesignDisabledBg = Color(0xFFE9EDF2);
  static const Color redesignDisabledText = Color(0xFF8D99AE);
}
