import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppTheme {
  light,
  dark,
  purpleHaze,
  mintFresh,
  midnightBlue,
  sunsetGlow,
  forestGreen,
  oceanWave,
  crimsonBlush;

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
      case AppTheme.midnightBlue:
        return 'Midnight Blue';
      case AppTheme.sunsetGlow:
        return 'Sunset Glow';
      case AppTheme.forestGreen:
        return 'Forest Green';
      case AppTheme.oceanWave:
        return 'Ocean Wave';
      case AppTheme.crimsonBlush:
        return 'Crimson Blush';
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
        bodySmall: TextStyle(color: Colors.black),
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
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black),
        bodySmall: TextStyle(color: Colors.black),
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

  static ThemeData midnightBlueTheme = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Color(0xFF3949AB),
      surface: Color(0xFF121212),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFBBDEFB)),
        bodyMedium: TextStyle(color: Color(0xFFBBDEFB)),
        bodySmall: TextStyle(color: Color(0xFF90CAF9)),
      ),
    ),
  );

  static ThemeData sunsetGlowTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFF7043),
      secondary: Color(0xFFFFAB91),
      surface: Color(0xFFFFF3E0),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFFF7043)),
        bodyMedium: TextStyle(color: Color(0xFFFF7043)),
        bodySmall: TextStyle(color: Color(0xFFFFAB91)),
      ),
    ),
  );

  static ThemeData forestGreenTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF388E3C),
      secondary: Color(0xFF66BB6A),
      surface: Color(0xFFE8F5E9),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF388E3C)),
        bodyMedium: TextStyle(color: Color(0xFF388E3C)),
        bodySmall: TextStyle(color: Color(0xFF66BB6A)),
      ),
    ),
  );

  static ThemeData oceanWaveTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0288D1),
      secondary: Color(0xFF03A9F4),
      surface: Color(0xFFE1F5FE),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF0288D1)),
        bodyMedium: TextStyle(color: Color(0xFF0288D1)),
        bodySmall: TextStyle(color: Color(0xFF03A9F4)),
      ),
    ),
  );

  static ThemeData crimsonBlushTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFD32F2F),
      secondary: Color(0xFFFF5252),
      surface: Color(0xFFFFEBEE),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFD32F2F)),
        bodyMedium: TextStyle(color: Color(0xFFD32F2F)),
        bodySmall: TextStyle(color: Color(0xFFFF5252)),
      ),
    ),
  );

  static final Map<AppTheme, ThemeData> themeMap = {
    AppTheme.light: lightTheme,
    AppTheme.dark: darkTheme,
    AppTheme.purpleHaze: purpleHazeTheme,
    AppTheme.mintFresh: mintFreshTheme,
    AppTheme.midnightBlue: midnightBlueTheme,
    AppTheme.sunsetGlow: sunsetGlowTheme,
    AppTheme.forestGreen: forestGreenTheme,
    AppTheme.oceanWave: oceanWaveTheme,
    AppTheme.crimsonBlush: crimsonBlushTheme,
  };
}
