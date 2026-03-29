import 'package:flutter/material.dart';
import 'package:aprende_lexico/enums/learn_status.dart';

class ProgressCard extends StatelessWidget {
  final Map<String, LearnStatus> progress;

  const ProgressCard({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final total = progress.length;
    final mastered = progress.values
        .where((s) => s == LearnStatus.mastered)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Progreso general",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text("Temas dominados: $mastered / $total"),
        ],
      ),
    );
  }
}
