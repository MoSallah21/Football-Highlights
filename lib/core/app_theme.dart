import 'package:flutter/material.dart';

/// Dark theme optimized for TV viewing with cinematic styling
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF1A1A2E),
      scaffoldBackgroundColor: const Color(0xFF0F0F1E),

      // Card theme for highlight cards
      cardTheme: CardTheme(
        color: const Color(0xFF1F1F3A),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Text theme optimized for TV reading distance
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Colors.white60,
        ),
      ),

      // Focus color for D-pad navigation
      focusColor: const Color(0xFF00D9FF),

      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00D9FF),
        secondary: Color(0xFFFF2E63),
        surface: Color(0xFF1F1F3A),
        background: Color(0xFF0F0F1E),
      ),
    );
  }

  // Glow effect for focused items
  static BoxDecoration focusedDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF00D9FF).withOpacity(0.6),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );
}