import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_palette.dart';

/// Holds the selected theme. AppColors reads from it, so every screen follows the choice.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'selected_theme';

  AppPalette _palette = AppPalettes.midnight;
  AppPalette get palette => _palette;

  /// Call once at startup, before runApp.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _palette = AppPalettes.byId(prefs.getString(_key));
    } catch (_) {
      _palette = AppPalettes.midnight;
    }
  }

  Future<void> select(AppPalette palette) async {
    if (palette.id == _palette.id) return;
    _palette = palette;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, palette.id);
    } catch (_) {}
  }
}
