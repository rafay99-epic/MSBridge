import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightTheme = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Colors.white,
    secondary: Color(0xFF7AA2F7),
    surface: Color(0xFF1F2335),
    secondaryFixed: Colors.black,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(
    const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white),
    ),
  ),
);
