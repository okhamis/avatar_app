import 'package:flutter/material.dart';

/// Material-style editorial tokens from the HTML / Tailwind reference.
abstract final class PresntTokens {
  static const Color background = Color(0xFF131313);
  static const Color backgroundLowest = Color(0xFF0E0E0E);
  static const Color surface = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerLowest = Color(0xFF0A0A0A);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  static const Color surfaceBright = Color(0xFF3A3939);
  static const Color outline = Color(0xFF928F9D);
  static const Color outlineVariant = Color(0xFF474552);

  static const Color primary = Color(0xFFC5C0FF);
  static const Color primaryContainer = Color(0xFF8C84EB);
  static const Color onPrimaryFixed = Color(0xFF140067);
  static const Color onPrimaryContainer = Color(0xFF23127D);

  static const Color secondary = Color(0xFF6EDAB4);
  static const Color secondaryFixed = Color(0xFF8AF7CF);

  static const Color tertiary = Color(0xFFFFB3AE);
  static const Color tertiaryContainer = Color(0xFFF85B58);

  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFC8C4D4);
  static const Color onBackground = Color(0xFFE5E2E1);

  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);

  /// Brand CTA accent (legacy product accent)
  static const Color ctaPurple = Color(0xFF7F77DD);

  static const LinearGradient primaryCtaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );
}
