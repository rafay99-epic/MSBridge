import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightTheme = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Colors.black, // Changed to black for light mode
    secondary: Color(0xFF7AA2F7),
    surface: Colors.white, // Changed to white for light mode
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
    primary: Colors.white, // White text for dark mode
    secondary: Color(0xFF7AA2F7),
    surface: Color(0xFF1F2335), // Dark background for dark mode
    secondaryFixed: Colors.white,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(
    const TextTheme(
      bodyLarge: TextStyle(color: Colors.white), //White Text for dark mode
      bodyMedium: TextStyle(color: Colors.white), //White Text for dark mode
      bodySmall: TextStyle(color: Colors.white), //White Text for dark mode
    ),
  ),
);
