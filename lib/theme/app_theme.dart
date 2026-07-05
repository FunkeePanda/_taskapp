import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color maroon = Color(0xFF7A1E2E);
  static const Color maroonLight = Color(0xFFA8394A);
  static const Color maroonDark = Color(0xFF54141F);

  static const Color slateBackground = Color(0xFF1B1D22);
  static const Color slateSurface = Color(0xFF2A2D34);
  static const Color slateSurfaceAlt = Color(0xFF363943);
  static const Color slateBorder = Color(0xFF484C57);

  static const Color textPrimary = Color(0xFFF2EEEE);
  static const Color textSecondary = Color(0xFFB8B7BD);

  static const List<Color> confettiColors = [
    maroon,
    maroonLight,
    Color(0xFFE0A96D),
    Color(0xFFD8D2C2),
    slateSurfaceAlt,
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.slateBackground,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: AppColors.maroon,
        secondary: AppColors.maroonLight,
        surface: AppColors.slateSurface,
        onPrimary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.slateBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.slateSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.slateBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.slateSurface,
        selectedItemColor: AppColors.maroonLight,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.maroon,
        foregroundColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slateSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.maroon,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.slateBorder),
    );
  }
}
