import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightTheme = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Colors.black,
    secondary: Color(0xFF7AA2F7),
    surface: Colors.white,
    secondaryFixed: Colors.black,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(
    const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
      bodySmall: TextStyle(color: Colors.black),
    ),
  ),
);

ThemeData darkTheme = ThemeData(
  colorScheme: const ColorScheme.dark(
    primary: Colors.white,
    secondary: Color(0xFF7AA2F7),
    surface: Color(0xFF1F2335),
    secondaryFixed: Colors.white,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(
    const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white),
    ),
  ),
);
