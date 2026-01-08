import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Color Palette (Semantic) ---
  // Dark Theme Colors (Existing)
  static const Color _darkBgPrimary = Color(0xFF0F172A); // Slate 900
  static const Color _darkBgSecondary = Color(0xFF1E293B); // Slate 800
  static const Color _darkBgTertiary = Color(0xFF334155); // Slate 700
  static const Color _darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color _darkTextSecondary = Color(0xFF94A3B8); // Slate 400

  // Light Theme Colors (New)
  static const Color _lightBgPrimary =
      Color(0xFFF8FAFC); // Slate 50 (Inverse of Dark Text)
  static const Color _lightBgSecondary = Color(0xFFFFFFFF); // White
  static const Color _lightBgTertiary = Color(0xFFE2E8F0); // Slate 200
  static const Color _lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color _lightTextSecondary = Color(0xFF334155); // Slate 700

  // Accents (Shared)
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color secondary = Color(0xFF9333EA); // Purple 600
  static const Color accentCyan = Color(0xFF0EA5E9);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentRed = Color(0xFFEF4444);

  // --- Theme Data Definitions ---

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBgPrimary,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: _darkBgSecondary, // Cards, Dialogs, Sidebars
      // background: _darkBgPrimary, // Deprecated in Flutter 3.22+, use surface or scaffoldBackgroundColor
      surfaceContainer: _darkBgSecondary, // M3 specific
      surfaceContainerHigh: _darkBgTertiary,
      onSurface: _darkTextPrimary,
      onSurfaceVariant: _darkTextSecondary,
      error: accentRed,
    ),
    dividerColor: _darkBgTertiary,
    cardColor: _darkBgSecondary,
    dialogTheme: const DialogThemeData(
      backgroundColor: _darkBgSecondary,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: GoogleFonts.notoSansKrTextTheme(const TextTheme(
      bodyLarge: TextStyle(color: _darkTextPrimary),
      bodyMedium: TextStyle(color: _darkTextPrimary),
      bodySmall: TextStyle(color: _darkTextSecondary),
      titleLarge:
          TextStyle(color: _darkTextPrimary, fontWeight: FontWeight.bold),
    )),
    iconTheme: const IconThemeData(color: _darkTextSecondary),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBgPrimary,
      foregroundColor: _darkTextPrimary,
      elevation: 0,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBgPrimary,
    primaryColor: primary,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: _lightBgSecondary,
      surfaceContainerLow: _lightBgPrimary,
      surfaceContainer: _lightBgSecondary,
      surfaceContainerHigh: _lightBgTertiary,
      surfaceContainerHighest:
          Color(0xFFCBD5E1), // Slate 300 for clearer contrast
      onSurface: _lightTextPrimary,
      onSurfaceVariant: _lightTextSecondary,
      error: accentRed,
    ),
    dividerColor: _lightBgTertiary,
    cardColor: _lightBgSecondary,
    dialogTheme: const DialogThemeData(
      backgroundColor: _lightBgSecondary,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: GoogleFonts.notoSansKrTextTheme(const TextTheme(
      bodyLarge: TextStyle(color: _lightTextPrimary),
      bodyMedium: TextStyle(color: _lightTextPrimary),
      bodySmall: TextStyle(color: _lightTextSecondary),
      titleLarge:
          TextStyle(color: _lightTextPrimary, fontWeight: FontWeight.bold),
    )),
    iconTheme:
        const IconThemeData(color: _lightTextPrimary), // Darker icon color
    popupMenuTheme: const PopupMenuThemeData(
      color: _lightBgSecondary,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      textStyle: TextStyle(color: _lightTextPrimary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBgPrimary,
      foregroundColor: _lightTextPrimary,
      elevation: 0,
    ),
  );
}
