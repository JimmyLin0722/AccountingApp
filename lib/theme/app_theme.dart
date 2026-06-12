import 'package:flutter/material.dart';

class AppColors {
  static const background  = Color(0xFF0D1117);
  static const surface     = Color(0xFF161B22);
  static const surfaceHigh = Color(0xFF1C2333);
  static const expense     = Color(0xFFFF4772);
  static const income      = Color(0xFF00F5D4);
  static const accent      = Color(0xFF7000FF);
  static const textPrimary = Color(0xFFE6EDF3);
  static const textGrey    = Color(0xFF8B949E);
  // backward-compat aliases
  static const primary  = expense;
  static const okButton = accent;
  static const acButton = income;
  static const textDark = textPrimary;
  static const card     = surface;
  static const numKey   = surfaceHigh;
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.income,
          surface: AppColors.surface,
          error: AppColors.expense,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: AppColors.surfaceHigh,
          textStyle: TextStyle(color: AppColors.textPrimary),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.surfaceHigh,
          contentTextStyle: TextStyle(color: AppColors.textPrimary),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: AppColors.textGrey),
          hintStyle: TextStyle(color: AppColors.textGrey),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.surfaceHigh),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.accent, width: 2),
          ),
          prefixIconColor: AppColors.textGrey,
        ),
      );
}
