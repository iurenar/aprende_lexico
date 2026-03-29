import 'package:flutter/material.dart';
import 'package:aprende_lexico/lesson/voice_chat_screen.dart';
import 'package:aprende_lexico/home/practice_mode.dart';
import 'package:aprende_lexico/home/practice_mode_mapper.dart';
import 'package:aprende_lexico/learn/professional_lexicon_screen.dart';

class ProfessionalScreen extends StatelessWidget {
  const ProfessionalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profesional"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Habla como un profesional",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Entrena vocabulario y expresiones propias de tu profesión.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // 👉 Más adelante: pantalla solo de vocabulario
            _ProfessionalCard(
              icon: Icons.work,
              title: "Léxico profesional",
              subtitle: "Palabras clave de tu profesión",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoiceChatScreen(
                      mode: mapPracticeToTraining(
                        PracticeMode.professionalLexicon,
                      ),
                      learnContext: "léxico profesional",
                    ),


                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _ProfessionalCard(
              icon: Icons.mic,
              title: "Practicar con vocabulario real",
              subtitle: "Habla como en tu trabajo",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>  const ProfessionalLexiconScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _ProfessionalCard(
              icon: Icons.error_outline,
              title: "Errores comunes",
              subtitle: "Evita sonar poco profesional",
              onTap: () {
                // 👉 Más adelante: pantalla de errores
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfessionalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEAFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
