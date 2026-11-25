import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';



import 'package:flutter/material.dart';

import 'constants/app_colors.dart';
import 'constants/app_constants.dart';
import 'screens/home_screen.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await loadThemeMode();
  runApp(ValueListenableBuilder<ThemeMode>(
    valueListenable: appThemeMode,
    builder: (context, mode, child) => MyApp(),
  ));
}

/// Root application widget configuring Material 3 theme and offline typography.
class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: appThemeMode.value,
      darkTheme: darkAppTheme(),
      builder: (context, child) => Stack(children: [
        child!,
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(appThemeMode.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: toggleThemeMode,
            ),
          ),
        ),
      ]),
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.accent,
          onSecondary: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
          onError: Colors.white,
        ),
        // Offline typography fallback: system Bengali & Latin fonts
        fontFamilyFallback: const [
          'Hind Siliguri',
          'Poppins',
          'Roboto',
          'Noto Sans Bengali',
          'Segoe UI',
          'sans-serif',
        ],
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
          bodySmall: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            side: BorderSide(color: AppColors.cardBorder),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: Size.fromHeight(AppConstants.minTapTargetSize),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size.fromHeight(AppConstants.minTapTargetSize),
            side: BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}
