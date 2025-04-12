import 'package:flutter/material.dart';

final themeData = ThemeData(
  primaryColor: const Color(0xFF1DB954),
  // Spotify-like green
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1DB954),
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: Colors.white,
  cardColor: Colors.white,
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Color(0xFF1DB954),
    unselectedItemColor: Colors.grey,
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w500,
    ),
  ),
  useMaterial3: true,
);
