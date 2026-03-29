// practice_screen.dart

import 'package:flutter/material.dart';
import 'package:aprende_lexico/presentation/presentation_practice_screen.dart';
import 'package:aprende_lexico/thesis/thesis_defense_practice_screen.dart';
import 'package:aprende_lexico/lesson/voice_chat_screen.dart';
import 'package:aprende_lexico/widget/practicecard.dart';
import 'package:aprende_lexico/enums/training_mode.dart';

import '../interview/interview_practice_screen.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  void _goToChat(BuildContext context, TrainingMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceChatScreen(mode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Práctica"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Elige un modo de práctica",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            PracticeCard(
              title: "Exposición profesional",
              subtitle: "Presenta ideas con claridad y seguridad",
              icon: Icons.record_voice_over,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PresentationPracticeScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            PracticeCard(
              title: "Defensa de tesis",
              subtitle: "Argumenta y responde con precisión",
              icon: Icons.school,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ThesisDefensePracticeScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            PracticeCard(
              title: "Entrevista laboral",
              subtitle: "Prepárate con preguntas reales de reclutadores",
              icon: Icons.work,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InterviewPracticeScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            PracticeCard(
              title: "Reunión de trabajo",
              subtitle: "Comunica decisiones y propuestas",
              icon: Icons.groups,
              onTap: () => _goToChat(context, TrainingMode.guidedPractice),
            ),
          ],
        ),
      ),
    );
  }
}