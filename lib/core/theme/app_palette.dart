import 'package:flutter/material.dart';

/// One complete colour set. Every theme in the app is an AppPalette.
/// Each theme has its OWN background, cards, text and accents, so the whole screen changes colour.
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

  final Color primary; // main buttons, selected tab
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

class AppPalettes {
  AppPalettes._();

  /// 1. The original Study Sensei look — the only black theme.
  static const midnight = AppPalette(
    id: 'midnight',
    name: 'Midnight Black',
    description: 'The original Study Sensei look.',
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

  /// 2. The only blue theme.
  static const ocean = AppPalette(
    id: 'ocean',
    name: 'Ocean Blue',
    description: 'Deep blue screens with bright cyan buttons.',
    brightness: Brightness.dark,
    background: Color(0xFF0B2545),
    surface: Color(0xFF13315C),
    surfaceElevated: Color(0xFF1B3F72),
    border: Color(0xFF285089),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB4C8E6),
    textDisabled: Color(0xFF6C86AD),
    primary: Color(0xFF5CE1E6),
    onPrimary: Color(0xFF062033),
    accentPurple: Color(0xFFB39DFF),
    accentBlue: Color(0xFF5CE1E6),
    accentOrange: Color(0xFFFFC15E),
    accentGreen: Color(0xFF6BF0B0),
    accentPink: Color(0xFFFF8FB1),
    success: Color(0xFF6BF0B0),
    error: Color(0xFFFF8F8F),
    warning: Color(0xFFFFC15E),
  );

  /// 3. Green.
  static const emerald = AppPalette(
    id: 'emerald',
    name: 'Emerald Green',
    description: 'Rich green screens with golden buttons.',
    brightness: Brightness.dark,
    background: Color(0xFF0B3D2E),
    surface: Color(0xFF125240),
    surfaceElevated: Color(0xFF186650),
    border: Color(0xFF237A60),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFBFE3D3),
    textDisabled: Color(0xFF6FA48D),
    primary: Color(0xFFF6C453),
    onPrimary: Color(0xFF2B1D00),
    accentPurple: Color(0xFFD4B5FF),
    accentBlue: Color(0xFF8FD3FF),
    accentOrange: Color(0xFFF6C453),
    accentGreen: Color(0xFF9DF7C9),
    accentPink: Color(0xFFFF9EB5),
    success: Color(0xFF9DF7C9),
    error: Color(0xFFFF9E9E),
    warning: Color(0xFFF6C453),
  );

  /// 4. Purple.
  static const royal = AppPalette(
    id: 'royal',
    name: 'Royal Purple',
    description: 'Purple screens with pink buttons.',
    brightness: Brightness.dark,
    background: Color(0xFF2A0F4F),
    surface: Color(0xFF3A1A68),
    surfaceElevated: Color(0xFF4A2580),
    border: Color(0xFF5C3496),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFD7C6F2),
    textDisabled: Color(0xFF9A82BF),
    primary: Color(0xFFFF7AC6),
    onPrimary: Color(0xFF3A0628),
    accentPurple: Color(0xFFE0B3FF),
    accentBlue: Color(0xFF9CC9FF),
    accentOrange: Color(0xFFFFC27A),
    accentGreen: Color(0xFF8FF2C8),
    accentPink: Color(0xFFFF7AC6),
    success: Color(0xFF8FF2C8),
    error: Color(0xFFFF8A9A),
    warning: Color(0xFFFFC27A),
  );

  /// 5. Warm red / orange.
  static const sunset = AppPalette(
    id: 'sunset',
    name: 'Sunset Red',
    description: 'Warm red-brown screens with orange buttons.',
    brightness: Brightness.dark,
    background: Color(0xFF4A1414),
    surface: Color(0xFF5E1E1C),
    surfaceElevated: Color(0xFF732A25),
    border: Color(0xFF8A3A31),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFF2C9BD),
    textDisabled: Color(0xFFB58276),
    primary: Color(0xFFFF9F43),
    onPrimary: Color(0xFF3A1A00),
    accentPurple: Color(0xFFE6B3FF),
    accentBlue: Color(0xFF9FD4FF),
    accentOrange: Color(0xFFFF9F43),
    accentGreen: Color(0xFFA3F0B5),
    accentPink: Color(0xFFFF8FA3),
    success: Color(0xFFA3F0B5),
    error: Color(0xFFFFB3B3),
    warning: Color(0xFFFFD166),
  );

  /// 6. Light: white screens.
  static const daylight = AppPalette(
    id: 'daylight',
    name: 'Daylight',
    description: 'Bright white screens with teal buttons, good in daylight.',
    brightness: Brightness.light,
    background: Color(0xFFF4F7F6),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFE6EEEC),
    border: Color(0xFFD3DEDB),
    textPrimary: Color(0xFF14211E),
    textSecondary: Color(0xFF55706A),
    textDisabled: Color(0xFFA3B5B0),
    primary: Color(0xFF0F8B7E),
    onPrimary: Color(0xFFFFFFFF),
    accentPurple: Color(0xFF6E4BD8),
    accentBlue: Color(0xFF1D72D8),
    accentOrange: Color(0xFFE07A10),
    accentGreen: Color(0xFF0F8B7E),
    accentPink: Color(0xFFD43F6A),
    success: Color(0xFF0F8B7E),
    error: Color(0xFFD43F3F),
    warning: Color(0xFFE07A10),
  );

  /// 7. Light: soft pink.
  static const blossom = AppPalette(
    id: 'blossom',
    name: 'Cherry Blossom',
    description: 'Soft pink screens with rose buttons.',
    brightness: Brightness.light,
    background: Color(0xFFFDEEF2),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF9DCE4),
    border: Color(0xFFF0C4D0),
    textPrimary: Color(0xFF3A1622),
    textSecondary: Color(0xFF8A5566),
    textDisabled: Color(0xFFC9A1AD),
    primary: Color(0xFFD6336C),
    onPrimary: Color(0xFFFFFFFF),
    accentPurple: Color(0xFF8E44C9),
    accentBlue: Color(0xFF2F7BD9),
    accentOrange: Color(0xFFE8740C),
    accentGreen: Color(0xFF1E9E6A),
    accentPink: Color(0xFFD6336C),
    success: Color(0xFF1E9E6A),
    error: Color(0xFFC92A2A),
    warning: Color(0xFFE8740C),
  );

  static const all = [midnight, ocean, emerald, royal, sunset, daylight, blossom];

  static AppPalette byId(String? id) => all.firstWhere((p) => p.id == id, orElse: () => midnight);
}
