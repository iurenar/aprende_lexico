

class InterviewStep {
  final String phase;
  final String question;

  InterviewStep({
    required this.phase,
    required this.question,
  });
}

enum InterviewPhase {
  analysis,
  star,
  difficult,
  candidate,
  evaluation
}
enum LexicalLevel {
  low,
  medium,
  high,
}
enum Decision {
  advance, // avanzar a la siguiente pregunta
  probe,   // repreguntar
  correct, // corregir léxico
}

