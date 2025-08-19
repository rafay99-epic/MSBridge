import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider extends ChangeNotifier {
  static const String _fontKey = 'selected_font_family';
  
  // Curated list of popular, readable fonts
  static const List<FontOption> availableFonts = [
    FontOption(
      name: 'Poppins',
      family: 'Poppins',
      category: 'Google Fonts',
      isDefault: true,
    ),
    FontOption(
      name: 'Inter',
      family: 'Inter',
      category: 'Google Fonts',
      isDefault: false,
    ),
    FontOption(
      name: 'Open Sans',
      family: 'OpenSans',
      category: 'Google Fonts',
      isDefault: false,
    ),
    FontOption(
      name: 'Lato',
      family: 'Lato',
      category: 'Google Fonts',
      isDefault: false,
    ),
    FontOption(
      name: 'Montserrat',
      family: 'Montserrat',
      category: 'Google Fonts',
      isDefault: false,
    ),
    FontOption(
      name: 'Roboto',
      family: 'Roboto',
      category: 'System',
      isDefault: false,
    ),
    FontOption(
      name: 'SF Pro',
      family: 'SF Pro Display',
      category: 'System',
      isDefault: false,
    ),
    FontOption(
      name: 'JetBrains Mono',
      family: 'JetBrainsMono',
      category: 'Monospace',
      isDefault: false,
    ),
    FontOption(
      name: 'Playfair Display',
      family: 'PlayfairDisplay',
      category: 'Display',
      isDefault: false,
    ),
    FontOption(
      name: 'Merriweather',
      family: 'Merriweather',
      category: 'Display',
      isDefault: false,
    ),
  ];

  String _selectedFontFamily = 'Poppins';
  String get selectedFontFamily => _selectedFontFamily;

  FontProvider() {
    _loadFont();
  }

  Future<void> _loadFont() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedFontFamily = prefs.getString(_fontKey) ?? 'Poppins';
      notifyListeners();
    } catch (e) {
      // Keep default font if loading fails
      _selectedFontFamily = 'Poppins';
    }
  }

  Future<void> setFont(String fontFamily) async {
    if (_selectedFontFamily == fontFamily) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontKey, fontFamily);
      _selectedFontFamily = fontFamily;
      notifyListeners();
    } catch (e) {
      // Handle error silently or log to Crashlytics
      debugPrint('Failed to save font selection: $e');
    }
  }

  // Get the current font as a TextStyle
  TextStyle getCurrentFont({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.getFont(
      _selectedFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // Get current font for body text
  TextStyle get bodyText => getCurrentFont(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  // Get current font for headings
  TextStyle get headingText => getCurrentFont(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  // Get current font for small text
  TextStyle get smallText => getCurrentFont(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  // Get current font for large text
  TextStyle get largeText => getCurrentFont(
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  // Reset to default font
  Future<void> resetToDefault() async {
    await setFont('Poppins');
  }

  // Get font by name
  FontOption? getFontByName(String name) {
    try {
      return availableFonts.firstWhere((font) => font.name == name);
    } catch (e) {
      return null;
    }
  }

  // Get current font option
  FontOption get currentFontOption {
    return availableFonts.firstWhere(
      (font) => font.family == _selectedFontFamily,
      orElse: () => availableFonts.first,
    );
  }
}

// Font option model
class FontOption {
  final String name;
  final String family;
  final String category;
  final bool isDefault;

  const FontOption({
    required this.name,
    required this.family,
    required this.category,
    this.isDefault = false,
  });

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontOption &&
          runtimeType == other.runtimeType &&
          family == other.family;

  @override
  int get hashCode => family.hashCode;
}
