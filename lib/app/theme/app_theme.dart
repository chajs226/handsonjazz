import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1E1E2E);
  static const Color secondaryColor = Color(0xFF89B4FA);
  static const Color accentColor = Color(0xFFF9E2AF);
  static const Color backgroundColor = Color(0xFF181825);
  static const Color surfaceColor = Color(0xFF313244);
  static const Color whiteKeyColor = Color(0xFFF5F5DC);
  static const Color blackKeyColor = Color(0xFF2D2D2D);
  static const Color activeKeyColor = Color(0xFF89B4FA);
  static const Color leftHandColor = Color(0xFF94E2D5);
  static const Color rightHandColor = Color(0xFFF9E2AF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: secondaryColor,
        thumbColor: accentColor,
        inactiveTrackColor: Colors.grey,
      ),
    );
  }
}
