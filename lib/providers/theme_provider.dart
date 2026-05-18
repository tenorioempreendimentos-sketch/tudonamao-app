import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _kKey = 'dark_mode';
  bool _isDark = true; // padrão: dark (app nasceu dark)

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_kKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, _isDark);
  }
}
