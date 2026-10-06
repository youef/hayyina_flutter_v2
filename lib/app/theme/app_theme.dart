import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primary = Color(0xFF0EA5A4);
  static const _ink = Color(0xFF0F172A);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _primary, brightness: Brightness.light),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    textTheme: GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme).apply(bodyColor: _ink, displayColor: _ink),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0, backgroundColor: Colors.transparent, foregroundColor: _ink),
    cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _primary, brightness: Brightness.dark),
    textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
    cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
  );
}
