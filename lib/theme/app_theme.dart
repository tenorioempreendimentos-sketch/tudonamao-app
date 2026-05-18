import 'package:flutter/material.dart';

class AppColors {
  // SupraTech Brand Colors
  static const Color primaryDark = Color(0xFF0B1F3A);
  static const Color primaryBlue = Color(0xFF1E63B7);
  static const Color primaryBlueMedium = Color(0xFF2E86D1);
  static const Color accentOrange = Color(0xFFFF7A00);
  static const Color accentOrangeLight = Color(0xFFFFB13B);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0B1F3A);
  static const Color textMedium = Color(0xFF4A5568);
  static const Color textLight = Color(0xFF8A9BB0);
  static const Color success = Color(0xFF27AE60);
  static const Color danger = Color(0xFFE74C3C);
  static const Color divider = Color(0xFFE8EDF2);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [accentOrange, accentOrangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  // ── Tema claro ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentOrange,
        surface: const Color(0xFFF8FAFC),
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shadowColor: AppColors.primaryDark.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentOrange,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentOrange,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textMedium),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryBlue,
        selectedItemColor: AppColors.accentOrangeLight,
        unselectedItemColor: Color(0xFFBDD3EA),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 28),
        headlineMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 22),
        titleLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: TextStyle(color: AppColors.textMedium, fontSize: 15),
        bodyMedium: TextStyle(color: AppColors.textMedium, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textLight, fontSize: 12),
      ),
    );
  }

  // ── Tema escuro (original) ─────────────────────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentOrange,
        surface: AppColors.background,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 2,
        shadowColor: AppColors.primaryDark.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentOrange,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentOrange,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textMedium),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryDark,
        selectedItemColor: AppColors.accentOrange,
        unselectedItemColor: Color(0xFF7A9CC0),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        titleLarge: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textMedium,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textMedium,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: AppColors.textLight,
          fontSize: 12,
        ),
      ),
    );
  }
}
