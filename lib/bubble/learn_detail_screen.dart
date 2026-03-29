import 'package:flutter/material.dart';
import 'package:aprende_lexico/bubble/learn_topic.dart';
import 'package:aprende_lexico/lesson/voice_chat_screen.dart';
import 'package:aprende_lexico/home/practice_mode.dart';
import 'package:aprende_lexico/learn/learn_progress_services.dart';
import 'package:aprende_lexico/enums/learn_status.dart';
import 'package:aprende_lexico/enums/training_mode.dart';



class LearnDetailScreen extends StatefulWidget {
  final LearnTopic topic;

  const LearnDetailScreen({
    super.key,
    required this.topic,
  });

  @override
  State<LearnDetailScreen> createState() => _LearnDetailScreenState();
}

class _LearnDetailScreenState extends State<LearnDetailScreen> {

  @override
  void initState() {
    super.initState();

    // 🔥 CLAVE: marcar como "en progreso" al abrir
    LearnProgressService.markOpened(widget.topic.id);
  }

  // 🔁 MAPEO Learn → Practice
  TrainingMode _mapPracticeToTraining(PracticeMode mode) {
    switch (mode) {
      case PracticeMode.exposition:
        return TrainingMode.presentation;
      case PracticeMode.thesis:
        return TrainingMode.defense;
      default:
        return TrainingMode.guidedPractice;
    }
  }
  String _ctaText(LearnStatus status) {
    switch (status) {
      case LearnStatus.mastered:
        return "Refrescar este concepto";
      case LearnStatus.inProgress:
        return "Seguir practicando";
      case LearnStatus.notStarted:
      default:
        return "Practicar este concepto";
    }
  }
  IconData _ctaIcon(LearnStatus status) {
    switch (status) {
      case LearnStatus.mastered:
        return Icons.refresh;
      default:
        return Icons.mic;
    }
  }

  Color _ctaColor(LearnStatus status) {
    switch (status) {
      case LearnStatus.mastered:
        return Colors.green;
      default:
        return Colors.indigo;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic.title),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👇 Mensaje de "dominado" (solo si aplica)
              if (widget.topic.status == LearnStatus.mastered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "✔ Ya dominas este concepto",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // 👇 Contenido del tema
              Text(
                widget.topic.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),

      // ✅ CTA INTELIGENTE
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.topic.status == LearnStatus.mastered) // ✅ widget.topic
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "✔ Ya dominas este concepto",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ElevatedButton.icon(
              icon: Icon(_ctaIcon(widget.topic.status)), // ✅
              label: Text(_ctaText(widget.topic.status)), // ✅
              style: ElevatedButton.styleFrom(
                backgroundColor: _ctaColor(widget.topic.status), // ✅
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoiceChatScreen(
                      mode: _mapPracticeToTraining(widget.topic.practiceMode), // ✅
                      learnContext: widget.topic.title, // ✅
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
