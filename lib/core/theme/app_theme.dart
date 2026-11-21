import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_palette.dart';
import 'theme_controller.dart';

class AppTheme {
  AppTheme._();

  /// The CURRENT theme. Old code that still says `theme: AppTheme.dark` now follows the user's choice too.
  static ThemeData get dark => fromPalette(ThemeController.instance.palette);
  static ThemeData get current => dark;

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
        // Status bar icons: white on dark themes, dark on light themes.
        systemOverlayStyle: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      iconTheme: IconThemeData(color: p.textPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintStyle: TextStyle(color: p.textSecondary),
        labelStyle: TextStyle(color: p.textSecondary),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
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
        height: 74,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(size: 27, color: s.contains(WidgetState.selected) ? p.primary : p.textSecondary),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12.5,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? p.primary : p.textSecondary,
          ),
        ),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: p.textPrimary,
        unselectedLabelColor: p.textSecondary,
        indicatorColor: p.primary,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: p.surface,
        titleTextStyle: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        contentTextStyle: TextStyle(color: p.textSecondary, fontSize: 14),
      ),
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
      canvasColor: p.background,
      cardColor: p.surface,
      listTileTheme: ListTileThemeData(textColor: p.textPrimary, iconColor: p.textSecondary),
      chipTheme: base.chipTheme.copyWith(backgroundColor: p.surfaceElevated, selectedColor: p.primary.withOpacity(0.25), labelStyle: TextStyle(color: p.textPrimary), side: BorderSide(color: p.border)),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      popupMenuTheme: PopupMenuThemeData(color: p.surface),
      drawerTheme: DrawerThemeData(backgroundColor: p.surface),
      dividerTheme: DividerThemeData(color: p.border),
      dividerColor: p.border,
      splashColor: p.primary.withOpacity(0.08),
    );
  }
}
