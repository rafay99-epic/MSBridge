// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:msbridge/theme/colors.dart';
import 'package:msbridge/core/models/custom_color_scheme_model.dart';
import 'package:msbridge/core/repo/custom_color_scheme_repo.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'appTheme';
  static const String _dynamicColorsKey = 'dynamicColors';

  AppTheme _selectedTheme = AppTheme.dark;
  bool _dynamicColorsEnabled = false;

  // Custom color scheme support
  CustomColorSchemeModel? _customColorScheme;
  bool _isCustomTheme = false;
  final CustomColorSchemeRepo _customColorRepo = CustomColorSchemeRepo.instance;

  // Cache ThemeData to avoid recomputation
  ThemeData? _cachedThemeData;
  AppTheme? _lastSelectedTheme;
  bool? _lastDynamicColorsEnabled;
  CustomColorSchemeModel? _lastCustomColorScheme;

  AppTheme get selectedTheme => _selectedTheme;
  bool get dynamicColorsEnabled => _dynamicColorsEnabled;
  CustomColorSchemeModel? get customColorScheme => _customColorScheme;
  bool get isCustomTheme => _isCustomTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? themeName = prefs.getString(_themeKey);
      bool? dynamicColors = prefs.getBool(_dynamicColorsKey);
      bool? isCustomTheme = prefs.getBool('isCustomTheme');

      _selectedTheme = _themeFromString(themeName);
      _dynamicColorsEnabled = dynamicColors ?? false;
      _isCustomTheme = isCustomTheme ?? false;

      // Load custom color scheme if active
      if (_isCustomTheme) {
        _customColorScheme = await _customColorRepo.getActiveScheme();
        if (_customColorScheme == null) {
          // If no active custom scheme found, fall back to regular theme
          _isCustomTheme = false;
          await prefs.setBool('isCustomTheme', false);
        }
      }
    } catch (e) {
      _selectedTheme = AppTheme.dark;
      _dynamicColorsEnabled = false;
      _isCustomTheme = false;
      FlutterBugfender.sendCrash(
          'Error loading theme: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error loading theme: $e',
      );
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
    if (_dynamicColorsEnabled) {
      FlutterBugfender.log(
          'Cannot set custom theme when dynamic colors are enabled');
      return;
    }

    // Clear custom theme when switching to regular theme
    _isCustomTheme = false;
    _customColorScheme = null;
    _selectedTheme = theme;
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.name);
      await prefs.setBool('isCustomTheme', false);
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to set theme: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to set theme: $e',
      );
    }
  }

  Future<void> setDynamicColors(bool enabled) async {
    _dynamicColorsEnabled = enabled;

    if (enabled) {
      _selectedTheme = AppTheme.dark;
      _isCustomTheme = false;
      _customColorScheme = null;
    }

    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dynamicColorsKey, enabled);
      if (enabled) {
        await prefs.setString(_themeKey, AppTheme.dark.name);
        await prefs.setBool('isCustomTheme', false);
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to set dynamic colors: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to set dynamic colors: $e',
      );
    }
  }

  ThemeData getThemeData() {
    // Check if we can use cached ThemeData
    if (_cachedThemeData != null &&
        _lastSelectedTheme == _selectedTheme &&
        _lastDynamicColorsEnabled == _dynamicColorsEnabled &&
        _lastCustomColorScheme == _customColorScheme) {
      return _cachedThemeData!;
    }

    ThemeData themeData;

    if (_isCustomTheme && _customColorScheme != null) {
      // Use custom color scheme
      themeData = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _customColorScheme!.primary,
          brightness: _isDarkTheme ? Brightness.dark : Brightness.light,
          primary: _customColorScheme!.primary,
          secondary: _customColorScheme!.secondary,
          surface: _customColorScheme!.background,
          onPrimary: _getContrastColor(_customColorScheme!.primary),
          onSecondary: _getContrastColor(_customColorScheme!.secondary),
          onSurface: _customColorScheme!.textColor,
        ).copyWith(
          onSurface: _customColorScheme!.textColor,
        ),
        textTheme: AppThemes.themeMap[_selectedTheme]!.textTheme.copyWith(
          bodyLarge: TextStyle(color: _customColorScheme!.textColor),
          bodyMedium: TextStyle(color: _customColorScheme!.textColor),
          bodySmall: TextStyle(color: _customColorScheme!.textColor),
          titleLarge: TextStyle(color: _customColorScheme!.textColor),
          titleMedium: TextStyle(color: _customColorScheme!.textColor),
          titleSmall: TextStyle(color: _customColorScheme!.textColor),
        ),
      );
    } else if (_dynamicColorsEnabled) {
      // Use a custom dynamic color theme that simulates Material You
      themeData = ThemeData(
        useMaterial3: true,
        colorScheme: _generateDynamicColorScheme(),
        // Apply some custom styling while keeping dynamic colors
        textTheme: AppThemes.themeMap[_selectedTheme]!.textTheme,
      );
    } else {
      themeData = AppThemes.themeMap[_selectedTheme]!;
    }

    // Cache the result
    _cachedThemeData = themeData;
    _lastSelectedTheme = _selectedTheme;
    _lastDynamicColorsEnabled = _dynamicColorsEnabled;
    _lastCustomColorScheme = _customColorScheme;

    return themeData;
  }

  // Generate a dynamic color scheme that simulates Material You
  ColorScheme _generateDynamicColorScheme() {
    final isDark = _selectedTheme == AppTheme.dark;

    if (isDark) {
      // Dark dynamic theme with vibrant accents
      return const ColorScheme.dark(
        primary: Color(0xFF81C784), // Green accent
        onPrimary: Colors.black,
        secondary: Color(0xFFFFB74D), // Orange accent
        onSecondary: Colors.black,
        surface: Color(0xFF121212), // Dark surface
        onSurface: Colors.white,
        error: Color(0xFFE57373), // Red accent
        onError: Colors.black,
        outline: Color(0xFF424242),
        shadow: Colors.black,
      );
    } else {
      // Light dynamic theme with warm colors
      return const ColorScheme.light(
        primary: Color(0xFF4CAF50), // Green primary
        onPrimary: Colors.white,
        secondary: Color(0xFFFF9800), // Orange secondary
        onSecondary: Colors.white,
        surface: Color(0xFFFAFAFA), // Light surface
        onSurface: Colors.black87,
        error: Color(0xFFF44336), // Red error
        onError: Colors.white,
        outline: Color(0xFFE0E0E0),
        shadow: Colors.black12,
      );
    }
  }

  // Helper method to determine if current theme is dark
  bool get _isDarkTheme {
    if (_isCustomTheme && _customColorScheme != null) {
      // Determine brightness based on background color luminance
      return _customColorScheme!.background.computeLuminance() < 0.5;
    }
    return _selectedTheme == AppTheme.dark;
  }

  // Helper method to get contrast color (black or white)
  Color _getContrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  String get currentImagePath {
    if (_dynamicColorsEnabled) {
      return 'assets/svg/dynamic_colors.svg';
    }
    return _selectedTheme.imagePath();
  }

  Future<void> resetTheme() async {
    // Update state immediately and notify listeners
    _selectedTheme = AppTheme.dark;
    _dynamicColorsEnabled = false;
    notifyListeners();

    // Persist to disk asynchronously to avoid blocking UI
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
      await prefs.remove(_dynamicColorsKey);
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to reset theme: $e', StackTrace.current.toString());
    }
  }

  // Check if a theme can be selected (disabled when dynamic colors are on)
  bool canSelectTheme(AppTheme theme) {
    return !_dynamicColorsEnabled;
  }

  // Get the current effective theme name for display
  String get effectiveThemeName {
    if (_isCustomTheme && _customColorScheme != null) {
      return _customColorScheme!.name;
    }
    if (_dynamicColorsEnabled) {
      return 'Dynamic Colors';
    }
    return _selectedTheme.name;
  }

  // Custom Color Scheme Management Methods

  /// Set a custom color scheme as active
  Future<bool> setCustomColorScheme(CustomColorSchemeModel scheme) async {
    try {
      _customColorScheme = scheme;
      _isCustomTheme = true;
      notifyListeners();

      // Save to local storage
      await _customColorRepo.setActiveScheme(scheme);

      // Update SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isCustomTheme', true);

      return true;
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to set custom color scheme: $e',
          StackTrace.current.toString());

      return false;
    }
  }

  /// Create a new custom color scheme
  Future<CustomColorSchemeModel?> createCustomColorScheme({
    required String name,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color textColor,
  }) async {
    try {
      final scheme = await _customColorRepo.createScheme(
        name: name,
        primary: primary,
        secondary: secondary,
        background: background,
        textColor: textColor,
      );

      if (scheme != null) {
        await setCustomColorScheme(scheme);
      }

      return scheme;
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to create custom color scheme: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to create custom color scheme: $e',
      );
      return null;
    }
  }

  /// Update an existing custom color scheme
  Future<bool> updateCustomColorScheme(CustomColorSchemeModel scheme) async {
    try {
      final success = await _customColorRepo.updateScheme(scheme);

      if (success && _isCustomTheme && _customColorScheme?.id == scheme.id) {
        _customColorScheme = scheme;
        notifyListeners();
      }

      return success;
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to update custom color scheme: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to update custom color scheme: $e',
      );
      return false;
    }
  }

  /// Delete a custom color scheme
  Future<bool> deleteCustomColorScheme(CustomColorSchemeModel scheme) async {
    try {
      final success = await _customColorRepo.deleteScheme(scheme);

      if (success) {
        // Clean up any orphaned data
        await _customColorRepo.cleanupOrphanedData();

        if (_isCustomTheme && _customColorScheme?.id == scheme.id) {
          // If deleting the active scheme, fall back to default theme
          // Clear custom theme state first
          _customColorScheme = null;
          _isCustomTheme = false;

          // Update SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isCustomTheme', false);

          // Notify listeners after state is fully updated
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to delete custom color scheme: $e',
          StackTrace.current.toString());
      return false;
    }
  }

  /// Get all custom color schemes
  Future<List<CustomColorSchemeModel>> getCustomColorSchemes() async {
    try {
      return await _customColorRepo.loadLocalSchemes();
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to get custom color schemes: $e',
          StackTrace.current.toString());
      return [];
    }
  }

  /// Sync custom color schemes to Firebase
  Future<bool> syncCustomColorSchemesToFirebase() async {
    try {
      return await _customColorRepo.syncAllToFirebase();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to sync custom color schemes to Firebase: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to sync custom color schemes to Firebase: $e',
      );
      return false;
    }
  }

  /// Sync custom color schemes from Firebase
  Future<bool> syncCustomColorSchemesFromFirebase() async {
    try {
      return await _customColorRepo.syncFromFirebase();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to sync custom color schemes from Firebase: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to sync custom color schemes from Firebase: $e',
      );
      return false;
    }
  }

  /// Clear custom theme and fall back to regular theme
  Future<void> clearCustomTheme() async {
    try {
      _isCustomTheme = false;
      _customColorScheme = null;
      notifyListeners();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isCustomTheme', false);
      await _customColorRepo.setActiveScheme(null);
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to clear custom theme: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to clear custom theme: $e',
      );
    }
  }
}
