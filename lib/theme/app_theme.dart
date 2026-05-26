import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class ThemeColors {
  Color get bg;
  Color get surface;
  Color get surfaceLight;
  Color get border;
  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;
  Color get primary;
}

class DarkColors implements ThemeColors {
  @override Color get bg => const Color(0xFF1A1A1A); 
  @override Color get surface => const Color(0xFF2C2C2C);
  @override Color get surfaceLight => const Color(0xFF383838);
  @override Color get border => const Color(0xFF000000); 
  @override Color get textPrimary => const Color(0xFFF7F7F7);
  @override Color get textSecondary => const Color(0xFFD1D5DB);
  @override Color get textMuted => const Color(0xFF9CA3AF);
  @override Color get primary => const Color(0xFFFFD93D); // Comic yellow
}

class LightColors implements ThemeColors {
  @override Color get bg => const Color(0xFFF5F0E8); // Warm cream for comic background
  @override Color get surface => const Color(0xFFFFFFFF); // Pure white for cards/inputs
  @override Color get surfaceLight => const Color(0xFFF3F4F6); 
  @override Color get border => const Color(0xFF1A1A1A); // Thick black for borders
  @override Color get textPrimary => const Color(0xFF1A1A1A); // Solid black for comic text
  @override Color get textSecondary => const Color(0xFF4B5563);
  @override Color get textMuted => const Color(0xFF9CA3AF);
  @override Color get primary => const Color(0xFFFFD93D); // Comic yellow
}

class AppColors {
  static const Color primary = Color(0xFFFFD93D); // Comic yellow
  static const Color primaryLight = Color(0xFFFFF4CC); 
  static const Color income = Color(0xFF4ADE80); // Comic green
  static const Color expense = Color(0xFFFF6B6B); // Comic red
  static const Color accent = Color(0xFF38BDF8); 

  // Backward compatibility static members (Default Light Comic Theme)
  static const Color bg = Color(0xFFF5F0E8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFF1A1A1A);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Helper static getters for current theme
  static ThemeColors of(BuildContext context) {
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return isDark ? DarkColors() : LightColors();
    } catch (_) {
      return LightColors();
    }
  }
}

class AppTheme {
  static ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? DarkColors() : LightColors();

    final baseTextTheme = brightness == Brightness.dark 
      ? ThemeData.dark().textTheme 
      : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.bg,
      textTheme: GoogleFonts.comicNeueTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.comicNeue(color: colors.textPrimary, fontWeight: FontWeight.w900),
        titleLarge: GoogleFonts.comicNeue(color: colors.textPrimary, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.comicNeue(color: colors.textPrimary, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.comicNeue(color: colors.textPrimary, fontWeight: FontWeight.w600),
        bodyMedium: GoogleFonts.comicNeue(color: colors.textSecondary, fontWeight: FontWeight.w600),
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.black, // Dark text on primary
        secondary: AppColors.income,
        onSecondary: Colors.black,
        error: AppColors.expense,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.comicNeue(
          color: colors.textPrimary, 
          fontWeight: FontWeight.w900, 
          fontSize: 22
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border, width: 3), // Comic border
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black, // Black text on yellow button
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border, width: 3), // Comic border
          ),
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          textStyle: GoogleFonts.comicNeue(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border, width: 3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border, width: 3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 4), // thicker when focused
        ),
        labelStyle: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold),
        hintStyle: TextStyle(color: colors.textMuted, fontWeight: FontWeight.bold),
      ),
    );
  }
}
