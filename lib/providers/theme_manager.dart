import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Manages the app’s theme (light or dark) and saves user preference.
class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  // Constructor automatically loads the saved theme.
  ThemeManager() {
    _loadTheme();
  }

  // Loads the saved theme preference from local storage.
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Switches between dark and light mode and updates the saved preference.
  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', isDark);
    notifyListeners();
  }
}
