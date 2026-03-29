
import 'package:aprende_lexico/enums/interview_flow.dart';

class LexicalResult {
  final LexicalLevel level;
  final Decision decision;
  final String diagnosis;
  final String followUpQuestion;

  LexicalResult({
    required this.level,
    required this.decision,
    required this.diagnosis,
    required this.followUpQuestion,
  });

  /// 🧠 Convierte texto de IA en estructura usable
  factory LexicalResult.fromAI(String aiText) {
    final lower = aiText.toLowerCase();

    // 🔹 Nivel léxico
    LexicalLevel level = LexicalLevel.medium;
    if (lower.contains("bajo")) level = LexicalLevel.low;
    if (lower.contains("alto")) level = LexicalLevel.high;

    // 🔹 Decisión
    Decision decision = Decision.probe;
    if (lower.contains("advance")) decision = Decision.advance;
    if (lower.contains("correct")) decision = Decision.correct;

    // 🔹 Diagnóstico (simple)
    final diagnosis = aiText.split('\n').first;

    // 🔹 Repregunta
    final followUp = _extractFollowUp(aiText);

    return LexicalResult(
      level: level,
      decision: decision,
      diagnosis: diagnosis,
      followUpQuestion: followUp,
    );
  }

  static String _extractFollowUp(String text) {
    final lines = text.split('\n');
    for (final l in lines) {
      if (l.trim().endsWith("?")) {
        return l.trim();
      }
    }
    return "¿Podrías profundizar un poco más?";
  }
}


