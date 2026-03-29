import 'package:flutter/material.dart';
import 'package:aprende_lexico/lesson/voice_chat_screen.dart';
import 'package:aprende_lexico/enums/training_mode.dart';

class ProfessionalLexiconScreen extends StatelessWidget {
  const ProfessionalLexiconScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Léxico profesional"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Entrena tu forma de expresarte como un profesional.",
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            _OptionCard(
              icon: Icons.record_voice_over,
              title: "Hablar como un profesional",
              subtitle:
              "Explica ideas, proyectos y decisiones con lenguaje técnico y preciso.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VoiceChatScreen(
                      mode: TrainingMode.professional,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _OptionCard(
              icon: Icons.work_outline,
              title: "Practicar léxico por profesión",
              subtitle:
              "Entrena vocabulario específico según tu área profesional.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VoiceChatScreen(
                      mode: TrainingMode.professional,

                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _OptionCard(
              icon: Icons.warning_amber_outlined,
              title: "Errores comunes",
              subtitle:
              "Detecta expresiones vagas y aprende cómo corregirlas.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VoiceChatScreen(
                      mode: TrainingMode.professional,

                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;


  const _OptionCard({
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
          color: const Color(0xFFF3F1FF),
          borderRadius: BorderRadius.circular(16),
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
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
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
