import 'package:flutter/material.dart';
import 'package:aprende_lexico/bubble/learn_topic.dart';
import 'package:aprende_lexico/bubble/learn_bubble.dart';
import 'package:aprende_lexico/enums/learn_status.dart';

// ✅ Eliminamos onOpened: se maneja desde LearnScreen
class LearnTopicsGrid extends StatelessWidget {
  final Map<String, LearnStatus> progress;

  const LearnTopicsGrid({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: learnTopics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, index) {
        final topic = learnTopics[index];
        final status =
            progress[topic.id] ?? LearnStatus.notStarted;

        return LearnBubble(
          topic: topic,
          status: status,
        );
      },
    );
  }
}
