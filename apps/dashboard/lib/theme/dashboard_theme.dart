import 'package:flutter/material.dart';

/// Single source of truth for the dashboard design system.
///
/// Inspired by Linear, Stripe Dashboard, Vercel.
/// Neutral palette, professional, desktop-first.
class DashboardTheme {
  DashboardTheme._();

  // ---------------------------------------------------------------------------
  // Colors
  // ---------------------------------------------------------------------------

  static const Color _primary = Color(0xFF6366F1); // indigo-500
  static const Color _primaryDark = Color(0xFF4F46E5); // indigo-600
  static const Color _danger = Color(0xFFEF4444); // red-500
  static const Color _success = Color(0xFF22C55E); // green-500
  static const Color _warning = Color(0xFFF59E0B); // amber-500

  static const Color _bg = Color(0xFFFAFAFA); // neutral-50
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E7EB); // gray-200
  static const Color _borderLight = Color(0xFFF3F4F6); // gray-100

  static const Color _textPrimary = Color(0xFF111827); // gray-900
  static const Color _textSecondary = Color(0xFF6B7280); // gray-500
  static const Color _textTertiary = Color(0xFF9CA3AF); // gray-400

  static const Color _sidebarBg = Color(0xFF111827); // gray-900
  static const Color _sidebarText = Color(0xFFD1D5DB); // gray-300
  static const Color _sidebarTextActive = Color(0xFFFFFFFF);
  static const Color _sidebarActive = Color(0xFF1F2937); // gray-800

  // ---------------------------------------------------------------------------
  // Spacing
  // ---------------------------------------------------------------------------

  static const double sp2 = 2;
  static const double sp4 = 4;
  static const double sp6 = 6;
  static const double sp8 = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;
  static const double sp32 = 32;
  static const double sp40 = 40;
  static const double sp48 = 48;

  // ---------------------------------------------------------------------------
  // Radius
  // ---------------------------------------------------------------------------

  static const double radius4 = 4;
  static const double radius6 = 6;
  static const double radius8 = 8;
  static const double radius12 = 12;
  static const double radius16 = 16;

  // ---------------------------------------------------------------------------
  // Sidebar
  // ---------------------------------------------------------------------------

  static const double sidebarWidth = 240;
  static const double topBarHeight = 60;

  // ---------------------------------------------------------------------------
  // ThemeData
  // ---------------------------------------------------------------------------

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFEEF2FF),
      onPrimaryContainer: _primaryDark,
      secondary: Color(0xFF64748B),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF1F5F9),
      onSecondaryContainer: Color(0xFF334155),
      tertiary: _success,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFF0FDF4),
      onTertiaryContainer: Color(0xFF166534),
      error: _danger,
      onError: Colors.white,
      errorContainer: Color(0xFFFEF2F2),
      onErrorContainer: Color(0xFF991B1B),
      surface: _surface,
      onSurface: _textPrimary,
      onSurfaceVariant: _textSecondary,
      outline: _border,
      outlineVariant: _borderLight,
      shadow: Color(0x0F000000),
      scrim: Color(0x66000000),
      inverseSurface: _textPrimary,
      onInverseSurface: _surface,
      inversePrimary: Color(0xFFA5B4FC),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bg,
      fontFamily: 'Inter',

      // Text theme — clean, readable
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.5),
        displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.3),
        displaySmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
            letterSpacing: -0.2),
        headlineLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _textPrimary),
        headlineMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textPrimary),
        headlineSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary),
        titleLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _textPrimary),
        titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textPrimary),
        titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textPrimary),
        bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: _textPrimary),
        bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _textPrimary),
        bodySmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: _textSecondary),
        labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textPrimary),
        labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _textSecondary),
        labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _textTertiary),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius8),
          side: const BorderSide(color: _border),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
              horizontal: sp16, vertical: sp8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius6)),
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          side: const BorderSide(color: _border),
          padding: const EdgeInsets.symmetric(
              horizontal: sp16, vertical: sp8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius6)),
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius6),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius6),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius6),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius6),
          borderSide: const BorderSide(color: _danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: sp12, vertical: sp10),
        hintStyle: const TextStyle(
            color: _textTertiary, fontSize: 14),
        labelStyle:
            const TextStyle(color: _textSecondary, fontSize: 14),
      ),

      dividerTheme: const DividerThemeData(
        color: _border,
        thickness: 1,
        space: 1,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: _border,
        iconTheme: IconThemeData(color: _textSecondary),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Semantic color helpers
  // ---------------------------------------------------------------------------

  static Color get primary => _primary;
  static Color get danger => _danger;
  static Color get success => _success;
  static Color get warning => _warning;
  static Color get bg => _bg;
  static Color get surface => _surface;
  static Color get border => _border;
  static Color get borderLight => _borderLight;
  static Color get textPrimary => _textPrimary;
  static Color get textSecondary => _textSecondary;
  static Color get textTertiary => _textTertiary;
  static Color get sidebarBg => _sidebarBg;
  static Color get sidebarText => _sidebarText;
  static Color get sidebarTextActive => _sidebarTextActive;
  static Color get sidebarActive => _sidebarActive;
}

// Convenient alias
const double sp10 = 10;
