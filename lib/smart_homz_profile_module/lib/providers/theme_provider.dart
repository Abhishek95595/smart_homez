import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme management provider that controls the application-wide [ThemeMode]
/// and persists user preferences in [SharedPreferences].
class ThemeProvider extends ChangeNotifier {
  static const String themePrefKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  String get themeName {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  ThemeProvider({ThemeMode initialMode = ThemeMode.light})
    : _themeMode = initialMode;

  /// Loads the persisted theme preference from storage during startup.
  Future<void> loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(themePrefKey);
      ThemeMode? resolved;
      if (saved == 'dark') {
        resolved = ThemeMode.dark;
      } else if (saved == 'light') {
        resolved = ThemeMode.light;
      } else if (saved == 'system') {
        resolved = ThemeMode.system;
      }
      if (resolved != null && resolved != _themeMode) {
        _themeMode = resolved;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Sets the global [ThemeMode] and persists the change to storage.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      switch (mode) {
        case ThemeMode.dark:
          await prefs.setString(themePrefKey, 'dark');
          break;
        case ThemeMode.light:
          await prefs.setString(themePrefKey, 'light');
          break;
        case ThemeMode.system:
          await prefs.setString(themePrefKey, 'system');
          break;
      }
    } catch (_) {}
  }

  /// Toggles between Light and Dark mode.
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
