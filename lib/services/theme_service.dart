import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

/// Current theme mode. main.dart er ValueListenableBuilder eita shunbe.
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

/// App shuru holei shesh pasand load korbe.
Future<void> loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  AppColors.isDark = isDark;
  appThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
}

/// Light <-> Dark toggle, pasand save kore rakhe.
Future<void> toggleThemeMode() async {
  final isDark = appThemeMode.value != ThemeMode.dark;
  AppColors.isDark = isDark;
  appThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('dark_mode', isDark);
}

ThemeData darkAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
    ),
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
    ),
  );
}