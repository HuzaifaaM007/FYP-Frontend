import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_palette.dart';

class AppTheme {
  AppTheme._();

  /// Kept for old call sites; same as building from the Midnight palette.
  static ThemeData get dark => fromPalette(AppPalettes.midnight);

  static ThemeData fromPalette(AppPalette p) {
    final base = p.isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      brightness: p.brightness,
      scaffoldBackgroundColor: p.background,
      colorScheme: base.colorScheme.copyWith(
        brightness: p.brightness,
        primary: p.primary,
        onPrimary: p.onPrimary,
        secondary: p.accentBlue,
        surface: p.surface,
        onSurface: p.textPrimary,
        error: p.error,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: p.textPrimary,
        displayColor: p.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        elevation: 0,
        centerTitle: false,
        foregroundColor: p.textPrimary,
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      iconTheme: IconThemeData(color: p.textPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintStyle: TextStyle(color: p.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: p.textPrimary, side: BorderSide(color: p.border)),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.textPrimary)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: p.primary, foregroundColor: p.onPrimary),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textSecondary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.primary.withOpacity(0.18),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.primary : p.textSecondary),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(fontSize: 12, color: s.contains(WidgetState.selected) ? p.primary : p.textSecondary),
        ),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: p.textPrimary,
        unselectedLabelColor: p.textSecondary,
        indicatorColor: p.primary,
      ),
      dialogTheme: base.dialogTheme.copyWith(backgroundColor: p.surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.surface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceElevated,
        contentTextStyle: TextStyle(color: p.textPrimary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.primary : Colors.transparent),
        checkColor: WidgetStateProperty.all(p.onPrimary),
        side: BorderSide(color: p.textSecondary),
      ),
      cardColor: p.surface,
      dividerColor: p.border,
      splashColor: p.primary.withOpacity(0.08),
    );
  }
}
