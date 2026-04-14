import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  // Warm amber/brown seed color suitable for Bible reading
  static const Color _seedColor = Color(0xFF7B4F2E);
  static const Color _lightBackground = Color(0xFFFDF6EC);
  static const Color _darkBackground = Color(0xFF1A120B);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ).copyWith(
      surface: _lightBackground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      surface: _darkBackground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    // Lora is a serif font optimized for reading long texts
    final serifBase = GoogleFonts.loraTextTheme();
    // Nunito for UI elements
    final sansBase = GoogleFonts.nunitoTextTheme();

    return sansBase.copyWith(
      // Use serif font for Bible text display (body styles)
      bodyLarge: serifBase.bodyLarge?.copyWith(
        fontSize: 18,
        height: 1.7,
        color: colorScheme.onSurface,
      ),
      bodyMedium: serifBase.bodyMedium?.copyWith(
        fontSize: 16,
        height: 1.6,
        color: colorScheme.onSurface,
      ),
      bodySmall: serifBase.bodySmall?.copyWith(
        fontSize: 14,
        height: 1.5,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
