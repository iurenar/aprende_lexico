import 'package:flutter/material.dart';
import 'package:aprende_lexico/bubble/learn_topic.dart';
import 'package:aprende_lexico/enums/learn_status.dart';
import 'package:aprende_lexico/bubble/learn_detail_screen.dart';
import 'package:aprende_lexico/learn/learn_progress_services.dart';

class LearnBubble extends StatelessWidget {
  final LearnTopic topic;
  final LearnStatus status;

  const LearnBubble({
    super.key,
    required this.topic,
    required this.status,
  });

  Color _bubbleColor(LearnStatus status) {
    switch (status) {
      case LearnStatus.mastered:
        return Colors.green.shade100;
      case LearnStatus.inProgress:
        return Colors.amber.shade100;
      case LearnStatus.notStarted:
      default:
        return Colors.grey.shade200;
    }
  }

  IconData _bubbleIcon(LearnStatus status) {
    switch (status) {
      case LearnStatus.mastered:
        return Icons.check_circle;
      case LearnStatus.inProgress:
        return Icons.timelapse;
      default:
        return Icons.circle_outlined;
    }
  }
  IconData _icon() {
    switch (status) {
      case LearnStatus.mastered:
        return Icons.check_circle;
      case LearnStatus.inProgress:
        return Icons.timelapse;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _iconColor() {
    switch (status) {
      case LearnStatus.mastered:
        return Colors.green;
      case LearnStatus.inProgress:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }


  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await LearnProgressService.markOpened(topic.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LearnDetailScreen(topic: topic),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _bubbleColor(status),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 FILA SUPERIOR: emoji + ícono animado (alineados horizontalmente)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji grande
                Text(
                  topic.emoji,
                  style: const TextStyle(fontSize: 46),
                ),
                const SizedBox(width: 8),
                // Ícono de estado (animado)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _icon(),
                    key: ValueKey(status),
                    color: _iconColor(),
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 🔹 TÍTULO (y label "Dominado" si aplica)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (status == LearnStatus.mastered)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "✔ Dominado",
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  }



