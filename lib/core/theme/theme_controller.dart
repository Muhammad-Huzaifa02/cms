import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Global ThemeController to toggle between Light and Executive Dark Banking themes.
/// Persists user choice in secure local storage.
class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  static const _storageKey = 'cms_theme_mode';
  final _storage = const FlutterSecureStorage();

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == 'dark') {
        _themeMode = ThemeMode.dark;
        notifyListeners();
      } else if (saved == 'light') {
        _themeMode = ThemeMode.light;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggleTheme(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      await _storage.write(key: _storageKey, value: dark ? 'dark' : 'light');
    } catch (_) {}
  }
}
