import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RezaColors {
  static const primaryNavy = Color(0xFF1B2A4A);
  static const accentGold = Color(0xFFD4A843);
  static const backgroundDark = Color(0xFF0F1923);
  static const cardDark = Color(0xFF1A2736);
  static const textWhite = Color(0xFFFFFFFF);
  static const textGray = Color(0xFF8B9BB4);
  static const errorRed = Color(0xFFE57373);
  static const successGreen = Color(0xFF81C784);
  static const borderDark = Color(0xFF2A3A4A);

  static const backgroundLight = Color(0xFFF8F9FC);
  static const cardLight = Color(0xFFFFFFFF);
  static const textBlack = Color(0xFF1B2A4A);
  static const textGrayLight = Color(0xFF6B7280);
  static const borderLight = Color(0xFFE5E7EB);
}

extension ThemeDataX on ThemeData {
  TextStyle? get headlineLarge => textTheme.headlineLarge;
  TextStyle? get headlineMedium => textTheme.headlineMedium;
  TextStyle? get bodyLarge => textTheme.bodyLarge;
  TextStyle? get bodyMedium => textTheme.bodyMedium;
}

class RezaTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: RezaColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: RezaColors.accentGold,
        surface: RezaColors.cardDark,
        error: RezaColors.errorRed,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: RezaColors.textWhite,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: RezaColors.textWhite,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: RezaColors.textWhite,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: RezaColors.textGray,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RezaColors.accentGold,
          foregroundColor: RezaColors.primaryNavy,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RezaColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RezaColors.accentGold),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: RezaColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: RezaColors.primaryNavy,
        surface: RezaColors.cardLight,
        error: RezaColors.errorRed,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: RezaColors.textBlack,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: RezaColors.textBlack,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: RezaColors.textBlack,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: RezaColors.textGrayLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RezaColors.primaryNavy,
          foregroundColor: RezaColors.textWhite,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RezaColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RezaColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RezaColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RezaColors.primaryNavy, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
