
import 'package:aprende_lexico/home/practice_mode.dart';
import 'package:aprende_lexico/enums/learn_status.dart'; // 👈 IMPORTANTE

class LearnTopic {
  final String id;
  final String title;
  final String emoji;
  final String content;
  final PracticeMode practiceMode;
  final LearnStatus status;

  const LearnTopic({
    required this.id,
    required this.title,
    required this.emoji,
    required this.content,
    required this.practiceMode,
    required this.status,
  });
}

const List<LearnTopic> learnTopics = [
  LearnTopic(
    id: "optimizar",
    title: "Optimizar vs Mejorar",
    emoji: "🧠",
    content: """
    
En contextos profesionales, “mejorar” suena bien, pero es impreciso.

Cuando dices:
❌ “Vamos a mejorar el proceso”

No queda claro cómo, ni con qué objetivo.

En cambio:
✅ “Vamos a optimizar el proceso”

Transmite análisis, intención y resultado.
""",
    practiceMode: PracticeMode.exposition,
    status: LearnStatus.notStarted, // ✅
  ),
  LearnTopic(
    id: "estructurar",
    title: "Estructurar ideas",
    emoji: "📐",
    content: """
Hablar bien no es hablar mucho.

Estructurar es guiar al oyente.
""",
    practiceMode: PracticeMode.thesis,
    status: LearnStatus.notStarted, // ✅
  ),
];