import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(
        0xFF141414,
      ), // Premium dark background
      primaryColor: const Color(0xFFE50914), // Accent red color
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE50914),
        secondary: Color(0xFFE50914),
        surface: Color(0xFF1C1C1C),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 26,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        bodyLarge: TextStyle(fontSize: 16, height: 1.4),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white70, height: 1.3),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2B2B2B),
        selectedColor: const Color(0xFFE50914),
        secondarySelectedColor: const Color(0xFFE50914),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light background
      primaryColor: const Color(0xFFE50914), // Accent red color
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE50914),
        secondary: Color(0xFFE50914),
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 26,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16, height: 1.4),
        bodyMedium: TextStyle(color: Colors.black54, fontSize: 14, height: 1.3),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE0E0E0),
        selectedColor: const Color(0xFFE50914),
        secondarySelectedColor: const Color(0xFFE50914),
        labelStyle: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
