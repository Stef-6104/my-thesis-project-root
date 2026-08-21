import 'package:flutter/material.dart';

class AppColors {
  static const Color mainBackground = Color(0xFF1B1B1B);
  static const Color secondaryDark = Color(0xFF202022);
  static const Color pastelYellow = Color(0xFFFFEE8C);
  static const Color lightYellow = Color(0xFFFFFFC5);
  static const Color darkGray = Color(0xFF4A4A4A);
  static const Color cascadingWhite = Color(0xFFF6F6F6);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.mainBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.lightYellow,
        secondary: AppColors.pastelYellow,
        surface: AppColors.secondaryDark,
        onSurface: AppColors.cascadingWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.mainBackground,
        foregroundColor: AppColors.cascadingWhite,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.secondaryDark,
        selectedItemColor: AppColors.cascadingWhite,
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightYellow,
        foregroundColor: Colors.black,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
