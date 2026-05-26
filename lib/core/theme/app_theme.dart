import 'package:flutter/material.dart';

const Color _lightBackground = Color(0xFFFFFFFF);
const Color _lightSurface = Color(0xFFF5F5F5);
const Color _lightPrimary = Color(0xFF000000);
const Color _lightText = Color(0xFF1A1A1A);
const Color _lightMuted = Color(0xFF6B6B6B);
const Color _lightBorder = Color(0xFFE0E0E0);

const Color _darkBackground = Color(0xFF0A0A0A);
const Color _darkSurface = Color(0xFF1A1A1A);
const Color _darkPrimary = Color(0xFFFFFFFF);
const Color _darkText = Color(0xFFF0F0F0);
const Color _darkMuted = Color(0xFF9E9E9E);
const Color _darkBorder = Color(0xFF2A2A2A);

ThemeData buildLightTheme() {
  const scheme = ColorScheme.light(
    primary: _lightPrimary,
    secondary: _lightPrimary,
    surface: _lightSurface,
    onPrimary: _lightBackground,
    onSecondary: _lightBackground,
    onSurface: _lightText,
    error: Color(0xFF4A4A4A),
    onError: _lightBackground,
    outline: _lightBorder,
  );

  return ThemeData.light(useMaterial3: true).copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: _lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackground,
      foregroundColor: _lightText,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: _lightSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _lightBorder, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: _lightBorder, thickness: 1),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _lightSurface,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: _lightBorder, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _lightBorder, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _lightPrimary, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _lightText),
      bodyMedium: TextStyle(color: _lightText),
      bodySmall: TextStyle(color: _lightMuted),
      titleLarge: TextStyle(color: _lightText),
      titleMedium: TextStyle(color: _lightText),
      titleSmall: TextStyle(color: _lightText),
    ),
  );
}

ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: _darkPrimary,
    secondary: _darkPrimary,
    surface: _darkSurface,
    onPrimary: _darkBackground,
    onSecondary: _darkBackground,
    onSurface: _darkText,
    error: Color(0xFFBDBDBD),
    onError: _darkBackground,
    outline: _darkBorder,
  );

  return ThemeData.dark(useMaterial3: true).copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: _darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackground,
      foregroundColor: _darkText,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: _darkSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _darkBorder, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: _darkBorder, thickness: 1),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: _darkBorder, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _darkBorder, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _darkPrimary, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _darkText),
      bodyMedium: TextStyle(color: _darkText),
      bodySmall: TextStyle(color: _darkMuted),
      titleLarge: TextStyle(color: _darkText),
      titleMedium: TextStyle(color: _darkText),
      titleSmall: TextStyle(color: _darkText),
    ),
  );
}