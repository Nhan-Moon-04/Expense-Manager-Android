import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// ═══════════════════════════════════════════════════════════
// SPACING – 4px base grid
// ═══════════════════════════════════════════════════════════
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Padding presets for common containers
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(14);
  static const EdgeInsets sectionGap = EdgeInsets.only(bottom: 20);
}

// ═══════════════════════════════════════════════════════════
// BORDER RADIUS
// ═══════════════════════════════════════════════════════════
class AppRadius {
  AppRadius._();

  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double card = 18;
  static const double pill = 100;

  static BorderRadius get smBorder => BorderRadius.circular(sm);
  static BorderRadius get mdBorder => BorderRadius.circular(md);
  static BorderRadius get lgBorder => BorderRadius.circular(lg);
  static BorderRadius get xlBorder => BorderRadius.circular(xl);
  static BorderRadius get cardBorder => BorderRadius.circular(card);
  static BorderRadius get pillBorder => BorderRadius.circular(pill);
}

// ═══════════════════════════════════════════════════════════
// TYPOGRAPHY – Inter font, 8 levels
// ═══════════════════════════════════════════════════════════
class AppTypography {
  AppTypography._();

  // ─── Headings ───
  /// Page title, biggest text (28px, w800)
  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  /// Section title (22px, w700)
  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  /// Subsection / Card header (17px, w700)
  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  // ─── Body text ───
  /// Primary body text (15px, w500)
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  /// Default body text (14px, w500)
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  /// Secondary body text (13px, w500)
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // ─── Captions & Labels ───
  /// Smallest readable text (11px, w500)
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// Tiny labels, badges (9px, w600)
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w600,
      );

  // ─── Amount / Financial numbers ───
  /// Default financial amount / alias to amountHero (36px, w800)
  static TextStyle get amount => amountHero;

  /// Hero balance amount (36px, w800)
  static TextStyle get amountHero => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.1,
        color: Colors.white,
      );

  /// Large amount on cards (30px, w800)
  static TextStyle get amountLarge => GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.1,
        color: Colors.white,
      );

  /// Inline amounts in lists (14px, w700)
  static TextStyle get amountSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      );

  /// Compact amounts in pills/badges (11px, w700)
  static TextStyle get amountTiny => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      );

  // ─── Navigation ───
  static TextStyle get navLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      );

  static TextStyle get navLabelActive => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      );

  // ─── Buttons ───
  static TextStyle get buttonPrimary => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  static TextStyle get buttonSecondary => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  // ─── Transaction list ───
  static TextStyle get transactionTitle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get transactionSubtitle => GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  static TextStyle get transactionTime => GoogleFonts.inter(
        fontSize: 11,
        color: AppColors.textHint,
      );

  /// Day group header in transaction list
  static TextStyle get dayHeader => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  static TextStyle get daySummary => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );
}

// ═══════════════════════════════════════════════════════════
// SHADOWS
// ═══════════════════════════════════════════════════════════
class AppShadows {
  AppShadows._();

  /// Subtle card shadow
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.shadowColor,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Elevated card (dialogs, modals)
  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Minimal shadow for subtle depth
  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  /// Bottom bar / appbar shadow
  static List<BoxShadow> get bar => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, -4),
        ),
      ];

  /// Colored glow for FAB / CTA
  static List<BoxShadow> primaryGlow(double alpha) => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: alpha),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> colorGlow(Color color, {double alpha = 0.3}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

// ═══════════════════════════════════════════════════════════
// EXTRA COLOR TOKENS (complements AppColors)
// ═══════════════════════════════════════════════════════════
class AppColorTokens {
  AppColorTokens._();

  /// Transfer between wallets
  static const Color transfer = Color(0xFF6366F1); // Indigo
  static const List<Color> transferGradient = [
    Color(0xFF4F46E5),
    Color(0xFF6366F1),
  ];

  /// Pending confirmation (auto-expense awaiting review)
  static const Color pending = Color(0xFFF59E0B); // Amber
  static const Color pendingLight = Color(0xFFFBBF24);

  /// Voice input accent
  static const Color voice = Color(0xFF8B5CF6); // Violet
  static const List<Color> voiceGradient = [
    Color(0xFF7C3AED),
    Color(0xFF8B5CF6),
  ];
}

// ═══════════════════════════════════════════════════════════
// ANIMATION DURATIONS
// ═══════════════════════════════════════════════════════════
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration page = Duration(milliseconds: 600);
  static const Duration splash = Duration(milliseconds: 800);
}
