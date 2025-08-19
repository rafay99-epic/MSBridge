import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
      family: 'Open Sans',
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
      category: 'Google Fonts',
      isDefault: false,
    ),
    FontOption(
      name: 'Work Sans',
      family: 'Work Sans',
      category: 'Google Fonts',
      isDefault: false,
    ),
    FontOption(
      name: 'Nunito',
      family: 'Nunito',
      category: 'Google Fonts',
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
      String fontFamily = prefs.getString(_fontKey) ?? 'Poppins';

      // Fix old font family names that might be stored incorrectly
      if (fontFamily == 'OpenSans') {
        fontFamily = 'Open Sans';
      } else if (fontFamily == 'JetBrainsMono') {
        fontFamily = 'JetBrains Mono';
      } else if (fontFamily == 'PlayfairDisplay') {
        fontFamily = 'Playfair Display';
      } else if (fontFamily == 'SF Pro Display') {
        fontFamily = 'Roboto'; // Fallback to Roboto for iOS font
      }

      _selectedFontFamily = fontFamily;
      notifyListeners();
    } catch (e) {
      _selectedFontFamily = 'Poppins';
      FirebaseCrashlytics.instance
          .recordError(e, StackTrace.current, reason: 'Failed to load font');
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
      FirebaseCrashlytics.instance
          .recordError(e, StackTrace.current, reason: 'Failed to save font');
    }
  }

  // Get the current font as a TextStyle using specific Google Fonts methods
  TextStyle getCurrentFont({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    try {
      TextStyle textStyle;

      switch (_selectedFontFamily) {
        case 'Poppins':
          textStyle = GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
          break;
        case 'Inter':
          textStyle = GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
          break;
        case 'Open Sans':
          textStyle = GoogleFonts.openSans(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
          break;
        case 'Lato':
          textStyle = GoogleFonts.lato(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
          break;
        case 'Montserrat':
          textStyle = GoogleFonts.montserrat(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
          break;
        case 'Roboto':
          textStyle = GoogleFonts.roboto(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
          break;
        case 'Work Sans':
          textStyle = GoogleFonts.workSans(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
          break;
        case 'Nunito':
          textStyle = GoogleFonts.nunito(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
          break;
        default:
          // Fallback to Poppins if unknown font
          textStyle = GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
      }

      return textStyle;
    } catch (e) {
      // Fallback to system font with font family name if Google Fonts fails
      // This will use the system's version of the font if available
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        fontFamily: _selectedFontFamily,
      );
    }
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

  // Get a preview TextStyle for a specific font (for font selection UI)
  TextStyle getPreviewTextStyle(
    String fontFamily, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    try {
      switch (fontFamily) {
        case 'Poppins':
          return GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
        case 'Inter':
          return GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
        case 'Open Sans':
          return GoogleFonts.openSans(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
        case 'Lato':
          return GoogleFonts.lato(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
        case 'Montserrat':
          return GoogleFonts.montserrat(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
        case 'Roboto':
          return GoogleFonts.roboto(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
        case 'Work Sans':
          return GoogleFonts.workSans(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
        case 'Nunito':
          return GoogleFonts.nunito(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
        default:
          return GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
      }
    } catch (e) {
      // Return a basic TextStyle with font family if Google Fonts fails
      // This will use the system's version of the font if available
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        fontFamily: fontFamily,
      );
    }
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
