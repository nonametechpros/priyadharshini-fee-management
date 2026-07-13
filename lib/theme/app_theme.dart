import 'package:flutter/material.dart';

/// Brand palette sampled directly from the Priyadarsini Driving School logo.
class AppColors {
  AppColors._();

  static const Color brandRed = Color(0xFFEA2628);
  static const Color brandRedDark = Color(0xFFB01417);
  static const Color brandYellow = Color(0xFFFFED24);
  static const Color brandBlack = Color(0xFF000000);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F5F2);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color divider = Color(0xFFE6E2DC);

  // Fee-status colors: pending reuses the brand red, partial reuses the
  // brand yellow, so status chips read as an extension of the logo itself.
  static const Color statusPaid = Color(0xFF1E8E5A);
  static const Color statusPartial = Color(0xFFB8860B);
  static const Color statusPending = brandRed;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandRed,
      primary: AppColors.brandRed,
      onPrimary: Colors.white,
      secondary: AppColors.brandYellow,
      onSecondary: AppColors.brandBlack,
      surface: AppColors.surface,
      error: AppColors.brandRed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.brandRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandRed,
          side: const BorderSide(color: AppColors.brandRed),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.brandRedDark),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandYellow,
        foregroundColor: AppColors.brandBlack,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.brandRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.brandRed),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.brandYellow,
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.brandBlack,
        indicatorColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: Colors.white),
        selectedLabelTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        unselectedIconTheme: IconThemeData(color: Colors.white70),
        unselectedLabelTextStyle: TextStyle(color: Colors.white70),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.brandBlack,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.brandBlack,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
