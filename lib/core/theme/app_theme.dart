import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color teal = Color(0xFF00897B);
  static const Color tealDark = Color(0xFF00695C);
  static const Color orange = Color(0xFFFF7043);
  static const Color background = Color(0xFFFAFAFA);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.light,
    ).copyWith(secondary: AppColors.orange, primary: AppColors.teal);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.teal),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.orange.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.orange
                : Colors.grey,
          ),
        ),
      ),
    );
  }
}
