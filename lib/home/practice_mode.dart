import 'package:aprende_lexico/enums/training_mode.dart';

enum PracticeMode {
  conversation,
  exposition,
  thesis,
  vocabulary,
  professionalLexicon,
}

extension PracticeModeX on PracticeMode {
  String get title {
    switch (this) {
      case PracticeMode.conversation:
        return "Conversación con Aria";
      case PracticeMode.exposition:
        return "Exposición oral";
      case PracticeMode.thesis:
        return "Práctica de tesis";
      case PracticeMode.vocabulary:
        return "Léxico profesional";
      case PracticeMode.professionalLexicon:
        return "Léxico profesional avanzado"; // ✅ STRING, no enum
    }
  }
}

