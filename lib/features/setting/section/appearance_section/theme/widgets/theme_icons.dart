import 'package:flutter/material.dart';
import 'package:msbridge/theme/colors.dart';

class ThemeIcons {
  static IconData getThemeIcon(AppTheme appTheme) {
    switch (appTheme) {
      case AppTheme.light:
        return Icons.wb_sunny;
      case AppTheme.dark:
        return Icons.nightlight_round;
      case AppTheme.purpleHaze:
        return Icons.palette;
      case AppTheme.mintFresh:
        return Icons.eco;
      case AppTheme.midnightBlue:
        return Icons.nightlight_round;
      case AppTheme.sunsetGlow:
        return Icons.wb_sunny_outlined;
      case AppTheme.forestGreen:
        return Icons.forest;
      case AppTheme.oceanWave:
        return Icons.water;
      case AppTheme.crimsonBlush:
        return Icons.favorite;
      case AppTheme.cyberDark:
        return Icons.computer;
      case AppTheme.neonPunk:
        return Icons.electric_bolt;
      case AppTheme.auroraBorealis:
        return Icons.auto_awesome;
      case AppTheme.cosmicVoid:
        return Icons.space_bar;
      case AppTheme.electricBlue:
        return Icons.flash_on;
      case AppTheme.goldenHour:
        return Icons.wb_sunny;
      case AppTheme.midnightPurple:
        return Icons.palette;
      case AppTheme.tropicalParadise:
        return Icons.beach_access;
      case AppTheme.arcticFrost:
        return Icons.ac_unit;
    }
  }
}
