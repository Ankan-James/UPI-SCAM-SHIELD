import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xFF101B3D);
  static const blue = Color(0xFF4361EE);
  static const violet = Color(0xFF806BFF);
  static const background = Color(0xFFF7F9FC);
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const muted = Color(0xFF68738C);
  static const border = Color(0xFFE6EAF2);
}

abstract final class AppSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
      primary: AppColors.blue,
      secondary: AppColors.violet,
      surface: Colors.white,
      error: AppColors.red,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.navy,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0x1A4361EE),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.blue : AppColors.muted,
          );
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0x1A4361EE),
        selectedIconTheme: IconThemeData(color: AppColors.blue),
        unselectedIconTheme: IconThemeData(color: AppColors.muted),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.blue,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(color: AppColors.muted),
      ),
      dividerColor: AppColors.border,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.navy, height: 1.45),
        bodyMedium: TextStyle(color: AppColors.muted, height: 1.45),
      ),
    );
  }
}