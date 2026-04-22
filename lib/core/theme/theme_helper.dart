import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Extension on BuildContext for easy theme-aware color access.
/// Use these instead of hardcoded Colors.white / Color(0xFF...) in screens.
extension ThemeHelper on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Backgrounds
  Color get bgColor => isDark ? const Color(0xFF121212) : AppColors.bgColor;
  Color get cardColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get surfaceColor =>
      isDark ? const Color(0xFF252525) : const Color(0xFFF5F7FA);
  Color get inputFillColor => isDark ? const Color(0xFF2C2C2C) : Colors.white;

  // Text
  Color get textPrimary => isDark ? Colors.white : AppColors.textDark;
  Color get textSecondary => isDark ? Colors.white60 : AppColors.textLight;
  Color get textHint => isDark ? Colors.white38 : Colors.grey.shade400;

  // Borders & dividers
  Color get dividerColor =>
      isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;
  Color get borderColor => isDark
      ? AppColors.primaryGreen.withValues(alpha: 0.3)
      : AppColors.primaryGreen.withValues(alpha: 0.2);

  // Shadows
  Color get shadowColor => isDark
      ? Colors.black.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.06);

  // Icon tint
  Color get iconColor => isDark ? Colors.white70 : AppColors.textLight;

  // Disabled / locked field
  Color get lockedFieldColor =>
      isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100;
}
