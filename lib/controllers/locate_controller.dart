import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleController() {
    loadLocale();
  }

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('language_code');

    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('language_code', code);

    _locale = Locale(code);

    notifyListeners();
  }
}