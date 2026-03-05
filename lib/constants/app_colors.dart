import 'package:flutter/material.dart';

class AppColors {
  // ─── Dark mode flag (updated by SettingsProvider) ───
  static bool _isDark = false;
  static void setDarkMode(bool value) => _isDark = value;
  static bool get isDark => _isDark;

  // Primary Colors - Modern Deep Blue/Purple Gradient
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8); // Light Indigo
  static const Color primaryDark = Color(0xFF4F46E5); // Dark Indigo

  // Secondary Colors - Teal accent
  static const Color secondary = Color(0xFF14B8A6); // Teal
  static const Color secondaryLight = Color(0xFF5EEAD4);

  // Accent Colors - Vibrant Orange
  static const Color accent = Color(0xFFF97316);
  static const Color accentLight = Color(0xFFFB923C);

  // ─── Theme-aware colors (auto-switch light/dark) ───

  // Background Colors
  static Color get background =>
      _isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8FAFC);
  static Color get surface => _isDark ? const Color(0xFF1E1E2E) : Colors.white;
  static Color get cardBackground =>
      _isDark ? const Color(0xFF1E1E2E) : Colors.white;
  static const Color scaffoldDark = Color(0xFF0F172A); // legacy

  // Text Colors
  static Color get textPrimary =>
      _isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
  static Color get textSecondary =>
      _isDark ? const Color(0xFFA0AEC0) : const Color(0xFF64748B);
  static Color get textHint =>
      _isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);
  static Color get textLight =>
      _isDark ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0);

  // Divider / border color
  static Color get dividerColor =>
      _isDark ? const Color(0xFF2D2D44) : const Color(0xFFE2E8F0);

  // Input fill color
  static Color get inputFillColor =>
      _isDark ? const Color(0xFF2A2A3E) : Colors.white;

  // Bottom nav / bottom sheet background
  static Color get bottomBarBackground =>
      _isDark ? const Color(0xFF1E1E2E) : Colors.white;

  // Status Colors (same in both themes)
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // Expense Category Colors - Vibrant modern palette
  static const Color foodColor = Color(0xFFF43F5E); // Rose
  static const Color transportColor = Color(0xFF6366F1); // Indigo
  static const Color shoppingColor = Color(0xFFA855F7); // Purple
  static const Color entertainmentColor = Color(0xFFF97316); // Orange
  static const Color billsColor = Color(0xFF64748B); // Slate
  static const Color healthColor = Color(0xFF14B8A6); // Teal
  static const Color educationColor = Color(0xFF8B5CF6); // Violet
  static const Color otherColor = Color(0xFF94A3B8); // Grey

  // Income/Expense Colors
  static const Color incomeColor = Color(0xFF22C55E); // Green
  static const Color expenseColor = Color(0xFFEF4444); // Red

  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];

  static const List<Color> incomeGradient = [
    Color(0xFF22C55E),
    Color(0xFF14B8A6),
  ];

  static const List<Color> expenseGradient = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
  ];

  // Card shadow color
  static Color get shadowColor => _isDark
      ? const Color(0xFF000000).withValues(alpha: 0.3)
      : const Color(0xFF6366F1).withValues(alpha: 0.08);
}
