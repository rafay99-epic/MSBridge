// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
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
  crimsonBlush,
  cyberDark,
  neonPunk,
  auroraBorealis,
  cosmicVoid,
  electricBlue,
  goldenHour,
  midnightPurple,
  tropicalParadise,
  arcticFrost,
  pureBlack;

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
      case AppTheme.cyberDark:
        return 'Cyber Dark';
      case AppTheme.neonPunk:
        return 'Neon Punk';
      case AppTheme.auroraBorealis:
        return 'Aurora Borealis';
      case AppTheme.cosmicVoid:
        return 'Cosmic Void';
      case AppTheme.electricBlue:
        return 'Electric Blue';
      case AppTheme.goldenHour:
        return 'Golden Hour';
      case AppTheme.midnightPurple:
        return 'Midnight Purple';
      case AppTheme.tropicalParadise:
        return 'Tropical Paradise';
      case AppTheme.arcticFrost:
        return 'Arctic Frost';
      case AppTheme.pureBlack:
        return 'Black & Orange';
    }
  }

  String imagePath() {
    switch (this) {
      case AppTheme.light:
        return 'assets/svg/light mode.svg';
      case AppTheme.dark:
        return 'assets/svg/mid_dark.svg';
      case AppTheme.purpleHaze:
        return 'assets/svg/purple_lavender.svg';
      case AppTheme.mintFresh:
        return 'assets/svg/MintFresh.svg';
      case AppTheme.midnightBlue:
        return 'assets/svg/mid_dark.svg';
      case AppTheme.sunsetGlow:
        return 'assets/svg/SunsetGlow.svg';
      case AppTheme.forestGreen:
        return 'assets/svg/ForestGreen.svg';
      case AppTheme.oceanWave:
        return 'assets/svg/OceanWave.svg';
      case AppTheme.crimsonBlush:
        return 'assets/svg/CrimsonBlush.svg';
      case AppTheme.cyberDark:
        return 'assets/svg/cyber_dark.svg';
      case AppTheme.neonPunk:
        return 'assets/svg/cyber_dark.svg';
      case AppTheme.auroraBorealis:
        return 'assets/svg/cyber_dark.svg';
      case AppTheme.cosmicVoid:
        return 'assets/svg/mid_dark.svg';
      case AppTheme.electricBlue:
        return 'assets/svg/OceanWave.svg';
      case AppTheme.goldenHour:
        return 'assets/svg/SunsetGlow.svg';
      case AppTheme.midnightPurple:
        return 'assets/svg/purple_lavender.svg';
      case AppTheme.tropicalParadise:
        return 'assets/svg/ForestGreen.svg';
      case AppTheme.arcticFrost:
        return 'assets/svg/cyber_dark.svg';
      case AppTheme.pureBlack:
        return 'assets/svg/SunsetGlow.svg';
    }
  }
}

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Color(0xFF7AA2F7),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      outline: Color(0xFFE0E0E0),
      shadow: Color(0xFF000000),
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
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      outline: Color(0xFF2A2E3D),
      shadow: Color(0xFF000000),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white),
      ),
    ),
  );

  static ThemeData purpleHazeTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFBB9AF7),
      secondary: Color(0xFFC0A7F3),
      surface: Color(0xFFF5F5F5),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFBB9AF7),
      outline: Color(0xFFE8E0F7),
      shadow: Color(0xFFBB9AF7),
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
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF9ECE6A),
      outline: Color(0xFFD4F0C4),
      shadow: Color(0xFF9ECE6A),
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
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Color(0xFFBBDEFB),
      outline: Color(0xFF1E1E1E),
      shadow: Color(0xFF3949AB),
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
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFFF7043),
      outline: Color(0xFFFFE0B2),
      shadow: Color(0xFFFF7043),
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
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF388E3C),
      outline: Color(0xFFC8E6C9),
      shadow: Color(0xFF388E3C),
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
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF0288D1),
      outline: Color(0xFFB3E5FC),
      shadow: Color(0xFF0288D1),
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
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFD32F2F),
      outline: Color(0xFFFFCDD2),
      shadow: Color(0xFFD32F2F),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFD32F2F)),
        bodyMedium: TextStyle(color: Color(0xFFD32F2F)),
        bodySmall: TextStyle(color: Color(0xFFFF5252)),
      ),
    ),
  );

  static ThemeData cyberDarkTheme = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8BE9FD), // Neon Cyan
      secondary: Color(0xFFFF79C6), // Magenta Accent
      surface: Color(0xFF1A1B26), // Deep Dark Background
      onPrimary: Color(0xFF1A1B26),
      onSecondary: Color(0xFF1A1B26),
      onSurface: Color(0xFF8BE9FD),
      outline: Color(0xFF2A2E3D),
      shadow: Color(0xFF8BE9FD),
    ),
    scaffoldBackgroundColor: const Color(0xFF1A1B26),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF8BE9FD)),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Color(0xFFFF79C6)),
      ),
    ),
  );

  // New vibrant color themes
  static ThemeData neonPunkTheme = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00FF88), // Neon Green
      secondary: Color(0xFFFF0080), // Hot Pink
      surface: Color(0xFF0A0A0A), // Deep Black
      onPrimary: Color(0xFF0A0A0A),
      onSecondary: Color(0xFF0A0A0A),
      onSurface: Color(0xFF00FF88),
      outline: Color(0xFF1A1A1A),
      shadow: Color(0xFF00FF88),
    ),
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF00FF88)),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Color(0xFFFF0080)),
      ),
    ),
  );

  static ThemeData auroraBorealisTheme = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00D4FF), // Electric Blue
      secondary: Color(0xFF00FFB3), // Mint Green
      surface: Color(0xFF0B1426), // Deep Ocean
      onPrimary: Color(0xFF0B1426),
      onSecondary: Color(0xFF0B1426),
      onSurface: Color(0xFF00D4FF),
      outline: Color(0xFF1A2332),
      shadow: Color(0xFF00D4FF),
    ),
    scaffoldBackgroundColor: const Color(0xFF0B1426),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF00D4FF)),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Color(0xFF00FFB3)),
      ),
    ),
  );

  static ThemeData cosmicVoidTheme = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF9D4EDD), // Cosmic Purple
      secondary: Color(0xFFE0AAFF), // Light Purple
      surface: Color(0xFF10002B), // Deep Space
      onPrimary: Color(0xFF10002B),
      onSecondary: Color(0xFF10002B),
      onSurface: Color(0xFF9D4EDD),
      outline: Color(0xFF240046),
      shadow: Color(0xFF9D4EDD),
    ),
    scaffoldBackgroundColor: const Color(0xFF10002B),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF9D4EDD)),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Color(0xFFE0AAFF)),
      ),
    ),
  );

  static ThemeData electricBlueTheme = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00F5FF), // Electric Cyan
      secondary: Color(0xFF0099CC), // Deep Blue
      surface: Color(0xFF001122), // Midnight Blue
      onPrimary: Color(0xFF001122),
      onSecondary: Colors.white,
      onSurface: Color(0xFF00F5FF),
      outline: Color(0xFF002244),
      shadow: Color(0xFF00F5FF),
    ),
    scaffoldBackgroundColor: const Color(0xFF001122),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF00F5FF)),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Color(0xFF0099CC)),
      ),
    ),
  );

  static ThemeData goldenHourTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFF6B35), // Golden Orange
      secondary: Color(0xFFFFD93D), // Golden Yellow
      surface: Color(0xFFFFF8E1), // Warm Cream
      onPrimary: Colors.white,
      onSecondary: Color(0xFF8B4513),
      onSurface: Color(0xFF8B4513),
      outline: Color(0xFFFFE0B2),
      shadow: Color(0xFFFF6B35),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF8B4513)),
        bodyMedium: TextStyle(color: Color(0xFF8B4513)),
        bodySmall: TextStyle(color: Color(0xFFFF6B35)),
      ),
    ),
  );

  static ThemeData midnightPurpleTheme = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7B2CBF), // Deep Purple
      secondary: Color(0xFFC77DFF), // Light Purple
      surface: Color(0xFF240046), // Dark Purple
      onPrimary: Colors.white,
      onSecondary: Color(0xFF240046),
      onSurface: Color(0xFFC77DFF),
      outline: Color(0xFF3C096C),
      shadow: Color(0xFF7B2CBF),
    ),
    scaffoldBackgroundColor: const Color(0xFF240046),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFC77DFF)),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Color(0xFF7B2CBF)),
      ),
    ),
  );

  static ThemeData tropicalParadiseTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00B894), // Tropical Green
      secondary: Color(0xFF00CEC9), // Turquoise
      surface: Color(0xFFE8F5E8), // Light Green
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF00B894),
      outline: Color(0xFFB8E6B8),
      shadow: Color(0xFF00B894),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF00B894)),
        bodyMedium: TextStyle(color: Color(0xFF00B894)),
        bodySmall: TextStyle(color: Color(0xFF00CEC9)),
      ),
    ),
  );

  static ThemeData arcticFrostTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF74B9FF), // Ice Blue
      secondary: Color(0xFFA29BFE), // Lavender
      surface: Color(0xFFF0F8FF), // Ice White
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF2D3436),
      outline: Color(0xFFDFE6E9),
      shadow: Color(0xFF74B9FF),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF2D3436)),
        bodyMedium: TextStyle(color: Color(0xFF2D3436)),
        bodySmall: TextStyle(color: Color(0xFF74B9FF)),
      ),
    ),
  );

  static ThemeData pureBlackTheme = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF6B35), // Simple orange
      secondary: Color(0xFFFF8A65), // Lighter orange
      surface: Color(0xFF000000),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      outline: Color(0xFF333333),
      shadow: Color(0xFFE65100),
    ),
    scaffoldBackgroundColor: const Color(0xFF000000),
    cardColor: const Color(0xFF1A1A1A),
    canvasColor: const Color(0xFF000000),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF1A1A1A),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1A1A1A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Color(0xFFE65100),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Color(0xFFE65100)),
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
    AppTheme.cyberDark: cyberDarkTheme,
    AppTheme.neonPunk: neonPunkTheme,
    AppTheme.auroraBorealis: auroraBorealisTheme,
    AppTheme.cosmicVoid: cosmicVoidTheme,
    AppTheme.electricBlue: electricBlueTheme,
    AppTheme.goldenHour: goldenHourTheme,
    AppTheme.midnightPurple: midnightPurpleTheme,
    AppTheme.tropicalParadise: tropicalParadiseTheme,
    AppTheme.arcticFrost: arcticFrostTheme,
    AppTheme.pureBlack: pureBlackTheme,
  };
}

