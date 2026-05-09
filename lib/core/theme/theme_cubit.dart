import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Possible theme modes
enum SawaTheme { system, dark, light }

@singleton
class ThemeCubit extends Cubit<ThemeMode> {
  static const String _key = 'sawa_theme_mode';

  ThemeCubit() : super(ThemeMode.system);

  // Call this in main.dart after configureDependencies()
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    switch (saved) {
      case 'dark':
        emit(ThemeMode.dark);
      case 'light':
        emit(ThemeMode.light);
      default:
        emit(ThemeMode.system); // First install = follow device
    }
  }

  Future<void> setDark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, 'dark');
    emit(ThemeMode.dark);
  }

  Future<void> setLight() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, 'light');
    emit(ThemeMode.light);
  }

  Future<void> setSystem() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, 'system');
    emit(ThemeMode.system);
  }

  // Returns the current saved string for display in UI
  String get currentLabel {
    switch (state) {
      case ThemeMode.dark:   return 'Dark';
      case ThemeMode.light:  return 'Light';
      case ThemeMode.system: return 'System default';
    }
  }
}
