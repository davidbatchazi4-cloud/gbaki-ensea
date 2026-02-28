import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs ENSEA
  static const Color primaryBlue = Color(0xFF1B4B8A);
  static const Color lightBlue = Color(0xFF4A90D9);
  static const Color skyBlue = Color(0xFF76B8E8);
  static const Color darkBlue = Color(0xFF0D2E5C);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F7FA);
  static const Color lightGray = Color(0xFFE8EDF2);
  static const Color textDark = Color(0xFF1A2332);
  static const Color textMedium = Color(0xFF4A5568);
  static const Color textLight = Color(0xFF8096B0);
  static const Color accentGold = Color(0xFFF5A623);
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBlue, primaryBlue, lightBlue],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B4B8A), Color(0xFF2D6DB8)],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: lightBlue,
        surface: white,
      ),
      scaffoldBackgroundColor: offWhite,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 14,
          color: textMedium,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13,
          color: textMedium,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
        shadowColor: primaryBlue.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(color: textLight, fontSize: 13),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightGray,
        selectedColor: primaryBlue,
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
