import 'package:flutter/material.dart';

class AppColors {
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

  // Background Colors - Clean modern grey
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;
  static const Color scaffoldDark = Color(0xFF0F172A); // Dark mode scaffold

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textHint = Color(0xFF94A3B8); // Slate 400
  static const Color textLight = Color(0xFFE2E8F0); // Slate 200

  // Status Colors
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
  static Color shadowColor = const Color(0xFF6366F1).withValues(alpha: 0.08);
}
