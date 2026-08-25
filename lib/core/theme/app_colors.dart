import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base surfaces — matches the black background in your mockups
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceElevated = Color(0xFF242424);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textDisabled = Color(0xFF5A5A5A);

  // Primary action color (buttons, links)
  static const Color primary = Color(0xFFFFFFFF); // white buttons on black, per your login mockup
  static const Color onPrimary = Color(0xFF000000);

  // Accent colors for course tiles — pulled from the neon-ish mockup thumbnails
  static const Color accentPurple = Color(0xFF9B5DE5);
  static const Color accentBlue = Color(0xFF3A86FF);
  static const Color accentOrange = Color(0xFFFB8500);
  static const Color accentGreen = Color(0xFF06D6A0);
  static const Color accentPink = Color(0xFFEF476F);

  static const List<Color> accentPalette = [
    accentPurple,
    accentBlue,
    accentOrange,
    accentGreen,
    accentPink,
  ];

  // Semantic
  static const Color success = Color(0xFF06D6A0);
  static const Color error = Color(0xFFEF476F);
  static const Color warning = Color(0xFFFB8500);
  static const Color border = Color(0xFF2E2E2E);
}