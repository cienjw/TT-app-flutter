import 'package:flutter/material.dart';
import 'app_text_styles.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light().copyWith(
      primary: AppColors.darkPrimarySoft2,
      onPrimary: AppColors.white,
      secondary: AppColors.darkPrimarySoft,
      onSecondary: AppColors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      onSurfaceVariant: AppColors.lightTextSecondary,
      error: AppColors.error,
      onError: AppColors.white,
    ),
    scaffoldBg: AppColors.lightBg,
    surface: AppColors.lightSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    onSurface: AppColors.lightTextPrimary,
    hint: AppColors.lightTextHint,
    primary: AppColors.meetorySkyBlue,
  );

  static ThemeData get darkTheme => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark().copyWith(
      primary: AppColors.meetorySkyBlue,  // 혹은 좀 더 밝은 Color(0xFFB8DCE8)
      onPrimary: AppColors.darkBg,        // black 대신 darkBg로
      secondary: AppColors.pinkLight,
      onSecondary: AppColors.black,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkTextSecondary,
      error: AppColors.error,
      onError: AppColors.black,
    ),
    scaffoldBg: AppColors.darkBg,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    onSurface: AppColors.darkTextPrimary,
    hint: AppColors.darkTextHint,
    primary: AppColors.skyBlueLight,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffoldBg,
    required Color surface,
    required Color surfaceVariant,
    required Color onSurface,
    required Color hint,
    required Color primary,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        titleTextStyle: AppTextStyles.headline2.copyWith(color: onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.primary, width: 1.5),
          ),
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: scheme.primary, width: 1.5),
          foregroundColor: scheme.primary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : hint);
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: surfaceVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primary.withOpacity(0.7), width: 1.2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: hint),
      ),
    );
  }
}