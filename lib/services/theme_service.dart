// lib/services/theme_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  light,
  dark,
  system,
}

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  AppTheme _currentTheme = AppTheme.system;

  AppTheme get currentTheme => _currentTheme;
  ThemeData get darkTheme => _darkTheme;


  ThemeService() {
    _loadTheme();
  }

  // Cargar tema guardado
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 2; // system por defecto
    _currentTheme = AppTheme.values[themeIndex];
    notifyListeners();
  }

  // Cambiar tema
  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
    notifyListeners();
  }

  // Obtener ThemeData según el tema seleccionado
  ThemeData getThemeData(Brightness platformBrightness) {
    switch (_currentTheme) {
      case AppTheme.light:
        return _lightTheme;
      case AppTheme.dark:
        return _darkTheme;
      case AppTheme.system:
        return platformBrightness == Brightness.dark
            ? _darkTheme
            : _lightTheme;
    }
  }

  // TEMA CLARO
  ThemeData get _lightTheme => ThemeData(
    primarySwatch: Colors.indigo,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAF9FF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.indigo,
      unselectedItemColor: Colors.grey,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: Colors.indigo,
      secondary: Colors.orange,
      surface: Colors.white,
    ),
  );

  // TEMA OSCURO
  ThemeData get _darkTheme => ThemeData(
    primarySwatch: Colors.indigo,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Colors.indigoAccent,
      unselectedItemColor: Colors.grey,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF2C2C2C),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.indigoAccent,
      secondary: Colors.orangeAccent,
      surface: Color(0xFF2C2C2C),
    ),
  );
}