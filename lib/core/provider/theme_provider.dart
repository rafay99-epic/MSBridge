import 'package:flutter/material.dart';
import 'package:msbridge/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'appTheme';

  AppTheme _selectedTheme = AppTheme.dark;

  AppTheme get selectedTheme => _selectedTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? themeName = prefs.getString(_themeKey);
      _selectedTheme = _themeFromString(themeName);
    } catch (e) {
      _selectedTheme = AppTheme.dark;
    }
    notifyListeners();
  }

  AppTheme _themeFromString(String? themeName) {
    if (themeName == null) {
      return AppTheme.dark;
    }

    for (AppTheme theme in AppTheme.values) {
      if (theme.name == themeName) {
        return theme;
      }
    }

    return AppTheme.dark;
  }

  Future<void> setTheme(AppTheme theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
    _selectedTheme = theme;
    notifyListeners();
  }

  ThemeData getThemeData() {
    return AppThemes.themeMap[_selectedTheme]!;
  }
}
