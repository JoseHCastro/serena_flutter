import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Color Palette ---
  static const Color primaryColor = Color(0xFF003441);
  static const Color primaryLight = Color(0xFF0F4C5C);
  static const Color primaryContrast = Color(0xFFFFFFFF);
  
  static const Color secondaryColor = Color(0xFF326570);
  static const Color secondaryLight = Color(0xFFB5E8F5);
  
  static const Color accentColor = Color(0xFFFFDCBE);
  
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  
  static const Color textMain = Color(0xFF191C1D);
  static const Color textMuted = Color(0xFF40484B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  static const Color borderColor = Color(0xFFE1E3E4);
  static const Color errorColor = Color(0xFFBA1A1A);

  // --- Spacing & Radii ---
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 16.0;
  static const double radiusFull = 9999.0;

  // --- Theme Data ---
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: primaryContrast,
        secondary: secondaryColor,
        onSecondary: surfaceColor,
        error: errorColor,
        onError: surfaceColor,
        surface: surfaceColor,
        onSurface: textMain,
      ).copyWith(
        surfaceContainerHighest: backgroundColor, // Using this for background
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: const TextStyle(color: textMain, fontWeight: FontWeight.w700),
        displayMedium: const TextStyle(color: textMain, fontWeight: FontWeight.w700),
        displaySmall: const TextStyle(color: textMain, fontWeight: FontWeight.w700),
        headlineLarge: const TextStyle(color: textMain, fontWeight: FontWeight.w700),
        headlineMedium: const TextStyle(color: textMain, fontWeight: FontWeight.w700),
        headlineSmall: const TextStyle(color: textMain, fontWeight: FontWeight.w700),
        titleLarge: const TextStyle(color: textMain, fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(color: textMain, fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(color: textMain, fontWeight: FontWeight.w500),
        bodyLarge: const TextStyle(color: textMain, fontWeight: FontWeight.w400),
        bodyMedium: const TextStyle(color: textMain, fontWeight: FontWeight.w400),
        bodySmall: const TextStyle(color: textMuted, fontWeight: FontWeight.w400),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        hintStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor),
        ),
        prefixIconColor: textMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: primaryContrast,
          padding: const EdgeInsets.symmetric(horizontal: spacingXl, vertical: spacingSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          elevation: 2,
        ),
      ),
    );
  }
}
