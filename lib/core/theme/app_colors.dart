import 'package:flutter/material.dart';

/// Centralized color palette for the app.
/// Never hardcode a Color(...) value in a screen or widget — add it here instead.
/// This is what makes dark mode / rebranding a one-file change later.
class AppColors {
  AppColors._(); // prevents instantiation

  // Brand
  static const Color primary = Color(0xFF4361EE);
  static const Color primaryDark = Color(0xFF3247C7);
  static const Color secondary = Color(0xFF3CCFCF);

  // Status
  static const Color online = Color(0xFF2ECC71);
  static const Color offline = Color(0xFF9CA3AF);
  static const Color error = Color(0xFFE63946);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF4A261);

  // Call actions
  static const Color callAccept = Color(0xFF2ECC71);
  static const Color callDecline = Color(0xFFE63946);
  static const Color callEnd = Color(0xFFE63946);
  static const Color callControlActive = Color(0xFF4361EE);
  static const Color callControlInactive = Color(0xFF3A3A3C);

  // Light theme neutrals
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1B25);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  // Dark theme neutrals
  static const Color backgroundDark = Color(0xFF121214);
  static const Color surfaceDark = Color(0xFF1E1E22);
  static const Color textPrimaryDark = Color(0xFFF2F2F7);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color dividerDark = Color(0xFF2C2C2E);
}
