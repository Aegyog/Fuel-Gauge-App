import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_manager.dart';
import 'screens/main_navigation.dart';
import 'utils/constants.dart';

// Entry point
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: const FuelTrackerApp(),
    ),
  );
}

// Main app - theme management
class FuelTrackerApp extends StatelessWidget {
  const FuelTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: 'FuelGauge',
          themeMode: themeManager.themeMode,
          // --- Light Theme Definition ---
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: kLightScaffoldBackgroundColor,
            primaryColor: kAccentColor,
            fontFamily: 'Inter',
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: kPrimaryTextColorLight),
              bodyMedium: TextStyle(color: kPrimaryTextColorLight),
              headlineLarge: TextStyle(
                  color: kPrimaryTextColorLight, fontWeight: FontWeight.bold),
              titleLarge: TextStyle(color: kPrimaryTextColorLight),
            ),
            cardTheme: CardThemeData(
              elevation: 1,
              color: kLightCardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[200],
              hintStyle: const TextStyle(color: kSecondaryTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: kLightCardBackgroundColor,
              selectedItemColor: kAccentColor,
              unselectedItemColor: kSecondaryTextColor,
              elevation: 2,
            ),
          ),
          // --- Dark Theme Definition ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: kDarkScaffoldBackgroundColor,
            primaryColor: kAccentColor,
            fontFamily: 'Inter',
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: kPrimaryTextColorDark),
              bodyMedium: TextStyle(color: kPrimaryTextColorDark),
              headlineLarge: TextStyle(
                  color: kPrimaryTextColorDark, fontWeight: FontWeight.bold),
              titleLarge: TextStyle(color: kPrimaryTextColorDark),
            ),
            cardTheme: CardThemeData(
              color: kDarkCardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: kDarkCardBackgroundColor,
              hintStyle: const TextStyle(color: kSecondaryTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: kDarkCardBackgroundColor,
              selectedItemColor: kAccentColor,
              unselectedItemColor: kSecondaryTextColor,
            ),
          ),
          home: const MainNavigation(),
        );
      },
    );
  }
}
