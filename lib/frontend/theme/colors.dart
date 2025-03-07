import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppTheme {
  light,
  dark,
  purpleHaze,
  mintFresh;

  String get name => toString().split('.').last;
}

extension AppThemeExtension on AppTheme {
  String get name {
    switch (this) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.purpleHaze:
        return 'Purple Haze';
      case AppTheme.mintFresh:
        return 'Mint Fresh';
    }
  }
}

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Color(0xFF7AA2F7),
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black),
        bodySmall: TextStyle(color: Colors.grey),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Color(0xFF7AA2F7),
      surface: Color(0xFF1F2335),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.grey),
      ),
    ),
  );

  static ThemeData purpleHazeTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFBB9AF7),
      secondary: Color(0xFFC0A7F3),
      surface: Color(0xFFF5F5F5),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFBB9AF7)),
        bodyMedium: TextStyle(color: Color(0xFFBB9AF7)),
        bodySmall: TextStyle(color: Color(0xFFC0A7F3)),
      ),
    ),
  );

  static ThemeData mintFreshTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF9ECE6A),
      secondary: Color(0xFFA3C98F),
      surface: Color(0xFFE5F6DF),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF9ECE6A)),
        bodyMedium: TextStyle(color: Color(0xFF9ECE6A)),
        bodySmall: TextStyle(color: Color(0xFFA3C98F)),
      ),
    ),
  );

  static final Map<AppTheme, ThemeData> themeMap = {
    AppTheme.light: lightTheme,
    AppTheme.dark: darkTheme,
    AppTheme.purpleHaze: purpleHazeTheme,
    AppTheme.mintFresh: mintFreshTheme,
  };
}