// Additional color utilities for enhanced UI
class AppColors {
  // Gradient colors for backgrounds
  static const List<Color> cyberGradient = [
    Color(0xFF8BE9FD),
    Color(0xFFFF79C6),
    Color(0xFFBD93F9),
  ];

  static const List<Color> neonGradient = [
    Color(0xFF00FF88),
    Color(0xFFFF0080),
    Color(0xFF00F5FF),
  ];

  static const List<Color> auroraGradient = [
    Color(0xFF00D4FF),
    Color(0xFF00FFB3),
    Color(0xFF9D4EDD),
  ];

  static const List<Color> sunsetGradient = [
    Color(0xFFFF6B35),
    Color(0xFFFFD93D),
    Color(0xFFFF79C6),
  ];

  static const List<Color> blackGradient = [
    Color(0xFF000000),
    Color(0xFF333333),
    Color(0xFF666666),
  ];

  static const List<Color> blackOrangeGradient = [
    Color(0xFF000000),
    Color(0xFFE65100),
    Color(0xFFFF9800),
  ];

  // Accent colors for highlights
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color hotPink = Color(0xFFFF0080);
  static const Color electricCyan = Color(0xFF00F5FF);
  static const Color cosmicPurple = Color(0xFF9D4EDD);
  static const Color goldenOrange = Color(0xFFFF6B35);
  static const Color tropicalGreen = Color(0xFF00B894);
  static const Color iceBlue = Color(0xFF74B9FF);
  static const Color pureBlack = Color(0xFF000000);
  static const Color deepOrange = Color(0xFFE65100);

  // Utility colors
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBlack = Color(0x1A000000);
  static const Color glassPrimary = Color(0x1A8BE9FD);
  static const Color glassSecondary = Color(0x1AFF79C6);
}
