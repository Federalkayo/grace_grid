import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Base Surface Colors
  static const Color background = Color(0xFF0D1511);
  static const Color surfaceLowest = Color(0xFF08100C);
  static const Color surfaceLow = Color(0xFF151D19);
  static const Color surfaceContainer = Color(0xFF19211D);
  static const Color surfaceHigh = Color(0xFF242C27);
  static const Color surfaceHighest = Color(0xFF2E3732);

  // Primary Luminescent Emeralds
  static const Color primary = Color(0xFF76FFAF);
  static const Color primaryContainer = Color(0xFF00E68A);
  static const Color onPrimary = Color(0xFF00391E);
  static const Color onPrimaryContainer = Color(0xFF006137);

  // Secondary Ethereal Teals
  static const Color secondary = Color(0xFF4CD7F6);
  static const Color secondaryContainer = Color(0xFF03B5D3);
  static const Color onSecondary = Color(0xFF003640);
  static const Color onSecondaryContainer = Color(0xFF00424E);

  // Tertiary
  static const Color tertiary = Color(0xFF72FEC0);
  static const Color onTertiary = Color(0xFF003824);

  // Text & On-Surface
  static const Color onSurface = Color(0xFFDCE5DD);
  static const Color onSurfaceVariant = Color(0xFFBACBBC);
  static const Color scriptureIvory = Color(0xFFECFDF5);

  // Borders & Outlines
  static const Color outline = Color(0xFF849587);
  static const Color outlineVariant = Color(0xFF3B4A3F);
  static const Color emeraldStrokeAlpha15 = Color(0x2610B981);
  static const Color emeraldStrokeAlpha25 = Color(0x4000E68A);
  static const Color emeraldStrokeAlpha40 = Color(0x6600E68A);

  // Errors
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surfaceContainer,
        surfaceContainerHighest: surfaceHighest,
        primary: primary,
        primaryContainer: primaryContainer,
        onPrimary: onPrimary,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        onSecondary: onSecondary,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
        errorContainer: errorContainer,
        onError: onError,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.displayLarge,
          fontSize: 44,
          fontWeight: FontWeight.w800,
          height: 52 / 44,
          letterSpacing: -1.32,
          color: onSurface,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.headlineLarge,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 38 / 30,
          letterSpacing: -0.6,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.headlineMedium,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 28 / 22,
          letterSpacing: -0.22,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.headlineSmall,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 24 / 18,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          textStyle: baseTextTheme.bodyLarge,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 24 / 16,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          textStyle: baseTextTheme.bodyMedium,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 20 / 14,
          color: onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.labelLarge,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: onPrimary,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.labelMedium,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 16 / 13,
          letterSpacing: 0.52,
          color: onSurface,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          textStyle: baseTextTheme.labelSmall,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 14 / 11,
          letterSpacing: 0.88,
          color: onSurfaceVariant,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceLow,
        selectedItemColor: primaryContainer,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static TextStyle get scriptureStyle => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 28 / 17,
        letterSpacing: 0.17,
        color: scriptureIvory,
      );
}
