import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'presnt_tokens.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
    );

    final manrope = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: PresntTokens.onSurface,
      displayColor: PresntTokens.onSurface,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PresntTokens.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.dark(
        primary: PresntTokens.primary,
        secondary: PresntTokens.secondary,
        surface: PresntTokens.surfaceContainerHigh,
        error: AppColors.danger,
        onPrimary: PresntTokens.onPrimaryFixed,
        onSecondary: const Color(0xFF003829),
        onSurface: PresntTokens.onSurface,
        onError: PresntTokens.onPrimaryFixed,
      ),
      textTheme: manrope,
      appBarTheme: AppBarTheme(
        backgroundColor: PresntTokens.background,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: PresntTokens.primary),
        titleTextStyle: GoogleFonts.manrope(
          color: PresntTokens.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: PresntTokens.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: const Color(0xFF1A1A1A),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: TextStyle(color: PresntTokens.surfaceBright.withValues(alpha: 0.8)),
        labelStyle: GoogleFonts.inter(
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.w500,
          color: PresntTokens.outline,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: PresntTokens.primary,
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
