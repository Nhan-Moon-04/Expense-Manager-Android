import 'package:flutter/material.dart';

class AppColors {
  // ─── Dark mode flag (updated by SettingsProvider) ───
  static bool _isDark = false;
  static void setDarkMode(bool value) => _isDark = value;
  static bool get isDark => _isDark;

  // Primary Colors - Professional Deep Blue
  static const Color primary = Color(0xFF2563EB); // Blue 600
  static const Color primaryLight = Color(0xFF3B82F6); // Blue 500
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue 700

  // Secondary Colors - Teal accent
  static const Color secondary = Color(0xFF14B8A6); // Teal
  static const Color secondaryLight = Color(0xFF5EEAD4);

  // Accent Colors - Warm Amber
  static const Color accent = Color(0xFFF59E0B); // Amber 500
  static const Color accentLight = Color(0xFFFBBF24); // Amber 400

  // ─── Theme-aware colors (auto-switch light/dark) ───

  // Background Colors
  static Color get background =>
      _isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
  static Color get surface => _isDark ? const Color(0xFF111827) : Colors.white;
  static Color get cardBackground =>
      _isDark ? const Color(0xFF1E293B) : Colors.white;
  static const Color scaffoldDark = Color(0xFF0B0F19); // legacy

  // Text Colors
  static Color get textPrimary =>
      _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textSecondary =>
      _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get textHint =>
      _isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
  static Color get textLight =>
      _isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

  // Divider / border color
  static Color get dividerColor =>
      _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

  // Input fill color
  static Color get inputFillColor =>
      _isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

  // Bottom nav / bottom sheet background
  static Color get bottomBarBackground =>
      _isDark ? const Color(0xFF111827) : Colors.white;

  // Status Colors (same in both themes)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFF43F5E); // Rose 500
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
  static const Color incomeColor = Color(0xFF10B981); // Emerald
  static const Color expenseColor = Color(0xFFF43F5E); // Rose

  // Gradient colors — Royal Indigo & Sapphire Blue (premium modern feel)
  static const List<Color> primaryGradient = [
    Color(0xFF1E1B4B),
    Color(0xFF312E81),
    Color(0xFF2563EB),
  ];

  static const List<Color> incomeGradient = [
    Color(0xFF059669),
    Color(0xFF10B981),
  ];

  static const List<Color> expenseGradient = [
    Color(0xFFE11D48),
    Color(0xFFF43F5E),
  ];

  // Card shadow color
  static Color get shadowColor => _isDark
      ? const Color(0xFF000000).withValues(alpha: 0.5)
      : const Color(0xFF0F172A).withValues(alpha: 0.08);

  // ─── New: Surface colors for glassmorphism / layering ───
  static Color get surfaceVariant =>
      _isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  static Color get borderColor =>
      _isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0);
}
