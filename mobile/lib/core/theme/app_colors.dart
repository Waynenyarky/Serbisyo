import 'package:flutter/material.dart';

/// Serbisyo brand and semantic colors.
abstract final class AppColors {
  // Primary — teal for CTAs and key actions
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0F766E);

  // Neutrals
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF171717);
  static const Color textSecondary = Color(0xFF737373);
  static const Color textTertiary = Color(0xFFA3A3A3);
  static const Color divider = Color(0xFFE5E5E5);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Category / accent
  static const Color accentCoral = Color(0xFFF97316);
}
