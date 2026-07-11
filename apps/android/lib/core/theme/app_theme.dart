import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Material 3 theme for Mr Squirrel Android app.
///
/// Visual language: calm, spacious, modern productivity app.
/// Inspired by Google Tasks / Google Wallet — not a POS system.
///
/// Design priorities:
/// - Large touch targets (minimum 48dp, prefer 56dp+)
/// - Clear typographic hierarchy (26sp home title → 15sp body)
/// - Green as accent only — surfaces are near-white neutral
/// - Subtle elevation instead of heavy borders
/// - Offline-first utility app feel
class AppTheme {
  AppTheme._();

  /// Brand green — used as seed for Material 3 tonal palette.
  /// Generates near-white surface tones automatically.
  static const _seedColor = Color(0xFF2E7D32);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      // Override surface to near-white so backgrounds feel clean
      surface: const Color(0xFFFAFAFA),
      surfaceContainerLow: const Color(0xFFF4F6F4),
      surfaceContainerLowest: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF4F6F4),
      textTheme: _textTheme,

      // System UI overlay — light status bar on light background
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withAlpha(20),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // Cards: white surface, subtle shadow, no hard border
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shadowColor: Colors.black.withAlpha(18),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated buttons: full-width, rounded, brand green
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: _seedColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE0E0E0),
          disabledForegroundColor: const Color(0xFF9E9E9E),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Inputs: Material 3 filled style — clean, modern, consistent
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
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
          borderSide: BorderSide(color: _seedColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB00020), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB00020), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(fontSize: 15),
        hintStyle: TextStyle(
          fontSize: 15,
          color: Colors.grey[500],
        ),
      ),

      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          color: Color(0xFF757575),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentTextStyle: const TextStyle(fontSize: 15),
      ),
    );
  }

  static const _textTheme = TextTheme(
    // Home screen title
    displaySmall: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    // Section headers
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    // Card titles
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    // Body text
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(fontSize: 15, height: 1.5),
    bodySmall: TextStyle(fontSize: 13, height: 1.4),
    // Labels
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 12),
  );
}
