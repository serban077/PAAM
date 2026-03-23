import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeService — persists and notifies dark/light mode preference
class ThemeService {
  static const String _key = 'dark_mode';
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  /// Load persisted preference at app startup
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_key) ?? false;
      themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      // Non-critical — keep light mode default
    }
  }

  /// Toggle dark/light mode and persist the preference
  static Future<void> setDarkMode(bool isDark) async {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, isDark);
    } catch (_) {}
  }

  static bool get isDark => themeNotifier.value == ThemeMode.dark;
}
