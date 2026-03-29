import 'package:shared_preferences/shared_preferences.dart';
import 'package:aprende_lexico/enums/learn_status.dart';

class LearnProgressService {
  static const _key = 'learn_progress';

  static Future<Map<String, LearnStatus>> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    final Map<String, LearnStatus> progress = {};

    for (final item in raw) {
      final parts = item.split('|');
      if (parts.length == 2) {
        progress[parts[0]] = LearnStatus.values.byName(parts[1]);
      }
    }

    return progress;
  }

  static Future<void> saveProgress(
      String topicId,
      LearnStatus status,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    raw.removeWhere((e) => e.startsWith('$topicId|'));
    raw.add('$topicId|${status.name}');

    await prefs.setStringList(_key, raw);
  }

  static Future<void> markOpened(String topicId) async {
    await saveProgress(topicId, LearnStatus.inProgress);
  }

  static Future<void> markMastered(String topicId) async {
    await saveProgress(topicId, LearnStatus.mastered);
  }
  // 🔍 Helpers de estado

  static LearnStatus getStatus(
      Map<String, LearnStatus> progress,
      String topicId,
      ) {
    return progress[topicId] ?? LearnStatus.notStarted;
  }

  static bool isMastered(
      Map<String, LearnStatus> progress,
      String topicId,
      ) {
    return progress[topicId] == LearnStatus.mastered;
  }




}
