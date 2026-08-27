import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱에서 선택 가능한 5가지 테마 프리셋
enum AppThemePreset {
  slateDark,      // 🌌 Slate Dark (기본 클래식 다크)
  obsidianCyber,  // ✨ Obsidian Cyber (사이버 네온 & 인디고)
  vintageAmber,   // 🎸 Vintage Amber (따뜻한 앰버 & 마호가니 골드)
  forestEmerald,  // 🌿 Midnight Forest (차분한 에메랄드 & 딥 그린)
  studioLight,    // ☀️ Studio Clean (화사하고 깨끗한 라이트)
}

extension AppThemePresetExtension on AppThemePreset {
  String get label {
    switch (this) {
      case AppThemePreset.slateDark:
        return '🌌 Slate Dark (기본)';
      case AppThemePreset.obsidianCyber:
        return '✨ Obsidian Cyber';
      case AppThemePreset.vintageAmber:
        return '🎸 Vintage Amber';
      case AppThemePreset.forestEmerald:
        return '🌿 Midnight Forest';
      case AppThemePreset.studioLight:
        return '☀️ Studio Clean (라이트)';
    }
  }

  String get shortName {
    switch (this) {
      case AppThemePreset.slateDark:
        return 'Slate Dark';
      case AppThemePreset.obsidianCyber:
        return 'Obsidian';
      case AppThemePreset.vintageAmber:
        return 'Vintage';
      case AppThemePreset.forestEmerald:
        return 'Forest';
      case AppThemePreset.studioLight:
        return 'Studio Light';
    }
  }

  Color get primaryAccent {
    switch (this) {
      case AppThemePreset.slateDark:
        return const Color(0xFF6366F1); // Indigo
      case AppThemePreset.obsidianCyber:
        return const Color(0xFF06B6D4); // Cyan
      case AppThemePreset.vintageAmber:
        return const Color(0xFFF59E0B); // Amber Gold
      case AppThemePreset.forestEmerald:
        return const Color(0xFF10B981); // Emerald
      case AppThemePreset.studioLight:
        return const Color(0xFF4F46E5); // Deep Indigo
    }
  }

  Color get previewBg {
    switch (this) {
      case AppThemePreset.slateDark:
        return const Color(0xFF0F172A);
      case AppThemePreset.obsidianCyber:
        return const Color(0xFF070B14);
      case AppThemePreset.vintageAmber:
        return const Color(0xFF1C130D);
      case AppThemePreset.forestEmerald:
        return const Color(0xFF061A14);
      case AppThemePreset.studioLight:
        return const Color(0xFFF8FAFC);
    }
  }

  bool get isDark => this != AppThemePreset.studioLight;
}

