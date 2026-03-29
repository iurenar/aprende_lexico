import 'package:aprende_lexico/home/practice_mode.dart';
import 'package:aprende_lexico/lesson/voice_chat_screen.dart';
import 'package:aprende_lexico/enums/training_mode.dart';


TrainingMode mapPracticeToTraining(PracticeMode mode) {
  switch (mode) {
    case PracticeMode.conversation:
      return TrainingMode.guidedPractice;
    case PracticeMode.exposition:
      return TrainingMode.presentation;
    case PracticeMode.thesis:
      return TrainingMode.defense;
    case PracticeMode.vocabulary:
      return TrainingMode.guidedPractice;
    case PracticeMode.professionalLexicon:
      return TrainingMode.professional; // ✅ Bien, porque TrainingMode.professional EXISTE
  }
}
