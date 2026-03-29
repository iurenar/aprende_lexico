import 'package:shared_preferences/shared_preferences.dart';
import 'package:aprende_lexico/home/practice_mode.dart';


class LastPracticeService {
  static const _key = 'last_practice';

  static Future<void> save(PracticeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  static Future<PracticeMode?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null) return null;

    return PracticeMode.values.firstWhere(
          (e) => e.name == value,
      orElse: () => PracticeMode.conversation,
    );
  }
}
