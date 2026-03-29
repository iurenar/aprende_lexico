import 'package:flutter/material.dart';
import 'learn_card.dart';

class LearnGrid extends StatelessWidget {
  const LearnGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: const [
        LearnCard(
          icon: Icons.work,
          title: "Léxico profesional",
          subtitle: "Palabras clave",
          color: Colors.indigo,
        ),
        LearnCard(
          icon: Icons.account_tree,
          title: "Por tu profesión",
          subtitle: "Arquitectura",
          color: Colors.green,
        ),
        LearnCard(
          icon: Icons.auto_stories,
          title: "Expresiones avanzadas",
          subtitle: "Sonar más pro",
          color: Colors.purple,
        ),
        LearnCard(
          icon: Icons.error_outline,
          title: "Errores comunes",
          subtitle: "Evítalos",
          color: Colors.orange,
        ),
      ],
    );
  }
}
