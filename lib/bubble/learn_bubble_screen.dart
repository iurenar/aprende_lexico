import 'package:flutter/material.dart';
import 'package:aprende_lexico/bubble/learn_topic.dart';
import 'package:aprende_lexico/bubble/learn_detail_screen.dart';

class LearnBubble extends StatelessWidget {
  final LearnTopic topic;
  final bool isLearned;
  final VoidCallback onOpened;

  const LearnBubble({
    super.key,
    required this.topic,
    required this.isLearned,
    required this.onOpened,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
    isLearned ? const Color(0xFFE6F4EA) : const Color(0xFFF1F1F1);

    final Color iconColor =
    isLearned ? Colors.green : Colors.grey.shade600;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LearnDetailScreen(topic: topic),
          ),
        );

        onOpened();
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  topic.emoji,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  topic.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ✅ CHECK SI APRENDIDO
          if (isLearned)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle,
                color: iconColor,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
