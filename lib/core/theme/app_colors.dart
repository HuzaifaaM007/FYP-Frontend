import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'theme_controller.dart';

/// Colours of the currently selected theme.
///
/// These used to be `static const`; they are now getters, so any widget using them must not be
/// `const` (see tools/remove_const_colors.py which does that change for you).
class AppColors {
  AppColors._();

  static AppPalette get _p => ThemeController.instance.palette;

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceElevated => _p.surfaceElevated;
  static Color get border => _p.border;

  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textDisabled => _p.textDisabled;

  static Color get primary => _p.primary;
  static Color get onPrimary => _p.onPrimary;

  static Color get accentPurple => _p.accentPurple;
  static Color get accentBlue => _p.accentBlue;
  static Color get accentOrange => _p.accentOrange;
  static Color get accentGreen => _p.accentGreen;
  static Color get accentPink => _p.accentPink;

  static List<Color> get accentPalette => _p.accentPalette;

  static Color get success => _p.success;
  static Color get error => _p.error;
  static Color get warning => _p.warning;
}
