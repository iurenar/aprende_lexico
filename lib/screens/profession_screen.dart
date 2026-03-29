import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aprende_lexico/onboarding/onboarding_controller.dart';
import 'package:aprende_lexico/onboarding/onboarding_state.dart';
import '../enums/profession.dart';

class ProfessionScreen extends StatelessWidget {
  const ProfessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final professions = {
      "Arquitectura": Profession.architect,
      "Ingeniería": Profession.engineer,
      "Derecho": Profession.lawyer,
      "Medicina": Profession.doctor,
      "Educación": Profession.educator,
    };

    return Scaffold(
      appBar: AppBar(title: const Text("Tu profesión")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: professions.entries.map((entry) {
          final label = entry.key;
          final professionEnum = entry.value;

          return Card(
            child: ListTile(
              title: Text(label),
              onTap: () {
                context
                    .read<OnboardingController>()
                    .setProfession(professionEnum);

                context
                    .read<OnboardingController>()
                    .next(OnboardingStep.completed);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}