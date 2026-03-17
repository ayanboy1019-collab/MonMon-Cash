// ============================================================
//  app_theme.dart  –  Purple + Blue neon dark theme
// ============================================================

import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colours ──────────────────────────────────────
  static const Color primaryPurple   = Color(0xFF7C3AED); // Vivid purple
  static const Color primaryBlue     = Color(0xFF2563EB); // Electric blue
  static const Color accentNeon      = Color(0xFF00F5FF); // Neon cyan
  static const Color accentGold      = Color(0xFFFFD700); // Coin gold
  static const Color accentGreen     = Color(0xFF10B981); // Success green
  static const Color accentRed       = Color(0xFFEF4444); // Error red

  static const Color bgDark          = Color(0xFF0D0820); // Deep dark bg
  static const Color bgCard          = Color(0xFF1A1035); // Card bg
  static const Color bgCardLight     = Color(0xFF241848); // Lighter card
  static const Color borderColor     = Color(0xFF3D2B6B); // Subtle border

  static const Color textPrimary     = Color(0xFFFFFFFF);
  static const Color textSecondary   = Color(0xFFB0A0D0);
  static const Color textMuted       = Color(0xFF6B5B8A);

  // ── Gradients ──────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0D0820), Color(0xFF0A1628)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF241848), Color(0xFF1A1035)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Text Styles ────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: textPrimary, letterSpacing: 0.5,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: textPrimary,
  );
  static const TextStyle coinText = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w900,
    color: accentGold, letterSpacing: 1.0,
  );
  static const TextStyle bodyText = TextStyle(
    fontSize: 14, color: textSecondary, height: 1.5,
  );
  static const TextStyle labelText = TextStyle(
    fontSize: 12, color: textMuted, letterSpacing: 0.8,
    fontWeight: FontWeight.w500,
  );

  // ── Main Theme ─────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    primaryColor: primaryPurple,
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: primaryBlue,
      surface: bgCard,
      error: accentRed,
    ),
    fontFamily: 'Poppins',           // Add to pubspec assets if needed
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: heading2,
      iconTheme: IconThemeData(color: textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700,
        ),
        elevation: 8,
        shadowColor: primaryPurple.withOpacity(0.5),
      ),
    ),
    cardTheme: CardTheme(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: borderColor, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgCardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryPurple, width: 2),
      ),
      hintStyle: const TextStyle(color: textMuted),
      labelStyle: const TextStyle(color: textSecondary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgCard,
      selectedItemColor: accentNeon,
      unselectedItemColor: textMuted,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 16,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: bgCard,
      contentTextStyle: const TextStyle(color: textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ── Reusable Gradient Box Decoration ──────────────────────
BoxDecoration gradientCard({double radius = 20}) => BoxDecoration(
  gradient: AppTheme.cardGradient,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppTheme.borderColor),
  boxShadow: [
    BoxShadow(
      color: AppTheme.primaryPurple.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ],
);

BoxDecoration neonCard({Color color = AppTheme.primaryPurple, double radius = 20}) =>
    BoxDecoration(
      gradient: AppTheme.cardGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withOpacity(0.5)),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ],
    );
