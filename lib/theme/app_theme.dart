import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFF4A438);
  static const okButton = Color(0xFFF06060);
  static const acButton = Color(0xFF5BC8C0);
  static const numKey = Colors.white;
  static const expense = Color(0xFFF4A438);
  static const income = Color(0xFF4A90D9);
  static const background = Color(0xFFF5F5F5);
  static const card = Colors.white;
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF9E9E9E);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      );
}