class AppTheme {
  // Shared Accents
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF9333EA);
  static const Color accentCyan = Color(0xFF0EA5E9);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentRed = Color(0xFFEF4444);

  // Modern Tonal Tokens
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color neonAmber = Color(0xFFF59E0B);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color neonIndigo = Color(0xFF6366F1);
  static const Color neonRose = Color(0xFFF43F5E);
  static const Color neonEmerald = Color(0xFF10B981);

  /// Glassmorphic container box decoration
  static BoxDecoration glassBox({
    Color? bgColor,
    Color? borderColor,
    double borderRadius = 16,
    double borderWidth = 1,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: bgColor ?? const Color(0xCC131D31),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? const Color(0x2AFFFFFF),
        width: borderWidth,
      ),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
    );
  }

  /// Preset에 따른 배경 그라데이션 반환
  static List<Color> getBackgroundGradient(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.slateDark:
        return const [
          Color(0xFF0F172A), // Slate 900
          Color(0xFF1E1B4B), // Indigo 950
          Color(0xFF312E81), // Indigo 900
        ];
      case AppThemePreset.obsidianCyber:
        return const [
          Color(0xFF05070D), // Obsidian Black
          Color(0xFF0B132B), // Deep Cyber Navy
          Color(0xFF1C2541), // Cyber Blue
        ];
      case AppThemePreset.vintageAmber:
        return const [
          Color(0xFF170E08), // Dark Walnut
          Color(0xFF2A1B0E), // Espresso Wood
          Color(0xFF452613), // Warm Mahogany
        ];
      case AppThemePreset.forestEmerald:
        return const [
          Color(0xFF04120D), // Deep Pine
          Color(0xFF0A231C), // Midnight Forest
          Color(0xFF133E32), // Emerald Dusk
        ];
      case AppThemePreset.studioLight:
        return const [
          Color(0xFFF8FAFC), // Slate 50
          Color(0xFFEEF2FF), // Indigo 50
          Color(0xFFE0E7FF), // Indigo 100
        ];
    }
  }

  /// Preset에 따른 전체 ThemeData 반환
  static ThemeData getTheme(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.slateDark:
        return _buildDarkTheme(
          scaffoldBg: const Color(0xFF0F172A),
          surface: const Color(0xFF1E293B),
          surfaceHigh: const Color(0xFF334155),
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFFA855F7),
          textPrimary: const Color(0xFFF8FAFC),
          textSecondary: const Color(0xFF94A3B8),
        );
      case AppThemePreset.obsidianCyber:
        return _buildDarkTheme(
          scaffoldBg: const Color(0xFF070B14),
          surface: const Color(0xFF0F172A),
          surfaceHigh: const Color(0xFF1E293B),
          primary: const Color(0xFF06B6D4),
          secondary: const Color(0xFF6366F1),
          textPrimary: const Color(0xFFF8FAFC),
          textSecondary: const Color(0xFF94A3B8),
        );
      case AppThemePreset.vintageAmber:
        return _buildDarkTheme(
          scaffoldBg: const Color(0xFF1A120B),
          surface: const Color(0xFF2B1E16),
          surfaceHigh: const Color(0xFF3E2C20),
          primary: const Color(0xFFF59E0B),
          secondary: const Color(0xFFD97706),
          textPrimary: const Color(0xFFFEF3C7),
          textSecondary: const Color(0xFFD4B996),
        );
      case AppThemePreset.forestEmerald:
        return _buildDarkTheme(
          scaffoldBg: const Color(0xFF061A14),
          surface: const Color(0xFF0E2E25),
          surfaceHigh: const Color(0xFF164438),
          primary: const Color(0xFF10B981),
          secondary: const Color(0xFF14B8A6),
          textPrimary: const Color(0xFFECFDF5),
          textSecondary: const Color(0xFFA7F3D0),
        );
      case AppThemePreset.studioLight:
        return _buildLightTheme();
    }
  }

  static ThemeData _buildDarkTheme({
    required Color scaffoldBg,
    required Color surface,
    required Color surfaceHigh,
    required Color primary,
    required Color secondary,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        surfaceContainer: surface,
        surfaceContainerHigh: surfaceHigh,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        error: accentRed,
      ),
      dividerColor: surfaceHigh,
      cardColor: surface,
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: GoogleFonts.notoSansKrTextTheme(TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      )),
      iconTheme: IconThemeData(color: textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
    );
  }

  static ThemeData _buildLightTheme() {
    const lightBgPrimary = Color(0xFFF8FAFC);
    const lightBgSecondary = Color(0xFFFFFFFF);
    const lightBgTertiary = Color(0xFFE2E8F0);
    const lightTextPrimary = Color(0xFF0F172A);
    const lightTextSecondary = Color(0xFF334155);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBgPrimary,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: lightBgSecondary,
        surfaceContainerLow: lightBgPrimary,
        surfaceContainer: lightBgSecondary,
        surfaceContainerHigh: lightBgTertiary,
        surfaceContainerHighest: Color(0xFFCBD5E1),
        onSurface: lightTextPrimary,
        onSurfaceVariant: lightTextSecondary,
        error: accentRed,
      ),
      dividerColor: lightBgTertiary,
      cardColor: lightBgSecondary,
      dialogTheme: const DialogThemeData(
        backgroundColor: lightBgSecondary,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: GoogleFonts.notoSansKrTextTheme(const TextTheme(
        bodyLarge: TextStyle(color: lightTextPrimary),
        bodyMedium: TextStyle(color: lightTextPrimary),
        bodySmall: TextStyle(color: lightTextSecondary),
        titleLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold),
      )),
      iconTheme: const IconThemeData(color: lightTextPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBgPrimary,
        foregroundColor: lightTextPrimary,
        elevation: 0,
      ),
    );
  }

  static final ThemeData darkTheme = getTheme(AppThemePreset.slateDark);
  static final ThemeData lightTheme = _buildLightTheme();
}
