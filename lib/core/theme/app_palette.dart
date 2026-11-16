import 'package:flutter/material.dart';

/// One complete colour set. Every theme in the app is an AppPalette.
class AppPalette {
  final String id;
  final String name;
  final String description;
  final Brightness brightness;

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;

  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  final Color primary; // main buttons
  final Color onPrimary;

  final Color accentPurple;
  final Color accentBlue;
  final Color accentOrange;
  final Color accentGreen;
  final Color accentPink;

  final Color success;
  final Color error;
  final Color warning;

  const AppPalette({
    required this.id,
    required this.name,
    required this.description,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.primary,
    required this.onPrimary,
    required this.accentPurple,
    required this.accentBlue,
    required this.accentOrange,
    required this.accentGreen,
    required this.accentPink,
    required this.success,
    required this.error,
    required this.warning,
  });

  List<Color> get accentPalette => [accentPurple, accentBlue, accentOrange, accentGreen, accentPink];

  bool get isDark => brightness == Brightness.dark;
}

/// The themes a student can pick from. The first one is the original Study Sensei look.
class AppPalettes {
  AppPalettes._();

  static const midnight = AppPalette(
    id: 'midnight',
    name: 'Midnight',
    description: 'The classic black Study Sensei look.',
    brightness: Brightness.dark,
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF1A1A1A),
    surfaceElevated: Color(0xFF242424),
    border: Color(0xFF2E2E2E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA0A0A0),
    textDisabled: Color(0xFF5A5A5A),
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    accentPurple: Color(0xFF9B5DE5),
    accentBlue: Color(0xFF3A86FF),
    accentOrange: Color(0xFFFB8500),
    accentGreen: Color(0xFF06D6A0),
    accentPink: Color(0xFFEF476F),
    success: Color(0xFF06D6A0),
    error: Color(0xFFEF476F),
    warning: Color(0xFFFB8500),
  );

  static const ocean = AppPalette(
    id: 'ocean',
    name: 'Ocean',
    description: 'Deep navy with teal and sky-blue accents.',
    brightness: Brightness.dark,
    background: Color(0xFF0B1220),
    surface: Color(0xFF131C2E),
    surfaceElevated: Color(0xFF1C2740),
    border: Color(0xFF26324D),
    textPrimary: Color(0xFFEAF2FF),
    textSecondary: Color(0xFF8FA3C7),
    textDisabled: Color(0xFF4E5E7C),
    primary: Color(0xFF4CC9F0),
    onPrimary: Color(0xFF04131F),
    accentPurple: Color(0xFF7B8CFF),
    accentBlue: Color(0xFF4CC9F0),
    accentOrange: Color(0xFFFFB454),
    accentGreen: Color(0xFF2EE6A6),
    accentPink: Color(0xFFFF6B9D),
    success: Color(0xFF2EE6A6),
    error: Color(0xFFFF6B7A),
    warning: Color(0xFFFFB454),
  );

  static const forest = AppPalette(
    id: 'forest',
    name: 'Forest',
    description: 'Calm dark green, easy on the eyes at night.',
    brightness: Brightness.dark,
    background: Color(0xFF0C1410),
    surface: Color(0xFF15221B),
    surfaceElevated: Color(0xFF1E2F26),
    border: Color(0xFF2A4034),
    textPrimary: Color(0xFFEEF7F0),
    textSecondary: Color(0xFF93AE9C),
    textDisabled: Color(0xFF4F6657),
    primary: Color(0xFF7BE495),
    onPrimary: Color(0xFF07140B),
    accentPurple: Color(0xFFB08CFF),
    accentBlue: Color(0xFF5DC8E8),
    accentOrange: Color(0xFFF5A663),
    accentGreen: Color(0xFF7BE495),
    accentPink: Color(0xFFF07EA3),
    success: Color(0xFF7BE495),
    error: Color(0xFFF07E7E),
    warning: Color(0xFFF5A663),
  );

  static const sunset = AppPalette(
    id: 'sunset',
    name: 'Sunset',
    description: 'Warm dark plum with orange and coral accents.',
    brightness: Brightness.dark,
    background: Color(0xFF17101A),
    surface: Color(0xFF241827),
    surfaceElevated: Color(0xFF312135),
    border: Color(0xFF433047),
    textPrimary: Color(0xFFFFF3EC),
    textSecondary: Color(0xFFC2A3B0),
    textDisabled: Color(0xFF6E5466),
    primary: Color(0xFFFF8E5A),
    onPrimary: Color(0xFF240F0A),
    accentPurple: Color(0xFFC77DFF),
    accentBlue: Color(0xFF6FB7FF),
    accentOrange: Color(0xFFFF8E5A),
    accentGreen: Color(0xFF5EE2B3),
    accentPink: Color(0xFFFF5C8A),
    success: Color(0xFF5EE2B3),
    error: Color(0xFFFF5C8A),
    warning: Color(0xFFFFB454),
  );

  static const lavender = AppPalette(
    id: 'lavender',
    name: 'Lavender',
    description: 'Soft light theme with purple accents.',
    brightness: Brightness.light,
    background: Color(0xFFF6F3FC),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFEDE7F8),
    border: Color(0xFFDCD3EE),
    textPrimary: Color(0xFF1E1530),
    textSecondary: Color(0xFF6B5F85),
    textDisabled: Color(0xFFB2A8C8),
    primary: Color(0xFF7C4DFF),
    onPrimary: Color(0xFFFFFFFF),
    accentPurple: Color(0xFF7C4DFF),
    accentBlue: Color(0xFF2F80ED),
    accentOrange: Color(0xFFF2994A),
    accentGreen: Color(0xFF27AE60),
    accentPink: Color(0xFFEB5757),
    success: Color(0xFF27AE60),
    error: Color(0xFFEB5757),
    warning: Color(0xFFF2994A),
  );

  static const paper = AppPalette(
    id: 'paper',
    name: 'Paper',
    description: 'Clean light theme for reading in daylight.',
    brightness: Brightness.light,
    background: Color(0xFFF7F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFEFEFEB),
    border: Color(0xFFE0E0DA),
    textPrimary: Color(0xFF1B1B1B),
    textSecondary: Color(0xFF6A6A66),
    textDisabled: Color(0xFFB4B4AE),
    primary: Color(0xFF1B1B1B),
    onPrimary: Color(0xFFFFFFFF),
    accentPurple: Color(0xFF7048E8),
    accentBlue: Color(0xFF1C7ED6),
    accentOrange: Color(0xFFE8590C),
    accentGreen: Color(0xFF0CA678),
    accentPink: Color(0xFFD6336C),
    success: Color(0xFF0CA678),
    error: Color(0xFFD6336C),
    warning: Color(0xFFE8590C),
  );

  static const all = [midnight, ocean, forest, sunset, lavender, paper];

  static AppPalette byId(String? id) => all.firstWhere((p) => p.id == id, orElse: () => midnight);
}
