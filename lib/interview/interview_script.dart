import 'package:aprende_lexico/enums/interview_flow.dart';
import 'interview_steps.dart'; // donde está tu lista interviewSteps

class InterviewScript {
  static final Map<InterviewPhase, List<String>> questions = {
    InterviewPhase.analysis: interviewSteps
        .where((s) => s.phase == "Análisis del puesto")
        .map((s) => s.question)
        .toList(),

    InterviewPhase.star: interviewSteps
        .where((s) => s.phase == "Método STAR")
        .map((s) => s.question)
        .toList(),

    InterviewPhase.difficult: interviewSteps
        .where((s) => s.phase == "Preguntas difíciles")
        .map((s) => s.question)
        .toList(),

    InterviewPhase.candidate: interviewSteps
        .where((s) => s.phase == "Preguntas al entrevistador")
        .map((s) => s.question)
        .toList(),
  };
}
