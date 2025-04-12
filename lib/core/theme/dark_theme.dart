import 'package:flutter/material.dart';

final darkThemeData = ThemeData(
  primaryColor: const Color(0xFF1DB954),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1DB954),
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  cardColor: const Color(0xFF212121),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Color(0xFF121212),
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF121212),
    selectedItemColor: Color(0xFF1DB954),
    unselectedItemColor: Colors.grey,
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  ),
  useMaterial3: true,
);
