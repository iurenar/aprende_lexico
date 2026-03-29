import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {

  double _voiceVolume = 0.8;
  double _voiceSpeed = 0.5;
  String _languageCode = 'es';

  double get voiceVolume => _voiceVolume;
  double get voiceSpeed => _voiceSpeed;
  String get languageCode => _languageCode;

  Locale get locale => Locale(_languageCode);

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _voiceVolume = prefs.getDouble('voice_volume') ?? 0.8;
    _voiceSpeed = prefs.getDouble('voice_speed') ?? 0.5;
    _languageCode = prefs.getString('language_code') ?? 'es';

    notifyListeners();
  }

  Future<void> setVoiceVolume(double value) async {
    _voiceVolume = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('voice_volume', value);

    notifyListeners();
  }

  Future<void> setVoiceSpeed(double value) async {
    _voiceSpeed = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('voice_speed', value);

    notifyListeners();
  }

  Future<void> setLanguage(String code) async {

    if (_languageCode == code) return;

    _languageCode = code;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);

    notifyListeners();
  }
}